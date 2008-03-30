require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module SpiderMonkey
    class JSProxyTest < Johnson::TestCase
      def setup
        @context = Johnson::SpiderMonkey::Context.new
      end      
    end
  end
end
