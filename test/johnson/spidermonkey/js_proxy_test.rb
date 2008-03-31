require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class JSProxyTest < Johnson::TestCase
      class Foo
        attr_accessor :bar
        
        def initialize
          @bar = 10
        end
      end
      
      class Indexable
        def initialize
          @store = {}
        end
        
        def [](key)
          @store[key]
        end
        
        def []=(key, value)
          @store[key] = value
        end
        
        def key?(key)
          @store.key?(key)
        end
      end

      def setup
        @context = Johnson::SpiderMonkey::Context.new
      end
      
      def test_getter_calls_0_arity_method
        @context["foo"] = Foo.new
        assert_js_equal(10, "foo.bar")
      end
      
      def test_getter_calls_indexer
        @context["foo"] = indexable = Indexable.new
        indexable["bar"] = 10
        
        assert_js_equal(10, "foo.bar")
      end
      
      def test_getter_returns_nil_for_unknown_properties
        @context["foo"] = Foo.new
        assert_js_equal(nil, "foo.quux")
      end

      def test_setter_calls_key=
        @context["foo"] = foo = Foo.new
        assert_js_equal(42, "foo.bar = 42")
        assert_equal(42, foo.bar)
      end
      
      def test_setter_calls_indexer
        @context["foo"] = indexable = Indexable.new
        assert_js_equal(42, "foo.monkey = 42")
        assert_equal(42, indexable["monkey"])
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
