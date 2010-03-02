require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module TraceMonkey
    class RubyLandProxyTest < Johnson::TestCase
      def setup
        @runtime = Johnson::Runtime.new(Johnson::TraceMonkey::Runtime)
      end
      
      def test_constructing_a_proxy_directly_asplodes
        assert_raise(Johnson::Error) { Johnson::TraceMonkey::RubyLandProxy.new }
      end
      
      def test_objects_get_wrapped_as_proxies
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, @runtime.evaluate("x = {}"))
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, @runtime.evaluate("new Object()"))
      end
      
      def test_proxies_get_unwrapped_when_roundtripping
        proxy = @runtime.evaluate("x = {}")
        @runtime["y"] = proxy
        assert(@runtime.evaluate("x === y"))
      end

      def test_reponds_to?
        proxy = @runtime.evaluate("x = {}")
        assert ! proxy.respond_to?(:foo)
        assert ! proxy.respond_to?("foo")
      end
      
      def test_array_indexable
        proxy = @runtime.evaluate("var x = [1,2,3]; x")
        assert_equal(1, proxy[0])
        assert_equal(1, proxy['0'])

        proxy[0] = 10
        assert_js_equal(10, 'x[0]')
      end
      
      def test_hash_indexable
        proxy = @runtime.evaluate("var x = { 0: 1, 1: 2, 2: 3 }; x")
        assert_equal(1, proxy[0])
        assert_equal(1, proxy['0'])

        proxy[0] = 10
        assert_js_equal(10, 'x[0]')
      end

      def test_functions_get_wrapped_as_proxies
        f = @runtime.evaluate("function() {}")
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, f)
        assert(f.function?)
      end

      def test_function?
        f = @runtime.evaluate("function() {}")
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, f)
        assert(f.function?)

        f = @runtime.evaluate("new Object()")
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, f)
        assert(!f.function?)
      end
      
      def test_calling_non_functions_complains
        o = @runtime.evaluate("new Object()")
        assert_equal(false, o.respond_to?(:call))
        assert_raise(NoMethodError) { o.call }
      end
      
      def test_functions_can_be_called
        f = @runtime.evaluate("function() { return 42; }")
        assert_equal(42, f.call)
      end
      
      def test_functions_can_be_called_with_args
        f = @runtime.evaluate("function(x) { return x * 2; }")
        assert_equal(84, f.call(42))
      end
      
      def test_functions_can_be_used_as_procs
        f = @runtime.evaluate("function(x) { return x * 2; }")
        a = [1, 2, 3]
        
        assert_equal([2, 4, 6], a.collect(&f))
      end
      
      def test_function_proxies_are_called_with_a_global_this
        f = @runtime.evaluate("x = 42; function() { return this.x; }")
        assert_equal(42, f.call)
      end
      
      def test_can_be_indexed_by_string
        proxy = @runtime.evaluate("x = { foo: 42 }")
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, proxy)
        
        assert_equal(42, proxy["foo"])
        
        proxy["foo"] = 99
        proxy["bar"] = 42
        
        assert_js_equal(99, "x.foo")
        assert_equal(99, proxy["foo"])
        assert_equal(42, proxy["bar"])
      end
      
      def test_can_be_indexed_by_symbol
        proxy = @runtime.evaluate("x = { foo: 42 }")
        assert_kind_of(Johnson::TraceMonkey::RubyLandProxy, proxy)
        
        assert_equal(42, proxy[:foo])
        
        proxy[:foo] = 99
        proxy[:bar] = 42
        
        assert_js_equal(99, "x.foo")
        assert_equal(99, proxy[:foo])
        assert_equal(42, proxy[:bar])
      end
      
      def test_multilevel_indexing_works
        proxy = @runtime.evaluate("x = { foo: { bar: 42 , baz: function() { return 42 } } }")
        assert_equal(42, proxy["foo"]["bar"])
        assert_equal(42, proxy["foo"]["baz"].call)
      end
      
      def test_respond_to_works
        proxy = @runtime.evaluate("x = { foo: 42 }")
        assert(!proxy.respond_to?(:bar))
        assert(proxy.respond_to?(:foo))
      end
      
      def test_respond_to_always_returns_true_for_assignment
        proxy = @runtime.evaluate("x = {}")
        assert(proxy.respond_to?(:bar=))
      end
      
      def test_accessor
        proxy = @runtime.evaluate("x = { foo: 42 }")
        assert_equal(42, proxy.foo)
      end
      
      def test_mutator
        proxy = @runtime.evaluate("x = {}")
        proxy.foo = 42
        
        assert_js_equal(42, "x.foo")
        assert_equal(42, proxy.foo)
      end
      
      def test_method_with_no_arguments
        proxy = @runtime.evaluate("x = { foo: function() { return 42 } }")
        assert_equal(42, proxy.foo)
      end
      
      def test_method_with_one_argument
        proxy = @runtime.evaluate("f = { f: function(x) { return x * 2 } }")
        assert_equal(84, proxy.f(42))
      end
      
      def test_method_with_multiple_arguments
        proxy = @runtime.evaluate("x = { add: function(x, y) { return x + y } }")
        assert_equal(42, proxy.add(40, 2))
      end
      
      def test_supports_each_on_arrays
        proxy = @runtime.evaluate("[1, 2, 3]")
        values = []
        
        proxy.each { |n| values << n }
        assert_equal([1, 2, 3], values)
      end
      
      def test_supports_each_on_things_that_arent_arrays
        proxy = @runtime.evaluate("x = { foo: 'fooval', bar: 'barval' }; x[0] = 42; x")
        values = {}
        
        proxy.each { |k, v| values[k] = v }
        assert_equal({ 'foo' => 'fooval', 'bar' => 'barval', 0 => 42 }, values)
      end
      
      def test_each_passes_an_exception
        proxy = @runtime.evaluate("x = { foo: 'fooval', bar: 'barval' }; x[0] = 42; x")
        values = {}
        
        assert_raise(RuntimeError) do
          proxy.each do |k, v|
            values[k] = v
            raise "splat" if values.keys.size == 2
          end
        end
        assert_equal({ 'foo' => 'fooval', 'bar' => 'barval' }, values)
      end
      
      def test_is_enumerable
        proxy = @runtime.evaluate("[1, 2, 3]")
        assert_kind_of(Enumerable, proxy)
        
        assert_equal([2, 4, 6], proxy.collect { |n| n * 2 })
      end
      
      def test_has_a_length
        proxy = @runtime.evaluate("[1, 2, 3]")
        assert_equal(3, proxy.length)
      end
      
      def test_length_is_aliased_as_size
        proxy = @runtime.evaluate("[1, 2, 3]")
        assert_equal(3, proxy.size)
      end
      
      def test_length_for_arrays_ignores_non_numeric_properties
        proxy = @runtime.evaluate("x = [1, 2, 3]; x['foo'] = 'bar'; x")
        assert_equal(3, proxy.length)
      end
      
      def test_length_for_objects_includes_all_properties
        proxy = @runtime.evaluate("x = { foo: 'foo', bar: 'bar', 0: 42 }")
        assert_equal(3, proxy.length)
      end

      def test_raises_in_js
        original = RuntimeError.new("an exception")
        @runtime["foo"] = lambda { raise original }
        raised = @runtime.evaluate "x = null; try { foo(); } catch(ex) { x = ex; }; x"
        assert_kind_of RuntimeError, raised
        assert_equal original, raised
        assert_equal "an exception", raised.message
      end

      def test_uncaught_exceptions_have_decent_stack_trace
        @runtime["foo"] = lambda { raise RuntimeError.new("an exception") }
        line_number = __LINE__ - 1 # reference to previous line
        begin
          @runtime.evaluate "foo()", "myfile", 7
        rescue RuntimeError => e
          assert_equal "an exception", e.message
          first_js_frame = e.stack_deck.detect {|q| q.language == 'JavaScript' }
          assert_equal "myfile:7", "#{first_js_frame.filename}:#{first_js_frame.lineno}"
          assert_match %r/#{__FILE__}:#{line_number}\b/, e.stack_deck[0].to_s
        else
          flunk "exception was not raised"
        end
      end

      def test_array_multiple_assignment
        a = @runtime.evaluate("[1,2,3]")
        x, y, z = a
        
        assert_equal(1, x)
        assert_equal(2, y)
        assert_equal(3, z)
      end

      def test_throwing_in_js_goes_to_ruby
        func = @runtime.evaluate('function () { throw "foo"; }')
        assert_raise(Johnson::Error) {
          func.call
        }
      end
    end
  end
end
