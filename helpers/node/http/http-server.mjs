import * as http from 'http'
import { defaultValues } from '../util.mjs';
import { toCamelCase } from "../util.mjs";

export default class HttpServer {
  static NOT_ALLOWED_METHOD = (req, res) => {
    res.writeHead(501)
  }

  static listenOptions(options) {
    return defaultValues([
      { key: 'host', d: '0.0.0.0' },
      { key: 'port', d: 3000 },
      { key: 'method', d: [] },
    ], options)
  }

  handlers
  server
  methods

  constructor(options = {}) {
    const methods = new Set(options.methods)
      .add('GET').add('HEAD')
    this.handlers = {}
    this.methods = []
    for (const method of http.METHODS) {
      if (methods.delete(method)) {
        this[toCamelCase(method)] = this._addHandler.bind(this, method)
        this.methods.push(method)
        this.handlers[method] = []
      } else {
        this.handlers[method] = [HttpServer.NOT_ALLOWED_METHOD]
      }
    }
    this.server = http.createServer(options.server, this._requestHandler.bind(this))
  }

  listen(options) {
    return new Promise((resolve, reject) => {
      this.server.prependOnceListener('error', reject)
      this.server.listen(HttpServer.listenOptions(options), () => {
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
