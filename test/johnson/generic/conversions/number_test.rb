require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class NumberTest < Johnson::TestCase
      def test_ruby_fixnum_in_js
        @runtime[:v] = 42
        
        assert_js("v == 42")
        assert_js_equal(42, "v")
        assert_equal(42, @runtime[:v])
      end
      
      def test_js_fixnum_in_ruby
        fix = @runtime.evaluate("42")
        assert_equal(42, fix)
        assert_kind_of(Fixnum, fix)
      end

      def test_ruby_float_in_js
        @runtime[:pi] = pi = 3.141592654
        assert_js_equal(pi, "pi")
        assert_in_delta(pi, @runtime.evaluate("pi"), 2 ** -20)
      end
      
      def test_ruby_bignum_in_js
        @runtime[:big] = big = 2 ** 200        
        
        assert_js_equal(big, "big")
        assert_kind_of(Float, @runtime.evaluate("big"))
      end
    end
  end
end
