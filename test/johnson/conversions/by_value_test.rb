require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class ByValueTest < Johnson::TestCase
      def test_array_conversion_by_value
        beatles = %w(john paul george ringo)
        Johnson.mark_for_conversion_by_value(beatles)
        
        @runtime[:beatles] = beatles
        munged = @runtime.evaluate("beatles")
        
        assert_not_same(beatles, munged)
        assert_equal(beatles.size, munged.size)
        assert_equal(beatles[0], munged[0])
      end
    end
  end
end
