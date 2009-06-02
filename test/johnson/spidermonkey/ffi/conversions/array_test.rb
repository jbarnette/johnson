require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../helper"))

module Johnson
  module Conversions
    class ArrayTest < Johnson::TestCase
      def test_array_index_get
        @runtime[:list] = [1, 2, 3, 4]
        assert_equal(1, @runtime.evaluate("list[0]"))
      end

      def test_array_index_set
        @runtime[:list] = []
        @runtime.evaluate("list[0] = 42")
        assert_equal(42, @runtime[:list][0])
      end

      def test_array_works_with_for_in
        list = [1, 2, 3, 4]

        @runtime['alert'] = lambda { |x| p x }
        @runtime['list'] = list
        @runtime.evaluate("
          var new_list = [];
          for(x in list) {
            new_list.push(x + 1);
          }
        ")
        assert_equal(list.map { |x| x + 1}, @runtime['new_list'].to_a)
      end
    end
  end
end
