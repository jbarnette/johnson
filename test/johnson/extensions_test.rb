require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  module Extensions
    class DefinePropertyTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
        @context.evaluate("x = {}")
      end      
      
      def test_object_can_define_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42)")
        assert_js_equal(42, "x.answer")
      end
      
      def test_object_can_define_unenumerable_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42)")
        @context.evaluate <<-JS
          y = [];
          for(prop in x) if(prop == "answer") y.push(prop)
        JS
        assert_js("y.length == 0")
      end
      
      def test_object_can_define_enumerable_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42, Object.ITERABLE)")
        @context.evaluate <<-JS
          y = [];
          for(prop in x) if(prop == "answer") y.push(prop)
        JS
        assert_js("y.length == 1")
      end
      
      def test_object_can_define_read_only_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42, Object.READ_ONLY)")
        @context.evaluate("x.answer = 47")
        assert_js_equal(42, "x.answer")
      end
      
      def test_object_can_define_non_deletable_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42, Object.NON_DELETABLE)")
        @context.evaluate("r = (delete x.answer)")
        assert_js_equal(false, "r")
        assert_js_equal(42, "x.answer")
      end
      
      def test_object_can_define_mixed_property
        @context.evaluate("Object.defineProperty(x, 'answer', 42, Object.NON_DELETABLE | Object.READ_ONLY)")
        @context.evaluate("r = (delete x.answer)")
        @context.evaluate("x.answer = 47")
        assert_js_equal(false, "r")
        assert_js_equal(42, "x.answer")
      end      
    end
  end
end
