import { Writable } from 'stream'
import { splitBuffer } from '../util.mjs'
import { END_EVENT, asyncQueue, asyncParallel } from '../async.mjs'
import TmpDir from '../tmp-dir.mjs'

const EOL = Buffer.from('\r\n')
const SEP = Buffer.from('--')
const REG_EXP_FILENAME = /filename="(.+)"\s*$/
const REG_EXP_CONTENT_TYPE = /(\S+\/\S+)\s*$/
const TMP_DIR = new TmpDir(process.cwd(), () => '.' + TmpDir.DEFAULT_GENERATOR())

const NEW_FILE_METHOD = Symbol('NEW FILE METHOD')

class HttpFile {
  filename
  contentType
  stream

  get path() {
    return this.stream.path
  }

  constructor(filename, contentType) {
    this.filename = filename
    this.contentType = contentType
    this.stream = TMP_DIR.createWriteStream()
  }

  write(data, cb) {
    if (!this.stream.write(data)) {
      this.stream.once('drain', cb)
    } else {
      queueMicrotask(cb)
    }
  }

  close(callback) {
    this.stream.close(callback)
  }
}

export default class HttpForm extends Writable {
  boundary
  files

  get lastFile() {
    return this.files[this.files.length - 1]
  }

  constructor(contentType, options) {
    super(options)
    this.boundary = Buffer.from('--' + contentType.match(/boundary=([^;]+)/)[1])
    this.files = []
  }

  /**
   * 
   * @param {Buffer} chunk 
   * @param {string} encoding 
   * @param callback 
   */
  _write(chunk, encoding, callback) {
    const queue = []
    let start = chunk.indexOf(this.boundary)
    let end = 0
    while (start !== -1) {
      if (this.files.length > 0) {
        queue.push(this.lastFile.write.bind(this.lastFile, chunk.subarray(end, start)))
      }
      if (SEP.compare(chunk, start + this.boundary.length, start + this.boundary.length + SEP.length) === 0) {
        end = chunk.length
        break
      }
      end = this[NEW_FILE_METHOD](chunk, start + this.boundary.length + EOL.length)
      start = chunk.indexOf(this.boundary, end)
    }
    if (end < chunk.length) {
      queue.push(this.lastFile.write.bind(this.lastFile, chunk.subarray(end)))
    }
    asyncQueue(queue).once(END_EVENT, callback)
  }

  _final(callback) {
    asyncParallel(this.files.map(f => f.close.bind(f)))
      .once(END_EVENT, callback)
  }

  [NEW_FILE_METHOD](buf, start) {
    const itLine = splitBuffer(buf, EOL, start)
    // Content-Disposition: form-data; name="infile"; filename="file.txt"
    const first = itLine.next().value
    // Content-Type: text/plain
    const second = itLine.next().value
    // Empty line
    const third = itLine.next().value
    this.files.push(new HttpFile(
      REG_EXP_FILENAME.exec(first.toString())[1],
      REG_EXP_CONTENT_TYPE.exec(second.toString())[1]
    ))
    return third.end + EOL.length
  }
}
