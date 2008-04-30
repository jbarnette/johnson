require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class BrowserTest < Johnson::TestCase
    def setup
      @context = Johnson::Context.new
      @context.evaluate('Johnson.require("johnson/browser");')
    end

    def test_set_location_returns_location
      filename = "file://#{File.expand_path(__FILE__)}"
      @context.evaluate("window.location = '#{filename}'")
      uri = URI.parse(filename)
      assert_equal(uri.to_s, @context.evaluate('window.location').to_s)
    end
  end
end
