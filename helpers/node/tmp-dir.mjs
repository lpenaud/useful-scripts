import * as os from 'os'
import * as path from 'path'
import * as fs from 'fs/promises'
import { createWriteStream, mkdtempSync, rmSync } from 'fs'

function join(prefix) {
  return path.join(os.tmpdir(), prefix + '-')
}

export default class TmpDir {
  static DEFAULT_GENERATOR = () => process.uptime().toString(36)

  static async newInstance(prefix, options) {
    return new TmpDir(await fs.mkdtemp(
      join(prefix),
      options
    ))
  }

  static newInstanceSync(prefix, options) {
    return new TmpDir(mkdtempSync(join(prefix), options))
  }

  static fromDir(dir) {
    return new TmpDir(dir, TmpDir.DEFAULT_GENERATOR)
  }

  dir
  generator

  constructor(dir, generator) {
    this.dir = dir
    this.generator = generator
  }

  createWriteStream(options) {
    return createWriteStream(path.join(this.dir, this.generator()), options)
  }

  _remove() {
    rmSync(this.dir, {
      recursive: true,
      force: true,
    })
  }
}
