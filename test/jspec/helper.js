Johnson.require("test/jspec/jspec");
Johnson.require("johnson/browser");

Johnson.waitForThreads = function() {
  // FIXME: This sucks ass
  Ruby.eval("(Thread.list - [Thread.main]).each {|t| t.join}");
};
