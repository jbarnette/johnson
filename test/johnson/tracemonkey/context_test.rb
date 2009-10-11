require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module TraceMonkey
    class ContextTest < Johnson::TestCase
      def setup
        @runtime = Johnson::Runtime.new(Johnson::TraceMonkey::Runtime)
      end
      
      def test_wraps_global_unfuckedly
        assert_same(@runtime.global, @runtime.evaluate("this"))
      end
      
      def test_provides_basic_runtime_interface
        assert(@runtime.respond_to?(:evaluate))
        assert(@runtime.respond_to?(:[]))
        assert(@runtime.respond_to?(:[]=))
      end
    end
  end
end
