// Init
Johnson.require("johnson/browser");
Johnson.require("johnson/browser/jquery");

Johnson.waitForThreads = function() {
  // FIXME: This sucks ass
  Ruby.eval("(Thread.list - [Thread.main]).each {|t| t.join}");
};

window.location = "file://" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/jquery_test.html";
Ruby.eval("(Thread.list - [Thread.main]).each {|t| t.join}");

document = Ruby.Taka.DOM.send("HTML",
    Ruby.File.open(Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/jquery_test.html")
);

// Load the test runner
Johnson.require("test/jquery_units/test_helper.js");

Johnson.require("test/jquery_units/units/core.js");
// // Load the tests
// load(
//     "test/unit/core.js",
//     "test/unit/selector.js",
//     "test/unit/event.js"
//     //"test/unit/fx.js",
//     //"test/unit/ajax.js"
// );

// Display the results
results();
