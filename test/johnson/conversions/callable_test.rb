require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class CallableTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end
      
      def test_proc_works_in_jsland
        @context[:squared] = Proc.new { |x| x * x }
        assert_js_equal(4, "squared(2)")
      end
      
      def test_procs_roundtrip
        @context[:k] = k = lambda { |x| x }
        assert_same(k, @context.evaluate("k"))
      end
      
      def test_proc_js_function_proxy_gets_reused
        @context[:k] = k = lambda { |x| x }
        @context[:kk] = k
        assert_js("k === kk")
      end
      
      class CallableThing
        def call
          "foo"
        end
      end
      
      def test_anything_with_a_call_method_can_be_called_as_a_method
        @context[:c] = CallableThing.new
        assert_js_equal("foo", "c()")
      end
    end
  end
end
