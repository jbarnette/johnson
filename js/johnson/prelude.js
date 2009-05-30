var Johnson = {};

Johnson.Symbol = function(string) {
  this.string = string;
};

Johnson.Symbol.prototype = {
  toString: function() {
    return this.string;
  },

  inspect: function() {
    return ":" + this.toString();
  }
};

Johnson.symbolCache = {};

Johnson.symbolize = function(string) {
  if (!Johnson.symbolCache[string])
    Johnson.symbolCache[string] = new Johnson.Symbol(string);

  return Johnson.symbolCache[string];
};

Object.defineProperty(String.prototype, "toSymbol", function() {
  return Johnson.symbolize(this.toString());
}, Object.READ_ONLY | Object.NON_DELETABLE);

Johnson.Generator = function(enumerableProxy) {
  this.items = enumerableProxy.toArray();
  this.index = 0;
};

Johnson.Generator.prototype.hasNext = function() {
  var len = this.items.length;
  if (typeof len != 'number') len = this.items.length();
  return this.index < len;
}

Johnson.Generator.prototype.next = function() {
  if (this.hasNext()) {
    return this.items[this.index++];
  }
  throw StopIteration;
}

Johnson.Generator.create = function() {
  return new Johnson.Generator(this);
}

Johnson.required = {};

Johnson.require = function(file) {
  file = Ruby.File.join(Ruby.File.dirname(file),
    Ruby.File.basename(file, ".js") + ".js");

  if(Johnson.required[file]) return false;

  for(var directory in Ruby["$LOAD_PATH"]) {
    var path = Ruby.File.join(directory, file);

    if(Ruby.File.send("file?", path)) {
      Johnson.required[file] = true;
      Johnson.runtime.load(path);

      return true;
    }
  }

  throw Ruby.LoadError;
}

this.__defineGetter__("__FILE__", function() {
  try { throw new Error; } catch(e) {
    return e.stack.split("\n")[2].split("@")[1].split(":").slice(0,-1).join(":");
  }
})

null; // no need to marshal a result
