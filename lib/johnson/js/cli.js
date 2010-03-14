Ruby.require("uri");
Ruby.require("open-uri");

this.load = this.load || function load() {
  for (var i = 0; i < arguments.length; ++i)
    Johnson.require(arguments[i]);
};

this.print = this.print || function print() {
  for (var i = 0; i < arguments.length; ++i)
    Ruby.puts(arguments[i]);
};

// NOTE: the Rhino version takes an optional encoding
this.readfile = this.readfile || function readFile(path) {
  return Ruby.IO.read(path);
}

// NOTE: the Rhino version takes an optional encoding
this.readUrl = this.readUrl || function readUrl(url) {
  return Ruby.URI.parse(url).read();
}

this.quit = this.quit || function quit() {
  Ruby.exit();
}

this.verison = this.verison || function version() {
  return Ruby.Johnson.VERSION;
}
