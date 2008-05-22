require File.expand_path(File.join(File.dirname(__FILE__), "/../test/helper"))

require 'logger'
module Johnson
  module Conversions
    class ThreadTest < Johnson::TestCase
      def setup
        @context = Johnson::Context.new
        ## Uncomment this, and each test will pass individually.
        ## Change STDOUT to nil, and it fails.  Are our tests failing because
        ## of IO issues?
        #db = Johnson::SpiderMonkey::Debugger.new(Logger.new(STDOUT))
        #@context.delegate.debugger = db
      end

      def test_new_js_thread
        @context.evaluate('function testing() { Ruby.sleep(10); }')
        @context.evaluate('new Ruby.Thread(function() { testing(); })')
      end

      def test_js_thread_read_file
        @context['filename'] = File.expand_path(__FILE__)
        @context.evaluate('function testing() { Ruby.File.read(filename); }')
        @context.evaluate('new Ruby.Thread(function() { testing(); })')
      end
    end
  end
end
