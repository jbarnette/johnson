require File.expand_path(File.join(File.dirname(__FILE__), "/../../../helper"))

module Johnson
  module SpiderMonkey
    class RuntimeTest < Johnson::TestCase
      def setup
        @runtime = Johnson::SpiderMonkey::Runtime.new
        @runtime.gc_zeal = 2
      end
      def teardown
        @runtime.destroy
      end      
      def test_can_create_more_than_one_without_barfing
        assert_nothing_raised {
          Johnson::SpiderMonkey::Runtime.new
        }
      end

      def test_global_is_a_ruby_proxy
        assert(RubyLandProxy === @runtime.global)
      end

      def test_hashes_are_private
        assert_raise(NoMethodError) { @runtime.jsids }
        assert_raise(NoMethodError) { @runtime.rbids }
        assert_raise(NoMethodError) { @runtime.roots }
      end
    end
  end
end
