require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  module Conversions
    class ThreadTest < Johnson::TestCase
      def test_manipulate_thread
        thread = Thread.new { }
        @runtime['thread'] = thread
        assert_js_equal(false, "thread.send('alive?')")
      end

      def test_new_js_thread
        @runtime.evaluate('function testing() { Ruby.sleep(10); }')
        @runtime.evaluate('new Ruby.Thread(function() { testing(); })')
      end

      def test_js_thread_read_file
        @runtime['filename'] = File.expand_path(__FILE__)
        @runtime.evaluate('function testing() { Ruby.File.read(filename); }')
        @runtime.evaluate('new Ruby.Thread(function() { testing(); })')
      end
    end
  end
end
