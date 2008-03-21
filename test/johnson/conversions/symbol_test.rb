require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class SymbolTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end

      def test_symbols_are_interned
        @context[:v] = :symbol
        @context[:x] = :symbol

        assert(@context.evaluate("v !== null && v === x"))
      end

      def test_ruby_symbol_roundtrips
        @context[:v] = :foo
        assert_equal(:foo, @context.evaluate("v"))
      end
    end
  end
end
