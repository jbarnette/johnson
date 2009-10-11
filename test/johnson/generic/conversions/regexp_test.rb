require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class RegexpTest < Johnson::TestCase
      def test_regex_converts
        @runtime[:x] = /aaron/
        @runtime[:y] = /john/i
        assert @runtime.evaluate('"aaron".match(x)')
        assert !@runtime.evaluate('"Aaron".match(x)')
        assert @runtime.evaluate('"john".match(y)')
        assert @runtime.evaluate('"John".match(y)')
      end

      def test_regex_roundtrips
        @runtime[:x] = /aaron/
        assert_equal(/aaron/, @runtime.evaluate('x'))

        @runtime[:x] = /aaron/m
        assert_equal(/aaron/m, @runtime.evaluate('x'))
      end
    end
  end
end
