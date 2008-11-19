Johnson.require("johnson/browser");
Johnson.require("johnson/browser/jquery")

var doc = new DOMDocument(Ruby.File.read("/Users/yehuda/Code/johnson/test/assets/jquery_test.html"));
window.document = doc;

// document.getElementById("sndp") == document.getElementById("sndp")
Ruby.p(document.getElementById("sndp") == document.getElementById("sndp"));

$("#header").appendTo("#nothiddendiv").attr("foo", "bar");

Ruby.p($("#nothiddendiv").html())