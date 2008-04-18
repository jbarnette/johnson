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

Johnson.Generator = function(enumerableProxy) {
  this.generator = new Ruby.Generator(enumerableProxy);
};

Johnson.Generator.prototype.next = function() {
  if(this.generator['next?']) {
    return this.generator.next;
  }
  throw StopIteration;
}

Johnson.Generator.create = function() {
  return new Johnson.Generator(this);
}

null; // no need to marshal a result
