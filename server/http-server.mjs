import { fileURLToPath } from 'url'
import { createReadStream, constants as fsConstants } from 'fs'
import fs from 'fs/promises'
import { pipeline } from 'stream/promises'
import path from 'path'
import HttpServer from '../helpers/node/http/http-server.mjs'
import HttpRange from '../helpers/node/http/http-range.mjs'
import HttpLogger from '../helpers/node/http/http-logger.mjs'
import HttpForm from '../helpers/node/http/http-form.mjs'
import { moveFile } from '../helpers/node/util.mjs'

const STAT_FILTER = st => st.isDirectory() || st.isFile()

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

class FileHandler {
  range
  pathname

  constructor({ req, info }) {
    this.range = new HttpRange(info.stat, req)
    this.pathname = info.pathname
  }

  prepare(res) {
    if (this.range.size < 0 || this.range.end === 0) {
      res.writeHead(416)
      res.end()
      return
    }
    this.range.setHeader(res)
    res.setHeader('Content-Type', 'applications/octet-stream')
  }

  async send(req, res) {
    const readStream = createReadStream(this.pathname, {
      start: this.range.start,
      end: this.range.end,
    })
    try {
      await pipeline(readStream, res)
    } finally {
      readStream.destroy()
    }
  }
}

class DirectoryHandler {
  pathname

  constructor({ info }) {
    this.pathname = info.pathname
  }

  prepare(res) {
    res.statusCode = 200
    res.setHeader('Content-Type', 'text/html')
  }

  async send(req, res) {
    const parsed = path.parse(this.pathname)
    const files = []
    if (parsed.base === '.') {
      parsed.base = '/'
    } else {
      files.push(`<li><a href="/${parsed.dir}">..</a></li>`)
    }
    files.push(...(await fs.readdir(this.pathname, { withFileTypes: true }))
      .filter(STAT_FILTER)
      .sort((f1, f2) => f1.name.localeCompare(f2.name))
      .map(f => `
<li>
  <a href="/${path.join(this.pathname, f.name)}">${f.name + (f.isDirectory() ? '/' : '')}</a>
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
  <form action="" method="POST" enctype="multipart/form-data">
    <label for="infile">Choose a file</label>
    <input type="file" name="infile" onchange="event.target.parentElement.submit()" required multiple>
  </form>
  <hr>
</body>
</html>`, resolve)
    })
  }
}

class NotFoundHandler {
  prepare(res) {
    res.writeHead(404)
  }

  send() {
    return Promise.resolve()
  }
}

function usage(printer, code) {
  const httpOptions = HttpServer.listenOptions()
  const loggerOptions = HttpLogger.getOptions()
  const prgm = path.basename(process.argv[1])
  const formatter = arg => printer(`  ${prgm} ${arg}`)
  printer('Usage:')
  formatter(`[(-H --host) HOST=${httpOptions.host}]`)
  formatter(`[(-p --port) PORT=${httpOptions.port}]`)
  formatter(`[(-l --level) LEVEL=${loggerOptions.level}]`)
  formatter('(-h --help)')
  process.exit(code)
}

function readArgs(args) {
  const config = {
    listen: {},
    log: {},
  }
  let hasError = false
  let arg
  while (args.length > 0) {
    switch (arg = args.shift()) {
      case '--port':
      case '-p':
        const port = parseInt(args.shift())
        if (port === NaN || port < 0 || port >= 65536) {
          console.error('PORT should be >= 0 and < 65536')
          hasError = true
        } else {
          config.listen.port = port
        }
        break

      case '--host':
      case '-H':
        config.listen.host = args.shift()
        break

      case '-l':
      case '--level':
        const level = args.shift()
        if (typeof HttpLogger.LEVELS[level] !== 'number') {
          console.error('Undefined log level', level)
          hasError = true
        } else {
          config.log.level = HttpLogger.LEVELS[level]
        }
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
  args = readArgs(args)
  const infoSymbol = Symbol('info')
  const server = new HttpServer({
    methods: ['POST', 'PUT'],
  })
  const logger = new HttpLogger(args.log)
  const headHandler = (req, res) => {
    const info = req[infoSymbol]
    const args = { res, req, info }
    const handler = info.stat === null ? new NotFoundHandler(args)
      : info.stat.isDirectory() ? new DirectoryHandler(args)
      : info.stat.isFile() ? new FileHandler(args) 
      : new NotFoundHandler(args)
    handler.prepare(res)
    return handler
  }
  const reveiveFile = async (res, req, form, pathname, method) => {
    const files = form.files.map(f => ({ path: f.path, pathname: path.join(pathname, f.filename) }))
    try {
      await Promise.all(files.map(f => moveFile(f.path, f.pathname)))
      logger.info(() => files.map(f => ['%s %s', method, f.pathname]))
    } catch (error) {
      res.statusCode = 500
      logger.error(error)
    } finally {
      await Promise.all(files.map(f => fs.rm(f.path, { force: true })))
    }
    res.writeHead(303, {
      'location': req.url,
    })
    res.end()
  }
  server.on(async (req, res) => {
    const pathname = path.join('.', decodeURIComponent(req.url))
    req[infoSymbol] = {
      pathname,
      stat: await tryStat(pathname),
    }
  })
  .head((req, res) => headHandler(req, res))
  .get((req, res) => headHandler(req, res).send(req, res))
  .post(async (req, res) => {
    const { pathname, stat } = req[infoSymbol]
    if (stat === null) {
      res.statusCode = 404
      return
    }
    const form = new HttpForm(req.headers['content-type'])
    await pipeline(req, form)
    const files = new Set(form.files.map(f => f.filename))
    const existingFiles = (await fs.readdir(pathname)).filter(f => files.delete(f))
    if (existingFiles.length > 0) {
      res.statusCode = 418
      await Promise.all(form.files.map(f => fs.rm(f.path, { force: true })))
    } else {
      await reveiveFile(res, req, form, pathname, req.method)
    }
  })
  .put(async (req, res) => {
    const { pathname, stat } = req[infoSymbol]
    if (stat === null) {
      res.statusCode = 404
      return
    }
    const form = new HttpForm(req.headers['content-type'])
    await pipeline(req, form)
    await reveiveFile(res, req, form, pathname, req.method)
  })
  .on(logger.log)
  await server.listen(args.listen)
  console.log('Web server listening on http://%s:%d', args.listen.host, args.listen.port)
}

// Test if it's this file which is directly call
if (fileURLToPath(import.meta.url).startsWith(process.argv[1])) {
  main(process.argv.slice(2))
}
