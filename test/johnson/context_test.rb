require File.expand_path(File.join(File.dirname(__FILE__), "/../helper"))

require 'logger'
module Johnson
  class ContextTest < Johnson::TestCase
    def setup
      @context = Johnson::Context.new
      db = Johnson::SpiderMonkey::Debugger.new(Logger.new(STDOUT))
      @context.delegate.debugger = db
    end

    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Context, @context.delegate.class)
    end

    def test_evaluate_returns_nil_for_nil_expression
      assert_nil(@context.evaluate(nil))
    end

    def test_js_eval
      assert_equal(1, @context.evaluate('eval("1");'))
    end
  end
end
