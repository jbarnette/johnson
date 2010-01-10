require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module TraceMonkey
    class JSLandProxyTest < Johnson::TestCase
      module AModule
      end
      
      class AClass
        attr_reader :args
        
        def initialize(*args)
          @args = args
        end
      end
      
      class Foo
        class Inner
        end
        
        def self.bar; 10; end

        attr_accessor :bar
        
        def initialize
          @bar = 10
        end
        
        def x2(x)
          x * 2
        end
        
        def add(*args)
          args.inject { |m,n| m += n }
        end
        
        def xform(arg)
          yield(arg)          
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
        @runtime = Johnson::Runtime.new(Johnson::TraceMonkey::Runtime)
      end

      def test_find_constants
        assert_js_equal($LOAD_PATH, "Ruby['$LOAD_PATH']")
      end

      def test_proxies_get_reused
        @runtime["foo"] = @runtime["bar"] = Foo.new
        assert_js_equal(true, "foo === bar")
      end

      def test_attributes_get_added_to_ruby
        foo = @runtime["foo"] = Foo.new
        assert !foo.respond_to?(:johnson)
        @runtime.evaluate("foo.johnson = 'explode';")
        assert foo.respond_to?(:johnson)
        assert_equal('explode', foo.johnson)
        assert_js_equal('explode', 'foo.johnson')
        assert !Foo.new.respond_to?(:johnson)
      end

      def test_assign_function_as_attribute
        foo = @runtime["foo"] = Foo.new
        assert !foo.respond_to?(:johnson)
        f = @runtime.evaluate("foo.johnson = function() { return 'explode'; }")
        assert foo.respond_to?(:johnson)
        assert_equal('explode', foo.johnson)
        assert_js_equal('explode', 'foo.johnson()')
        assert_js_equal(f, 'foo.johnson')
        assert !Foo.new.respond_to?(:johnson)
      end

      def test_assign_function_as_attribute_with_this
        foo = @runtime["foo"] = Foo.new
        @runtime.evaluate("foo.ex_squared = function(x) { return this.x2(x); }")
        assert_equal(4, foo.ex_squared(2))
        @runtime.evaluate("foo.ex_squared = 20;")
        assert_equal(20, foo.ex_squared)
      end

      def test_use_ruby_global_object
        func = @runtime.evaluate("function(x) { return this.x2(x); }")
        foo  = Foo.new
        assert_equal(4, func.call_using(foo, 2))
      end
      
      def test_proxies_roundtrip
        @runtime["foo"] = foo = Foo.new
        assert_same(foo, @runtime.evaluate("foo"))
      end
      
      def test_proxies_classes
        @runtime["Foo"] = Foo
        assert_same(Foo, @runtime.evaluate("Foo"))
      end
      
      def test_proxies_modules
        @runtime["AModule"] = AModule
        assert_same(AModule, @runtime.evaluate("AModule"))
      end
      
      def test_proxies_hashes
        @runtime["beatles"] = { "george" => "guitar" }
        assert_equal("guitar", @runtime.evaluate("beatles['george']"))
      end
      
      def test_getter_calls_0_arity_method
        @runtime["foo"] = Foo.new
        assert_js_equal(10, "foo.bar")
      end
      
      def test_getter_calls_indexer
        @runtime["foo"] = indexable = Indexable.new
        indexable["bar"] = 10
        
        assert_js_equal(10, "foo.bar")
      end
      
      def test_getter_returns_nil_for_unknown_properties
        @runtime["foo"] = Foo.new
        assert_js_equal(nil, "foo.quux")
      end

      def test_setter_calls_key=
        @runtime["foo"] = foo = Foo.new
        assert_js_equal(42, "foo.bar = 42")
        assert_equal(42, foo.bar)
      end
      
      def test_setter_calls_indexer
        @runtime["foo"] = indexable = Indexable.new
        assert_js_equal(42, "foo.monkey = 42")
        assert_equal(42, indexable["monkey"])
      end
      
      def test_calls_attr_reader
        @runtime["foo"] = Foo.new
        assert_js_equal(10, "foo.bar")
      end
      
      def test_calls_1_arity_method
        @runtime["foo"] = Foo.new
        assert_js_equal(10, "foo.x2(5)")
      end
      
      def test_calls_n_arity_method
        @runtime["foo"] = Foo.new
        assert_js_equal(10, "foo.add(4, 2, 2, 1, 1)")
      end
      
      def test_calls_class_method
        @runtime["Foo"] = Foo
        assert_js_equal(Foo.bar, "Foo.bar()")
      end
      
      def test_accesses_consts
        @runtime["Foo"] = Foo
        assert_same(Foo::Inner, @runtime.evaluate("Foo.Inner"))
      end
            
      def test_can_create_new_instances_in_js
        @runtime["AClass"] = AClass
        foo = @runtime.evaluate("AClass.new()")
        assert_kind_of(AClass, foo)
      end
      
      def test_class_proxies_provide_a_ctor
        @runtime["AClass"] = AClass
        foo = @runtime.evaluate("new AClass()")
        assert_kind_of(AClass, foo)
        
        bar = @runtime.evaluate("new AClass(1, 2, 3)")
        assert_equal([1, 2, 3], bar.args)
      end
      
      def test_dwims_blocks
        @runtime["foo"] = Foo.new
        assert_js_equal(4, "foo.xform(2, function(x) { return x * 2 })")
      end
      
      def test_dwims_blocks_for_0_arity_methods
        @runtime[:arr] = [1, 2, 3]
        assert_js_equal([2, 4, 6], "arr.collect(function(x) { return x * 2 })")
      end
      
      def test_scope_for_with
        assert_js_equal(84, "with (rb) { b + b }", :b => 1, :rb => { "b" => 42 })
      end
      
      def test_lambdas_for_with
        assert_js_equal(84, "with (rb) { b(42) }", :rb => { "b" => lambda { |x| x * 2 } })
      end
      
      class MethodForWith
        def b(x); x * 2; end
      end
      
      def test_method_for_with
        assert_js_equal(84, "with (rb) { b(42) }", :rb => MethodForWith.new)
      end

      def test_raises_string_to_ruby
        assert_raise(Johnson::Error) { @runtime.evaluate("throw 'my string';") }
      end

      def test_raises_object_to_ruby
        assert_raise(Johnson::Error) { @runtime.evaluate("throw { bad: true };") }
      end

      def test_raises_exception_to_ruby
        assert_raise(Johnson::Error) { @runtime.evaluate("undefinedValue();") }
      end

      def test_js_property_false_should_not_invoke
        klass = Class.new do
          def bar ; 10 ; end
          def js_property?(name) ; false ; end
        end
        @runtime['foo'] = foo = klass.new
        assert_equal foo.method(:bar), @runtime.evaluate("foo.bar")
      end

      def test_js_property_nil_should_not_invoke
        klass = Class.new do
          def bar ; 10 ; end
          def js_property?(name) ; nil ; end
        end
        foo = klass.new
        assert_js_equal(foo.method(:bar), "foo.bar", :foo => foo)
      end

      def test_js_property_true_should_invoke_0_arity
        klass = Class.new do
          def bar ; 10 ; end
          def js_property?(name) ; true ; end
        end
        assert_js_equal(10, "foo.bar", :foo => klass.new)
      end

      def test_js_property_on_n_arity_should_raise_exception
        klass = Class.new do
          def bar(n) ; 10 + n ; end
          def js_property?(name) ; true ; end
        end
        @runtime['foo'] = klass.new
        assert_raises(ArgumentError) do
          @runtime.evaluate("foo.bar")
        end
      end
    end
  end
end
