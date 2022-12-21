# JavaScript

## Download generated file

```js
/**
 * Generate a new text file then ask the user to download it.
 * @param {string} content Content of the new text file.
 * @param {string} name Default filename
 */
function downloadFile(content, name='content.txt') {
  // Create the file
  const blob = new Blob([content], { type: 'text/plain' });
  // Create the anchor element
  const a = document.createElement('a');
  // Create the URL to the generated file
  a.href = window.URL.createObjectURL(blob);
  // Set the filename
  a.download = name;
  // Ask the user to download it
  a.click()
}
```

## Get all the URL of a HTML element

```js
/**
 * Get all URLs in HTML element.
 * @param {HTMLElement} root Root of the all anchors elements.
 * @returns Array of all anchors elements.
 */
function getAllURLs(root) {
  return Array.from(root.getElementsByTagName('a'));
}
```


## Generate a list of urls

```js
/**
 * Download a list of url in a HTML element.
 * @param {HTMLElement} root Root of the all anchors elements.
 * @param name Default filename
 */
function createUrlsList(root, name='url.list') {
  downloadFile(getAllURLs(root)
    .reduce((acc, val) => acc + val.href + '\n', ''), name)
}
```

## Parse CLI argument

### On Node.js

```js
/**
 * Parse cli arguement as a plain object.
 * @example
 * // return { help: false, arg: value1, a: value2 }
 * parseArgs(["--arg", "value1", "-a", "value2"]);
 * @example
 * // return { help: false, arg: ["value1", "value2"] }
 * parseArgs(["--arg", "value1", "--arg", "value2"])
 * @example
 * // return { help: true, _: ["p1", "p2"] }
 * parseArgs(["--help", "p1", "p2"])
 * @example
 * // return { help: true, _: "p1", }
 * parseArgs(["--help", "p1"])
 * @param {string[]} args Arguments from cli
 * @returns {{[key: string]: string}} Parsed arguements as plain object.
 */
function parseArgs(args) {
  const positional = "_";
  const options = {};
  const regExp = /^--?([a-z]+)$/i;
  let arg = args.shift();
  let key = positional;
  while (arg !== undefined) {
    const match = regExp.exec(arg);
    // it's a value
    if (match === null) {
      if (options[key] === undefined) {
        options[key] = arg;
      } else {
        // if more than one
        if (typeof options[key] === "string") {
          options[key] = [options[key]]
        }
        options[key].push(arg);
      }
      key = positional;
    } else {
      // If key haven't value set to true
      if (key !== positional) {
        options[key] = true;
      }
      key = match[1];
    }
    arg = args.shift();
  }
  return {
    ...options,
    // Convert undefined value to boolean
    help: (options.help || options.h) === true,
  };
}

function main(args) {
  const options = parseArgs(args);
  // do things
}

if (!module.parent) {
  main(process.argv.slice(2));
}
```

### On Deno

```js
/**
 * Parse cli arguement as a plain object.
 * @example
 * // return { help: false, arg: value1, a: value2 }
 * parseArgs(["--arg", "value1", "-a", "value2"]);
 * @example
 * // return { help: false, arg: ["value1", "value2"] }
 * parseArgs(["--arg", "value1", "--arg", "value2"])
 * @example
 * // return { help: true, _: ["p1", "p2"] }
 * parseArgs(["--help", "p1", "p2"])
 * @example
 * // return { help: true, _: "p1", }
 * parseArgs(["--help", "p1"])
 * @param {string[]} args Arguments from cli
 * @returns {{[key: string]: string}} Parsed arguements as plain object.
 */
function parseArgs(args) {
  const positional = "_";
  const options = {};
  const regExp = /^--?([a-z]+)$/i;
  let arg = args.shift();
  let key = positional;
  while (arg !== undefined) {
    const match = regExp.exec(arg);
    // it's a value
    if (match === null) {
      if (options[key] === undefined) {
        options[key] = arg;
      } else {
        // if more than one
        if (typeof options[key] === "string") {
          options[key] = [options[key]]
        }
        options[key].push(arg);
      }
      key = positional;
    } else {
      // If key haven't value set to true
      if (key !== positional) {
        options[key] = true;
      }
      key = match[1];
    }
    arg = args.shift();
  }
  return {
    ...options,
    // Convert undefined value to boolean
    help: (options.help || options.h) === true,
  };
}

function main(args) {
  const options = parseArgs(args);
  // do things
}

if (import.meta.main) {
  main(Deno.args.slice());
}
```