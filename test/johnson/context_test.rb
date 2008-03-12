require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class ContextTest < Test::Unit::TestCase
    def setup
      @context = Johnson::Context.new
    end
    
    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Context, @context.delegate.class)
    end
    
    def test_delegates_public_ops
      delegate = mock()
      delegate.expects(:evaluate).with("expression").returns("result")
      delegate.expects(:[]).with(:key).returns("value")
      delegate.expects(:[]=).with(:key, "value").returns("value")
      
      context = Johnson::Context.new(delegate)
      
      assert_equal("result", context.evaluate("expression"))
      assert_equal("value", context[:key])
      assert_equal("value", context[:key] = "value")
    end
  end
end
