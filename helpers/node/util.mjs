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

export function defaultValues(defaults, values) {
  if (values === undefined) {
    return defaults
  }
  for (const key in defaults) {
    if (values[key] === undefined) {
      values[key] = defaults[key]
    }
  }
  return values
}
