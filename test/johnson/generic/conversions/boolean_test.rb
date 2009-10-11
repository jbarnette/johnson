require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class BooleanTest < Johnson::TestCase
      def test_truthiness
        @runtime[:v] = true
        assert_same(true, @runtime.evaluate("v === true"))
      end

      def test_dirty_lies
        @runtime[:v] = false
        assert_same(false, @runtime.evaluate("v === true"))
      end
    end
  end
end
