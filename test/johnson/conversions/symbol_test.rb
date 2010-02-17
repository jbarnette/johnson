require "helper"

module Johnson
  module Conversions
    class SymbolTest < Johnson::TestCase
      def test_symbols_are_interned
        @runtime[:v] = :symbol
        @runtime[:x] = :symbol

        assert(@runtime.evaluate("v !== null && v === x"))
      end

      def test_ruby_symbol_roundtrips
        @runtime[:v] = :foo
        assert_equal(:foo, @runtime.evaluate("v"))
      end
    end
  end
end
