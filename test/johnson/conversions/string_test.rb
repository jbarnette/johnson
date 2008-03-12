require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class StringTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end
      
      def test_ruby_string_in_js
        @context[:v] = "foo"
        assert_js("'foo' == v")
      end

      def test_js_string_in_ruby
        assert_equal("foo", @context.evaluate("'foo'"))
      end

      def test_roundtrip
        @context[:v] = v = "hola"
        assert_equal(v, @context.evaluate("v"))
      end
      
      def test_strings_are_copies
        @context[:v] = v = "hola"
        assert_not_same(v, @context.evaluate("v"))
      end
    end
  end
end
