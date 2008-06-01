Johnson.require("test/jspec/helper");

jspec.describe("awesomeness", function() {
  it("should be able to set its location", function() {
    var fileLocation = "file://" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";
    var uriLocation = "file:" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";
    window.location = fileLocation;
    Johnson.waitForThreads();
    expect(window.location).to("==", uriLocation);
    expect(document).to("have_constructor", DOMDocument);
    document.body;
    document.body;
    document.body;
    // expect(document.body).to("have_constructor", DOMNode);
  });
});

;