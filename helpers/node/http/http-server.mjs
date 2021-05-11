import * as http from 'http'
import { toCamelCase, defaultValues } from "../util.mjs";

export default class HttpServer {
  static NOT_ALLOWED_METHOD = (req, res) => {
    res.writeHead(501)
    res.end()
  }

  static listenOptions(options) {
    return defaultValues({
      host: '0.0.0.0',
      port: 3000,
    }, options)
  }

  handlers
  server
  methods

  constructor(options = {}) {
    this.handlers = {}
    this.methods = new Set(options.methods || [])
      .add('GET').add('HEAD')
    http.METHODS.filter(m => !this.methods.has(m))
      .forEach(m => this.handlers[m] = [HttpServer.NOT_ALLOWED_METHOD])
    for (const method of this.methods) {
      this[toCamelCase(method)] = this._addHandler.bind(this, method)
      this.handlers[method] = []
    }
    this.server = http.createServer(options.server, this._requestHandler.bind(this))
  }

  listen(options) {
    return new Promise((resolve, reject) => {
      this.server.prependOnceListener('error', reject)
      this.server.listen(HttpServer.listenOptions(options), () => {
        console.log('Web server listening on http://%s:%d',
          options.host,
          options.port,
        )
        this.server.removeListener('error', reject)
        resolve()
      })
    })
  }

  on(handler) {
    for (const method of this.methods) {
      this.handlers[method].push(handler)
    }
    return this
  }

  _addHandler(method, handler) {
    this.handlers[method].push(handler)
    return this
  }

  async _requestHandler(req, res) {
    try {
      for (const handler of this.handlers[req.method]) {
        await handler(req, res)
      }
    } catch (error) {
      console.error(error)
    } finally {
      res.end()
    }
  }
}
