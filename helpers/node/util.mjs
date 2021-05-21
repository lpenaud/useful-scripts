import * as fs from 'fs/promises'
import { constants as fsConstants } from 'fs'

/**
 * Function that serves no purpose except to be called.
 * Useful for optional callback.
 * @returns {void}
 */
export const USELESS_FUNCTION = () => undefined

export function toCamelCase(str, regExp = /_|\-/g) {
  let result = ""
  let start = 0
  let matchs
  const matched = (matchs = regExp.exec(str)) !== null
  let cond = matched
  while (cond) {
    result += str[start].toUpperCase() + str.substring(start + 1, matchs.index).toLowerCase()
    start = matchs.index + 1
    cond = (matchs = regExp.exec(str)) !== null
  }
  return !matched ? str.toLowerCase() : result.substr(0, 1).toLowerCase() 
    + result.substring(1)
    + str.substr(start, 1).toUpperCase()
    + str.substring(start + 1).toLowerCase()
}

export function computeIfAbsentMap(map, key, mappingFunction) {
  let value = map.get(key)
  if (value === undefined) {
    value = mappingFunction(key)
    map.set(key, value)
  }
  return value
}

export function computeIfAbsentObject(obj, key, mappingFunction) {
  let value = obj[key]
  if (value === undefined) {
    obj[key] = value = mappingFunction(key)
  }
  return value
}

class SplitResult {
  buf
  start
  end

  constructor(buf, start, end) {
    this.buf = buf
    this.start = start
    this.end = end
  }

  toString(encoding) {
    return this.buf.toString(encoding, this.start, this.end)
  }
}

/**
 * 
 * @param {Buffer} buf
 * @param {Uint8Array} sep
 * @param {number} [start=0]
 */
export function* splitBuffer(buf, sep, start = 0) {
  let end
  while ((end = buf.indexOf(sep, start)) !== -1) {
    yield new SplitResult(buf, start, end)
    start = end + sep.length
  }
  yield new SplitResult(buf, start, end)
}

export async function moveFile(src, dest, overwrite = false) {
  await fs.copyFile(src, dest, overwrite ? 
    fsConstants.COPYFILE_EXCL : undefined)
  await fs.rm(src)
}
