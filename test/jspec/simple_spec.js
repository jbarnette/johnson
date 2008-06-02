Johnson.require("test/jspec/helper");

jspec.describe("browser emulator", function() {
  var setup = function() {
    var fileLocation = "file://" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";
    window.location = fileLocation;
    Johnson.waitForThreads();    
  }
  
  it("can set its location", function() {
    setup();
    var uriLocation = "file:" + Ruby.File.expand_path(Ruby.Dir.pwd()) + "/test/assets/index.html";    
    expect(window.location).to("==", uriLocation);
  });
  
  it("makes the document node a DOMDocument element", function() {
    setup();
    expect(document).to("have_constructor", DOMDocument);
  });

  it("makes the document body a DOMNode", function() {
    setup();
    expect(document.body).to("have_constructor", DOMNode);    
  })

  it("makes childNodes a DOMNodeList", function() {
    setup();    
    expect(document.body.childNodes).to("have_constructor", DOMNodeList);    
  })

  it("knows how to get an element by ID and get its correct tagName", function() {
    setup();
    expect(document.getElementById('test').tagName).to("==", "HR");    
  })

  it("sets the constructor of elements gotten via getElementsByTagName to DOMNode", function() {
    setup();    
    expect(document.getElementsByTagName("hr")[0]).to("have_constructor", DOMNode);    
  })

  it("knows how to get the right tagName from elements gotten via getElementsByTagName", function() {
    setup();    
    expect(document.getElementsByTagName("hr")[0].tagName).to("==", "HR");
  })
  
});

;