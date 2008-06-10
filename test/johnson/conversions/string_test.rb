require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class StringTest < Johnson::TestCase
      def test_ruby_string_in_js
        @runtime[:v] = "foo"
        assert_js("'foo' == v")
      end

      def test_js_string_in_ruby
        assert_equal("foo", @runtime.evaluate("'foo'"))
      end

      def test_roundtrip
        @runtime[:v] = v = "hola"
        assert_equal(v, @runtime.evaluate("v"))
      end
      
      def test_strings_are_copies
        @runtime[:v] = v = "hola"
        assert_not_same(v, @runtime.evaluate("v"))
      end
    end
  end
end
