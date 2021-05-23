import { Console } from 'console'
import { USELESS_FUNCTION } from '../util.mjs'
import Enum from '../enum.mjs'
import { defaultValues } from '../util.mjs'

const INFO_METHOD = Symbol('INFO METHOD')
const LEVELS = new Enum('error', 'warn', 'log', 'info', 'debug')

export default class HttpLogger extends Console {
  static get LEVELS() {
    return LEVELS
  }

  static getOptions(options) {
    return defaultValues([
      { key: 'stderr', d: process.stderr },
      { key: 'stdout', d: process.stdout },
      { key: 'level', d: LEVELS.info },
      {
        key: 'dateTimeFormat',
        d: {
          dateStyle: 'short',
          timeStyle: 'short',
        },
      },
    ], options)
  }

  dateTimeFormat

  constructor(options) {
    super(options = HttpLogger.getOptions(options))
    this.dateTimeFormat = new Intl.DateTimeFormat([], options.dateTimeFormat)
    for (let i = options.level + 1; i < LEVELS[Enum.SIZE]; i++) {
      this[LEVELS[i]] = USELESS_FUNCTION
    }
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
