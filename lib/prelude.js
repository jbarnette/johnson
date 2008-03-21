var Ruby = {};

Ruby.Symbol = function(string) {
  this.string = string;
};

Ruby.Symbol.prototype = {
  toString: function() {
    return this.string;
  },

  inspect: function() {
    return ":" + this.toString();
  }
};

Ruby.symbolCache = {};

Ruby.symbolize = function(string) {
  if (!Ruby.symbolCache[string])
    Ruby.symbolCache[string] = new Ruby.Symbol(string);
    
  return Ruby.symbolCache[string];
};

null; // no need to marshal a result
