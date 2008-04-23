require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class ContextTest < Johnson::TestCase
    def setup
      @context = Johnson::Context.new
    end

    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Context, @context.delegate.class)
    end

    def test_evaluate_returns_nil_for_nil_expression
      assert_nil(@context.evaluate(nil))
    end
  end
end
