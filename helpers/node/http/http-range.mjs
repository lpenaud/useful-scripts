export default class HttpRange {
  start
  end
  size
  length

  get unit() {
    return 'bytes'
  }

  get contentRange() {
    return `${this.unit} ${this.start}-${this.end}/${this.size}`
  }

  constructor(stat, req) {
    const matchs = /^bytes=([0-9]+)\-([0-9]+)?$/
      .exec(req.headers.range)
    if (matchs === null) {
      this.start = 0
      this.end = stat.size
    } else {
      this.start = parseInt(matchs[1])
      this.end = parseInt(matchs[2]) || stat.size
    }
    this.size = stat.size
    this.length = (this.end - this.start)
  }

  setHeader(res) {
    res.setHeader('Content-Length', this.length)
    if (this.size !== this.length) {
      res.setHeader('Content-Range', this.contentRange)
      res.setHeader('Accept-Range', this.unit)
      res.statusCode = 206
    } else {
      res.statusCode = 200
    }
  }
}
