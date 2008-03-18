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
      
      def test_objects_get_wrapped_as_proxies
        assert_kind_of(Johnson::SpiderMonkey::Proxy, @context.evaluate("x = {}"))
        assert_kind_of(Johnson::SpiderMonkey::Proxy, @context.evaluate("new Object()"))
      end
      
      def test_functions_get_wrapped_as_proxies
        f = @context.evaluate("function() {}")
        assert_kind_of(Johnson::SpiderMonkey::Proxy, f)
        assert(f.function?)
      end
      
      def test_calling_non_functions_complains
        assert_raise(Johnson::Error) { @context.evaluate("new Object()").call }
      end
      
      def test_functions_can_be_called
        f = @context.evaluate("function() { return 42; }")
        assert_equal(42, f.call)
      end
      
      def test_functions_can_be_called_with_args
        k = @context.evaluate("function(x) { return x; }")
        assert_equal(42, k.call(42))
      end
      
      def test_proxies_can_be_indexed_by_string
        proxy = @context.evaluate("x = { foo: 42 }")
        assert_kind_of(Johnson::SpiderMonkey::Proxy, proxy)
        
        assert_equal(42, proxy["foo"])
        
        proxy["foo"] = 99
        proxy["bar"] = 42
        
        assert_equal(99, proxy["foo"])
        assert_equal(42, proxy["bar"])
      end
      
      def test_multilevel_indexing_works
        proxy = @context.evaluate("x = { foo: { bar: 42 } }")
        assert_equal(42, proxy["foo"]["bar"])
      end
      
      def test_simple_accessors_work
        proxy = @context.evaluate("x = { foo: 42 }")
        assert_equal(42, proxy.foo)
      end
      
      # FIXME: more tests on accessors/mutators here!
      
    end
  end
end
