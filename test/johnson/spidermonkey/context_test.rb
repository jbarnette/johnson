require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class ContextTest < Johnson::TestCase
      def setup
        @context = Johnson::SpiderMonkey::Context.new
        @context.evaluate(Johnson::PRELUDE)
      end
      
      def test_provides_basic_context_interface
        assert(@context.respond_to?(:evaluate))
        assert(@context.respond_to?(:[]))
        assert(@context.respond_to?(:[]=))
      end
      
      class Foo
        def gets_an_unspecified_block
          block_given?
        end
        
        def runs_block(arg, &block)
          yield(arg)
        end
      end
      
      def test_jsend_deals_with_blocks
        func = @context.evaluate("function() {}")
        assert(@context.jsend(Foo.new, :gets_an_unspecified_block, [func]))
      end
      
      def test_jsend_deals_with_specified_blocks
        func = @context.evaluate("function(x) { return x * 2 }")
        assert_equal(4, @context.jsend(Foo.new, :runs_block, [2, func]))
      end
    end
  end
end
