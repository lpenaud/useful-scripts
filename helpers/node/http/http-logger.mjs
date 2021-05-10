import { Console } from 'console'

const LOG_SYMBOL = Symbol()

export default class HttpLogger extends Console {
  dateTimeFormat

  constructor(options) {
    super({
      stderr: process.stderr,
      stdout: process.stdout,
      ...options,
    })
    this.dateTimeFormat = new Intl.DateTimeFormat([], {
      dateStyle: 'short',
      timeStyle: 'short',
    })
    this.log = this[LOG_SYMBOL].bind(this, 'log')
    this.info = this[LOG_SYMBOL].bind(this, 'info')
    this.error = this[LOG_SYMBOL].bind(this, 'error')
    this.warn = this[LOG_SYMBOL].bind(this, 'warn')
  }

  [LOG_SYMBOL](method, req, res) {
    super[method]('%s:%d [%s] "%s %s HTTP/%s" %d',
      req.socket.remoteAddress,
      req.socket.remotePort,
      this.dateTimeFormat.format(new Date()),
      req.method,
      decodeURIComponent(req.url),
      req.httpVersion,
      res.statusCode,
    )
  }
}
