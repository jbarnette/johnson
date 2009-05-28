require File.expand_path(File.join(File.dirname(__FILE__), "/../../../helper"))

module Johnson
  module SpiderMonkey
    class RuntimeTest < Johnson::TestCase
      def setup
        @runtime = Johnson::SpiderMonkey::Runtime.new
      end
      
      def test_can_create_more_than_one_without_barfing
        assert_nothing_raised {
          Johnson::SpiderMonkey::Runtime.new
        }
      end

      def test_global_is_a_ruby_proxy
        assert(RubyLandProxy === @runtime.global)
      end

    end
  end
end
