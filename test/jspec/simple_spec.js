Johnson.require("test/jspec/helper");

var setup = function() {
  var fileLocation = "file://" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";
  window.location = fileLocation;
  Johnson.waitForThreads();    
}

setup();

jspec.describe("browser emulator", function() {
  
  it("can set its location", function() {
    var uriLocation = "file:" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";    
    expect(window.location).to("==", uriLocation);
  });
  
  it("makes the document node a DOMDocument element", function() {
    // setup();
    expect(document).to("have_constructor", DOMDocument);
  });

  it("makes the document body a DOMNode", function() {
    // setup();
    expect(document.body).to("have_constructor", DOMNode);    
  })

  it("makes childNodes a DOMNodeList", function() {
    // setup();    
    expect(document.body.childNodes).to("have_constructor", DOMNodeList);    
  })

  it("knows how to get an element by ID and get its correct tagName", function() {
    // setup();
    expect(document.getElementById('test').tagName).to("==", "HR");    
  })

  it("sets the constructor of elements gotten via getElementsByTagName to DOMNode", function() {
    // setup();    
    expect(document.getElementsByTagName("hr")[0]).to("have_constructor", DOMNode);    
  })

  it("knows how to get the right tagName from elements gotten via getElementsByTagName", function() {
    // setup();    
    expect(document.getElementsByTagName("hr")[0].tagName).to("==", "HR");
  })
    
});

jspec.describe("jQuery Support", function() {
  it("loads jQuery", function() {
    Johnson.require("johnson/browser/jquery");
    expect($).to("==", jQuery);
  });
  
  it("gets elements with $(tag)", function() {
    expect($("hr").length).to("==", 2);
  });
});

Johnson.require("johnson/browser/jquery");
jspec.describe("The jQuery file", function() {
  it("loads the jQuery HTML files", function() {
    window.location = "file:" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/jquery_test.html";
    Johnson.waitForThreads();
    expect($("h1").length).to("==", 1);
  });
});
