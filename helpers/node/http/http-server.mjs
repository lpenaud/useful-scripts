import * as http from 'http'
import { toCamelCase } from "../util.mjs";

export default class HttpServer {
  static NOT_ALLOWED_METHOD = (req, res) => {
    res.writeHead(501)
    res.end()
  }

  static listenOptions(options = {}) {
    return {
      host: '0.0.0.0',
      port: 3000,
      ...options,
    }
  }

  handlers
  server

  constructor(options = {}) {
    const methods = new Set(Array.isArray(options.methods) ? options.methods : undefined)
      .add('HEAD').add('GET')
    this.handlers = {}
    const notAllowedMethods = http.METHODS.filter(m => !methods.has(m))
    for (const method of notAllowedMethods) {
      this.handlers[method] = [HttpServer.NOT_ALLOWED_METHOD]
    }
    for (const method of methods) {
      this.handlers[method] = []
      this[toCamelCase(method)] = this._addHandler.bind(this, method)
    }
    this.server = http.createServer(this._requestHandler.bind(this))
  }

  listen(options) {
    options = HttpServer.listenOptions(options)
    return new Promise((resolve, reject) => {
      this.server.prependOnceListener('error', reject)
      this.server.listen(options, () => {
        console.log('Web server listening on http://%s:%d',
          options.host,
          options.port,
        )
        this.server.removeListener('error', reject)
        resolve()
      })
    })
  }

  async _requestHandler(req, res) {
    try {
      for (const handler of this.handlers[req.method]) {
        await handler(req, res)
      }
    } catch (error) {
      console.error(error)
    }
  }

  _addHandler(method, handler) {
    this.handlers[method].push(handler)
    return this
  }
}
