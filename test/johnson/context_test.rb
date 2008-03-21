require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class ContextTest < Johnson::TestCase
    def setup
      @context = Johnson::Context.new
    end
    
    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Context, @context.delegate.class)
    end
    
    def test_delegates_public_ops
      delegate = mock(:evaluate => nil)
      delegate.expects(:[]).with("key").returns("value")
      delegate.expects(:[]=).with("key", "value").returns("value")
      
      ctx = Johnson::Context.new(delegate)
      
      assert_equal("value", ctx[:key])
      assert_equal("value", ctx[:key] = "value")
    end
    
    def test_evaluate_returns_nil_for_nil_expression
      assert_nil(@context.evaluate(nil))
    end
    
    def test_converts_keys_to_strings_for_get_and_set
      delegate = mock(:evaluate => nil)
      delegate.expects(:[]).with("key")
      delegate.expects(:[]=).with("key", "value")
      
      ctx = Johnson::Context.new(delegate)
      
      value = ctx[:key]
      ctx[:key] = "value"
    end
  end
end
