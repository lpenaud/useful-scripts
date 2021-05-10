import { fileURLToPath } from 'url'
import http from 'http'
import { createReadStream } from 'fs'
import fs from 'fs/promises'
import { pipeline } from 'stream/promises'
import path from 'path'
import { USELESS_FUNCTION } from "../helpers/node/util.mjs";
import HttpServer from '../helpers/node/http/http-server.mjs'
import HttpRange from "../helpers/node/http/http-range.mjs";
import HttpLogger from "../helpers/node/http/http-logger.mjs";

const STAT_FILTER = st => st.isDirectory() || st.isFile()

const LOGGER = new HttpLogger()

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

 async function tryStat(pathname) {
  try {
    const stat = await fs.stat(pathname)
    return STAT_FILTER(stat) ? stat : null
  } catch (error) {
    return null
  }
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
  const pathname = path.join('.', decodeURIComponent(req.url))
  const stat = await tryStat(pathname)
  if (stat === null) {
    res.writeHead(404)
    res.end()
    return
  }
  const range = new HttpRange(stat, req)
  let callback
  if (stat.isFile()) {
    if (range.size < 0 || range.end === 0) {
      res.writeHead(416)
      res.end()
      return
    }
    res.setHeader('Content-Type', 'applications/octet-stream')
    res.setHeader('Content-Length', range.length)
    if (range.size !== stat.size) {
      range.setHeader(res)
    } else {
      res.statusCode = 200
    }
    callback = options.onFile
  } else if (stat.isDirectory()) {
    res.statusCode = 200
    res.setHeader('Content-Type', 'text/html')
    callback = options.onDirectory
  }
  LOGGER.log(req, res)
  try {
    await callback(res, { pathname, range })
  } finally {
    res.end()
  }
}

/**
 * Can send totally or partially a regular file through a HTTP response.
 * @param {http.ServerResponse} res - HTTP server response. 
 * @param {HeaderInfo} info - Information about the requested file.
 */
async function getFile(res, info) {
  const readStream = createReadStream(info.pathname, {
    start: info.range.start,
    end: info.range.end,
  })
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
  const files = []
  console.log(info.pathname, parsed)
  if (parsed.base === '.') {
    parsed.base = '/'
  } else {
    files.push(`<li><a href="/${parsed.dir}">..</a></li>`)
  }
  files.push(...(await fs.readdir(info.pathname, { withFileTypes: true }))
    .filter(STAT_FILTER)
    .sort((f1, f2) => f1.name.localeCompare(f2.name))
    .map(f => `
<li>
  <a href="/${path.join(info.pathname, f.name)}">${f.name + (f.isDirectory() ? '/' : '')}</a>
</li>`)
  )
  const title = `Directory listing for ${parsed.base}`
  await new Promise((resolve) => {
    res.write(`
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
<head>
<body>
  <h1>${title}</h1>
  <hr>
  <ul>${files.join('')}</ul>
  <hr>
</body>
<h1>`, resolve)
  })
}

function usage(printer, code) {
  const httpOptions = HttpServer.listenOptions()
  const prgm = path.basename(process.argv[1])
  const formatter = arg => printer('  %s %s', prgm, arg)
  printer('Usage:')
  formatter(`[(-H --host) HOST=${httpOptions.host}]`)
  formatter(`[(-p --port) PORT=${httpOptions.port}]`)
  formatter('(-h --help)')
  process.exit(code)
}

function readArgs(args) {
  const config = {}
  let hasError = false
  let arg
  while (args.length > 0) {
    switch (arg = args.shift()) {
      case '--port':
      case '-p':
        config.port = parseInt(args.shift())
        if (config.port === NaN || config.port < 0 || config.port >= 65536) {
          console.error('PORT should be >= 0 and < 65536')
          hasError = true
        }
        break

      case '--host':
      case '-H':
        config.host = args.shift()
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
  const defaultOptions = {
    onFile: getFile,
    onDirectory: getDirectory,
  }
  const server = new HttpServer()
  server.head((req, res) => prepareHeader(req, res))
    .get((req, res) => prepareHeader(req, res, defaultOptions))
  await server.listen(readArgs(args))
}

// Test if it's this file which is directly call
if (fileURLToPath(import.meta.url).startsWith(process.argv[1])) {
  main(process.argv.slice(2))
}
