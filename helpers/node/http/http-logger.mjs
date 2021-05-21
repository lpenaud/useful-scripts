import { Console } from 'console'
import { USELESS_FUNCTION } from '../util.mjs'

const INFO_METHOD = Symbol('INFO METHOD')

export default class HttpLogger extends Console {
  static LEVELS = Object.freeze(['log', 'info', 'error', 'warn', 'debug'])

  static getOptions(options = {}) {
    return {
      stderr: process.stderr,
      stdout: process.stdout,
      levels: HttpLogger.LEVELS,
      ...options,
    }
  }

  dateTimeFormat

  constructor(options) {
    super(options = HttpLogger.getOptions(options))
    this.dateTimeFormat = new Intl.DateTimeFormat([], {
      dateStyle: 'short',
      timeStyle: 'short',
    })
    const levels = new Set(options.levels)
    HttpLogger.LEVELS.filter(l => !levels.delete(l))
      .forEach(l => this[l] = USELESS_FUNCTION)
  }
  
  info(func, ...args) {
    this[INFO_METHOD]('info', func, args)
  }

  debug(func, ...args) {
    this[INFO_METHOD]('debug', func, args)
  }

  log(req, res) {
    super.log('%s:%d [%s] "%s %s HTTP/%s" %d',
      req.socket.remoteAddress,
      req.socket.remotePort,
      this.dateTimeFormat.format(new Date()),
      req.method,
      decodeURIComponent(req.url),
      req.httpVersion,
      res.statusCode,
    )
  }

  [INFO_METHOD](method, func, args) {
    method = super[method]
    if (typeof func === "function") {
      const result = func.apply(undefined, args)
      if (Array.isArray(result)) {
        return result.forEach(r => method.apply(this, r))
      }
      return method(result)
    }
    method(func, ...args)
  }
}
