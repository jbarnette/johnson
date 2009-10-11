require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class NilTest < Johnson::TestCase
      def test_ruby_nil_is_js_null
        @runtime[:v] = nil
        assert_equal(true, @runtime.evaluate("v == null"))
      end

      def test_js_null_is_ruby_nil
        assert_nil(@runtime.evaluate("null"))
      end

      def test_js_undefined_is_ruby_nil
        assert_nil(@runtime.evaluate("undefined"))
      end
    end
  end
end
