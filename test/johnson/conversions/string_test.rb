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

      def test_multibyte_character_roundtrip_js
        s = @runtime.evaluate("'\\u20AC'")
        @runtime[:s] = s
        assert_equal('', @runtime.evaluate("s.substr(1)"))
        assert_equal(1, @runtime.evaluate("s.length"))
        assert_js("'\\u20ac' == s")
      end
    end
  end
end
