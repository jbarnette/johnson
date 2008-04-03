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

null; // no need to marshal a result
