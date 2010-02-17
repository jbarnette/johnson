require "helper"

module Johnson
  module Conversions
    class FileTest < Johnson::TestCase
      def test_read_file
        File.open(__FILE__, 'rb') { |f|
          @runtime[:foo] = f
          assert_equal(f, @runtime.evaluate("foo"))
          assert_equal(File.read(__FILE__), @runtime.evaluate("foo.read()"))
        }
      end
    end
  end
end
