Johnson.waitForThreads = function() {
  // FIXME: This sucks ass
  Ruby.eval("(Thread.list - [Thread.main]).each {|t| t.join}");
};

Johnson.require("johnson/browser");
Johnson.require("johnson/browser/jquery");
var fileLocation = "file://" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";
window.location = fileLocation;
Johnson.waitForThreads();    
