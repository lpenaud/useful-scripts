import { EventEmitter } from 'events'

export const DONE_EVENT = Symbol()
export const END_EVENT = Symbol()

/**
 * @callback AsyncCallback
 * @param {...any} args
 * @returns {void}
 */

/**
 * @callback AsyncFunction
 * @param {AsyncCallback} callback
 * @returns {void}
 */

/**
 * Queue async functions.
 * @param {Iterable<AsyncFunction>} functions Async function to queue.
 * @returns {EventEmitter} Emitter to listen
 */
export function asyncQueue(functions) {
  const it = functions[Symbol.iterator]()
  const emitter = new EventEmitter()
  const callback = (...results) => {
    emitter.emit(DONE_EVENT, ...results)
    factory()
  }
  const task = next => {
    if (next.done) {
      emitter.emit(END_EVENT)
    } else {
      next.value(callback)
    }
  }
  const factory = () => queueMicrotask(task.bind(undefined, it.next()))
  factory()
  return emitter
}

/**
 * Put async function in the event loop.
 * @param {Iterable<AsyncFunction>} functions Functions to put in the event loop.
 * @returns {EventEmitter} Emitter to listen.
 */
export function asyncParallel(functions) {
  const emitter = new EventEmitter()
  const it = functions[Symbol.iterator]()
  const callback = (...results) => {
    emitter.emit(DONE_EVENT, ...results)
    if (it.next().done) {
      emitter.emit(END_EVENT)
    }
  }
  for (const func of functions) {
    queueMicrotask(func.bind(undefined, callback))
  }
  if (it.next().done) {
    queueMicrotask(emitter.emit.bind(emitter, END_EVENT))
  }
  return emitter
}
