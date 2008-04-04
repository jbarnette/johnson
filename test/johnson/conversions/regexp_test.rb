require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class RegexpTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end

      def test_regex_converts
        @context[:x] = /aaron/
        @context[:y] = /john/i
        assert @context.evaluate('"aaron".match(x)')
        assert !@context.evaluate('"Aaron".match(x)')
        assert @context.evaluate('"john".match(y)')
        assert @context.evaluate('"John".match(y)')
      end

      # FIXME: Should we let this be a RubyProxy?  Or convert to Regexp
      #def test_regex_roundtrips
      #  @context[:x] = /aaron/
      #  assert_equal /aaron/, @context.evaluate('x')
      #end
    end
  end
end
