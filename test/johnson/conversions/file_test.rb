require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class FileTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end

      def test_read_file
        File.open(__FILE__, 'rb') { |f|
          @context[:foo] = f
          assert_equal(f, @context.evaluate("foo"))
          assert_equal(File.read(__FILE__), @context.evaluate("foo.read()"))
        }
      end
    end
  end
end
