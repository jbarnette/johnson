require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class BrowserTest < Johnson::TestCase
    def setup
      @runtime = Johnson::Runtime.new
      @runtime.evaluate('Johnson.require("johnson/browser");')
    end

    def test_set_location_returns_location
      filename = "file://#{File.expand_path(__FILE__)}"

      may_thread {
        @runtime.evaluate("window.location = '#{filename}'")
      }

      uri = URI.parse(filename)
      assert_equal(uri.to_s, @runtime.evaluate('window.location').to_s)
    end

    def may_thread(&block)
      block.call
      (Thread.list - [Thread.main]).each { |t| t.join }
    end
  end
end
