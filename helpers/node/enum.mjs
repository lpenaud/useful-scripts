
const SIZE = Symbol('Enum.SIZE')

export default class Enum {
  static get SIZE() {
    return SIZE
  }

  constructor(...values) {
    let i = 0
    for (const value of values) {
      this[i] = value
      this[value] = i++
    }
    this[SIZE] = i
    Object.freeze(this)
  }

  [Symbol.iterator] = () => {
    let i = 0
    return {
      next: () => {
        if (this[i] === undefined) {
          return { done: true }
        }
        return {
          value: this[i++],
          done: false,
        }
      }
    }
  }
}
