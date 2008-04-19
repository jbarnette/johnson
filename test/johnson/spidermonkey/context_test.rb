require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class ContextTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new(Johnson::SpiderMonkey::Context)
      end
      
      def test_wraps_global_unfuckedly
        assert_same(@context.global, @context.evaluate("this"))
      end
      
      def test_provides_basic_context_interface
        assert(@context.respond_to?(:evaluate))
        assert(@context.respond_to?(:[]))
        assert(@context.respond_to?(:[]=))
      end
    end
  end
end
