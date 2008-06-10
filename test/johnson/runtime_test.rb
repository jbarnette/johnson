require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

module Johnson
  class RuntimeTest < Johnson::TestCase
    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Runtime, @runtime.delegate.class)
    end

    def test_evaluate_returns_nil_for_nil_expression
      assert_nil(@runtime.evaluate(nil))
    end

    def test_js_eval
      assert_equal(1, @runtime.evaluate('eval("1");'))
    end
  end
end
