require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

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

      def test_array_length
        @runtime[:list] = [1, 2, 3, 4]
        assert_equal(4, @runtime.evaluate("list.length"))
      end

      def test_array_works_with_for_in
        list = [9, 3, 12, 8]

        @runtime['alert'] = lambda { |x| p x }
        @runtime['list'] = list
        @runtime.evaluate("
          var new_list = [];
          for(var x in list) {
            new_list.push(x);
          }
        ")
        assert_equal([0, 1, 2, 3], @runtime['new_list'].to_a)
      end

      def test_array_works_with_iterator
        list = [9, 3, 12, 8]

        @runtime['alert'] = lambda { |x| p x }
        @runtime['list'] = list
        @runtime.evaluate("
          var new_list = [];
          var it = Iterator(list);
          for(var x in it) {
            new_list.push(x);
          }
        ")
        assert_equal([[0, 9], [1, 3], [2, 12], [3, 8]], @runtime['new_list'].to_a.map {|a| a.to_a })
      end

      def test_array_works_with_function_apply
        list = [1, 2, 3, 4]

        @runtime['alert'] = lambda { |x| p x }
        @runtime['list'] = list
        @runtime.evaluate("
          var new_list = [];
          function process_list(a, b, c, d) {
            new_list.push(a * 2);
            new_list.push(b * 2);
            // skip c
            new_list.push(d * 2);
          }
          process_list.apply(process_list, list);
        ")
        assert_equal([2, 4, 8], @runtime['new_list'].to_a)
      end
    end
  end
end
