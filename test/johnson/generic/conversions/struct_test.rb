require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class StructTest < Johnson::TestCase
      def test_use_struct
        f = Struct.new(:phil_collins).new
        f.phil_collins = 'awesome'
        @runtime[:foo] = f
        assert_equal(f, @runtime.evaluate('foo'))
        assert_equal('awesome', @runtime.evaluate('foo.phil_collins'))
      end
    end
  end
end
