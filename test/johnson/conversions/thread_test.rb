require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module Conversions
    class ThreadTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
      end

      def test_manipulate_thread
        thread = Thread.new { }
        @context['thread'] = thread
        assert_js_equal(false, "thread.send('alive?')")
      end
    end
  end
end
