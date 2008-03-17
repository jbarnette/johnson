require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class ProxyTest < Johnson::TestCase
      def setup
        @context = Johnson::SpiderMonkey::Context.new
      end
      
      def test_constructing_a_proxy_directly_asplodes
        assert_raise(Johnson::Error) { Johnson::SpiderMonkey::Proxy.new }
      end
      
      def test_something
        proxy = @context.evaluate("x = { foo: 42 }")
      end
    end
  end
end
