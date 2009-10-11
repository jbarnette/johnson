require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module TraceMonkey
    class RuntimeTest < Johnson::TestCase
      def setup
        @runtime = Johnson::TraceMonkey::Runtime.new
      end
      
      def test_can_create_more_than_one_without_barfing
        assert_nothing_raised {
          Johnson::TraceMonkey::Runtime.new
        }
      end

      def test_default_is_no_debugger
        assert_equal false, @runtime.debugger?
      end

      def test_only_accepts_real_debugger_instance
        assert_raises(TypeError) {
          @runtime.debugger = 17
        }
        assert_raises(TypeError) {
          @runtime.debugger = "Yes please!"
        }
        assert_raises(TypeError) {
          @runtime.debugger = Object.new
        }
        assert_raises(TypeError) {
          @runtime.debugger = @runtime
        }
      end

      def test_reports_a_debugger_is_registered
        @runtime.debugger = Johnson::TraceMonkey::Debugger.new(nil)
        assert @runtime.debugger?
      end
    end
  end
end
