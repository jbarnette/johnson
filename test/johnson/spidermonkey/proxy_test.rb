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
        f = @context.evaluate("function(x) { return x * 2; }")
        assert_equal(84, f.call(42))
      end
      
      def test_functions_can_be_used_as_procs
        f = @context.evaluate("function(x) { return x * 2; }")
        a = [1, 2, 3]
        
        assert_equal([2, 4, 6], a.collect(&f))
      end
      
      def test_function_proxies_are_called_with_a_global_this
        f = @context.evaluate("x = 42; function() { return this.x; }")
        assert_equal(42, f.call)
      end
      
      def test_can_be_indexed_by_string
        proxy = @context.evaluate("x = { foo: 42 }")
        assert_kind_of(Johnson::SpiderMonkey::Proxy, proxy)
        
        assert_equal(42, proxy["foo"])
        
        proxy["foo"] = 99
        proxy["bar"] = 42
        
        assert_js_equal(99, "x.foo")
        assert_equal(99, proxy["foo"])
        assert_equal(42, proxy["bar"])
      end
      
      def test_multilevel_indexing_works
        proxy = @context.evaluate("x = { foo: { bar: 42 , baz: function() { return 42 } } }")
        assert_equal(42, proxy["foo"]["bar"])
        assert_equal(42, proxy["foo"]["baz"].call)
      end
      
      def test_respond_to_works
        proxy = @context.evaluate("x = { foo: 42 }")
        assert(!proxy.respond_to?(:bar))
        assert(proxy.respond_to?(:foo))
      end
      
      def test_respond_to_always_returns_true_for_assignment
        proxy = @context.evaluate("x = {}")
        assert(proxy.respond_to?(:bar=))
      end
      
      def test_accessor
        proxy = @context.evaluate("x = { foo: 42 }")
        assert_equal(42, proxy.foo)
      end
      
      def test_mutator
        proxy = @context.evaluate("x = {}")
        proxy.foo = 42
        
        assert_js_equal(42, "x.foo")
        assert_equal(42, proxy.foo)
      end
      
      def test_method_with_no_arguments
        proxy = @context.evaluate("x = { foo: function() { return 42 } }")
        assert_equal(42, proxy.foo)
      end
      
      def test_method_with_one_argument
        proxy = @context.evaluate("f = { f: function(x) { return x * 2 } }")
        assert_equal(84, proxy.f(42))
      end
      
      def test_method_with_multiple_arguments
        proxy = @context.evaluate("x = { add: function(x, y) { return x + y } }")
        assert_equal(42, proxy.add(40, 2))
      end
      
      # def test_supports_each_if_enumerable
      #   proxy = @context.evaluate("[1, 2, 3]")
      #   values = []
      #   
      #   proxy.each { |n| values << n }
      # end
    end
  end
end
