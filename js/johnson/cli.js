Ruby.require("uri");
Ruby.require("open-uri");

function load() {
  for (var i = 0; i < arguments.length; ++i)
    Johnson.require(arguments[i]);
}

function print() {
  for (var i = 0; i < arguments.length; ++i)
    Ruby.puts(arguments[i]);
}

// NOTE: the Rhino version takes an optional encoding
function readFile(path) {
  return Ruby.IO.read(path);
}

// NOTE: the Rhino version takes an optional encoding
function readUrl(url) {
  return Ruby.URI.parse(url).read();
}

function quit() {
  Ruby.exit();
}

function version() {
  return Ruby.Johnson.VERSION;
}
