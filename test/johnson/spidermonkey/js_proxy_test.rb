require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class JSProxyTest < Johnson::TestCase
      class Foo
        def self.bar; 10; end
        def bar; 10; end
        def baz(arg); arg; end
      end

      def setup
        @context = Johnson::SpiderMonkey::Context.new
      end
      
      def test_proxies_instances
        @context["foo"] = Foo.new
        assert_js_equal(10, "foo.bar()")
      end
      
      # def test_index_func_call_from_ruby
      #   @context[:Foo] = Foo
      #   assert_equal(10, @context.evaluate("Foo.bar()"))
      # 
      #   @context[:Foo] = Foo
      #   assert_equal(Foo, @context.evaluate("Foo"))
      # 
      #   x = Foo.new
      #   @context[:foo] = x
      #   assert_equal(10, @context.evaluate("foo.bar()"))
      #   assert_equal(x, @context.evaluate("foo"))
      #   assert_equal(10, @context.evaluate("foo.baz(10)"))
      #   assert_equal([10, 9], @context.evaluate("foo.baz([10, 9])"))
      # end
                  
    end
  end
end
