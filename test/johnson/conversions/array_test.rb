require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class ArrayTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end
      
      def test_array_index_get
        @context[:list] = [1, 2, 3, 4]
        assert_equal(1, @context.evaluate("list[0]"))
      end

      def test_array_index_set
        @context[:list] = []
        @context.evaluate("list[0] = 42")
        assert_equal(42, @context[:list][0])
      end

      def test_array_works_with_for_in
        list = [1, 2, 3, 4]

        @context['alert'] = lambda { |x| p x }
        @context['list'] = list
        @context.evaluate("
          var new_list = [];
          for(x in list) {
            new_list.push(x + 1);
          }
        ")
        assert_equal(list.map { |x| x + 1}, @context['new_list'].to_a)
      end
    end
  end
end
