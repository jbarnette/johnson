require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class StructTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end

      def test_use_struct
        f = Struct.new(:phil_collins).new
        f.phil_collins = 'awesome'
        @context[:foo] = f
        assert_equal('awesome', @context.evaluate('foo.phil_collins'))
      end
    end
  end
end
