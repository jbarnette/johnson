Ruby.require('net/http');
Johnson.require("johnson/browser/xmlw3cdom");
Johnson.require("johnson/browser/xmlsax");
Johnson.require("johnson/browser/env");

DOMElement.prototype.toString = function() {
  return "<" + this.tagName + (this.className !== "" ? " class='" + this.className + "'" : "") + 
    (this.id !== "" ? " id='" + this.id + "'" : "") + ">";
};