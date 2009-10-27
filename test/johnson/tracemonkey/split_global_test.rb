require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

module Johnson
  module TraceMonkey
    class SplitGlobalTest < Johnson::TestCase
      def setup
        @runtime = Johnson::Runtime.new(Johnson::TraceMonkey::Runtime)
        @outer = @runtime.new_split_global_outer
        @inner = @runtime.new_split_global_inner @outer
      end
      
      def test_getter_case_works
        @runtime.evaluate <<EOJS, nil, nil, @inner, @inner
  this.__defineGetter__("foo",function(){return"fooy";});
  a = this.foo;
  b = foo;
EOJS
        assert(@runtime.evaluate("a", nil, nil, @inner, @inner) == "fooy")
        assert(@runtime.evaluate("b", nil, nil, @inner, @inner) == "fooy")
      end
      
      def test_nested_eval_case
        assert(@runtime.evaluate( <<EOJS, nil, nil, @inner, @inner ) == 10)
  (function(){
    return eval("10")
  })();
EOJS
      end
      
    end
  end
end
