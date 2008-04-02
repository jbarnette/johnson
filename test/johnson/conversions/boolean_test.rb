require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class BooleanTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end
      
      def test_truthiness
        @context[:v] = true
        assert_same(true, @context.evaluate("v === true"))
      end

      def test_dirty_lies
        @context[:v] = false
        assert_same(false, @context.evaluate("v === true"))
      end
    end
  end
end
