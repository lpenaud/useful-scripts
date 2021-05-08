import { fileURLToPath } from 'url'
import http from 'http'
import { createReadStream } from 'fs'
import fs from 'fs/promises'
import { pipeline } from 'stream/promises'
import path from 'path'
import util from 'util'

/**
 * Function that serves no purpose except to be called.
 * Useful for optional callback.
 * @returns {void}
 */
const USELESS_FUNCTION = () => undefined

/**
 * @typedef Range
 * @property {number} start - Positive integer.
 * @property {number} end - Positive integer.
 * @property {number} size - Integer can be negative.
 * @property {number} length - Length of the range.
 * @property {"bytes"} unit - Range unit.
 * @see {@link getRangeHeader}
 */

/**
 * @typedef HeaderInfo
 * @property {string} pathname - Relative path to the file.
 * @property {Range} range - Asked file range.
 */

/**
 * @callback PrepareHeaderCallback
 * @param {http.ServerResponse} res - HTTP Result.
 * @param {HeaderInfo} info - Information about the file. 
 * @returns {Promise<void>|void} Return value is not use.
 */

/**
 * Options to prepareHeader function.
 * @typedef PrepareHeaderOptions
 * @property {PrepareHeaderCallback} onFile - Call if the requested file is a regular file.
 * @property {PrepareHeaderCallback} onDirectory - Call if the requested file is a directory.
 * @see {@link prepareHeader}
 */

/**
 * Calculate the asked range in headers of a HTTP request.
 * @param {fs.Stats} stat - File stats.
 * @param {http.ClientRequest} req - HTTP request.
 * @returns {Range} Asking range.
 */
function getRangeHeader(stat, req) {
  const matchs = /^bytes=([0-9]+)\-([0-9]+)?$/.exec(req.headers.range)
  const range = matchs === null
    ? { start: 0, end: stat.size - 1 }
    : { start: parseInt(matchs[1]), end: parseInt(matchs[2]) || stat.size - 1 }
  range.size = stat.size - range.start
  range.length = (range.end - range.start) + 1
  range.unit = 'bytes'
  return range
}

/**
 * 
 * @param {http.ClientRequest} req - HTTP client request.
 * @param {http.ServerResponse} res - HTTP server reponse.
 * @param {PrepareHeaderOptions} options - Provider of callbacks.
 * @param {options.onFile} [options.onFile=USELESS_FUNCTION] - By default do nothing.
 * @param {options.onDirectory} [options.onDirectory=USELESS_FUNCTION] - By default do nothing.
 */
async function prepareHeader(req, res, options = {}) {
  options = {
    onFile: USELESS_FUNCTION,
    onDirectory: USELESS_FUNCTION,
    ...options,
  }
  const pathname = path.join(".", decodeURIComponent(req.url))
  const stat = await fs.stat(pathname)
  const range = getRangeHeader(stat, req);
  if (stat.isFile()) {
    if (range.size < 0 || range.end === 0) {
      res.writeHead(416)
      res.end()
      return
    }
    res.writeHead(range.size !== stat.size ? 206 : 200, {
      'Content-Type': 'application/octet-stream',
      'Content-Range': `${range.unit} ${range.start}-${range.end}/${stat.size}`,
      'Accept-Range': range.unit,
      'Content-Length': range.length,
    })
    await options.onFile(res, { pathname, range })
  } else if (stat.isDirectory()) {
    await options.onDirectory(res, { pathname, range })
    res.writeHead(200, {
      'Content-Type': 'text/html'
    })
  }
  res.end()
}

/**
 * Can send totally or partially a regular file through a HTTP response.
 * @param {http.ServerResponse} res - HTTP server response. 
 * @param {HeaderInfo} info - Information about the requested file.
 */
async function getFile(res, info) {
  const readStream = createReadStream(info.pathname, info.range)
  try {
    await pipeline(readStream, res)
  } finally {
    readStream.destroy()
  }
}

/**
 * Send a HTML page with links to all regulars files and directories through a HTTP reponse.
 * @param {http.ServerResponse} res - HTTP server reponse.
 * @param {HeaderInfo} info - Information about the requested directory.
 */
async function getDirectory(res, info) {
  const parsed = path.parse(info.pathname)
  const files = (await fs.readdir(info.pathname, { withFileTypes: true }))
    .filter(f => f.isDirectory() || f.isFile())
  await new Promise((resolve) => {
    res.write(util.format(
      '<!DOCTYPE html><html><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><title>%s</title></head><body><h1>%s</h1><ul><li><a href=\"%s\">..</a></li>%s</ul></body>',
      parsed.name,
      parsed.name,
      parsed.dir,
      files.reduce((acc, f) => acc + `<li><a href="${path.join(info.pathname, f.name)}">${f.name}</a></li>`, ""),
    ), resolve)
  })
}

function prodString(str, times) {
  let result = ""
  while (times-- > 0) {
    result += str
  }
  return result
}

function usage(printer, code) {
  const prgm = path.basename(process.argv[1])
  const spaces = prodString(' ', prgm.length)
  const formatter = (...args) => printer('  %s %s', ...args)
  printer('Usage:')
  formatter(prgm, '[(-b --bind) ADRESS=0.0.0.0]')
  formatter(prgm, '[(-p --port) PORT=3000]')
  formatter(prgm, '(-h --help)')
  process.exit(code)
}

function readArgs(args) {
  const config = {
    port: 3000,
    address: '0.0.0.0',
  }
  let hasError = false
  let arg
  while (args.length > 0) {
    switch (arg = args.shift()) {
      case '--port':
      case '-p':
        config.port = parseInt(args.shift())
        if (config.port === NaN || config.port < 0 || config.port > 65536) {
          console.error('PORT should be >= 0 and < 65536')
          hasError = true
        }
        break

      case '--bind':
      case '-b':
        config.adress = args.shift()
        break

      case '-h':
      case '--help':
        usage(console.log, 0)
        break

      default:
        console.error(`Invalid arg: ${arg}`)
        hasError = true
        break
    }
  }
  if (hasError) {
    usage(console.error, 1)
  }
  return config
}

async function main(args) {
  const { port, address } = readArgs(args)
  const handlers = {
    HEAD(req, res) {
      return prepareHeader(req, res)
    },
    GET(req, res) {
      return prepareHeader(req, res, { onFile: getFile, onDirectory: getDirectory })
    },
  }
  http.createServer()
    .on("request", (req, res) => {
      req.timestamp = Date.now()
    })
    .on("request", (req, res) => {
      const handler = handlers[req.method]
      if (handler === undefined) {
        res.writeHead(501)
        res.end()
      } else {
        handler(req, res).catch(error => {
          console.error(error)
          res.writeHead(404)
          res.end()
        })
      }
    })
    .on("request", (req, res) => {
        console.log(`${res.statusCode} ${req.method} ${decodeURIComponent(req.url)} - ${Date.now() - req.timestamp} ms`)
    })
    .on('error', console.error)
    .listen(port, address, () => {
      console.log('Web server listening on http://%s:%d', address, port)
    })
}

// Test if it's this file which is directly call
if (fileURLToPath(import.meta.url).startsWith(process.argv[1])) {
  await main(process.argv.slice(2))
}
