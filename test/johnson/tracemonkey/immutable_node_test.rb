require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

require 'stringio'

module Johnson
  module TraceMonkey
    class ImmutableNodeTest < Johnson::TestCase
      include Johnson::TraceMonkey

      def test_initialize
        node = nil
        assert_nothing_raised {
          node = ImmutableNode.new
        }
      end

      def test_parse_some_shit
        assert_nothing_raised {
          node = ImmutableNode.parse_io(StringIO.new('var x = 10;'))
        }
      end

      def test_index
        node = ImmutableNode.parse_io(StringIO.new('var x = 10;'))
        assert_equal(0, node.index)
      end

      def test_line
        node = ImmutableNode.parse_io(StringIO.new('var x = 10;'))
        assert_equal(0, node.line)
      end
    end
  end
end
