function parseArg(args) {
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

// Deno import.meta.main
// main(Deno.args.slice())

// node !module.parent
// main(process.argv.slice(2))
