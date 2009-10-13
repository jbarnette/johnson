require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class RuntimeTest < Johnson::TestCase
    def test_default_delegate_is_spidermonkey
      assert_equal(Johnson::SpiderMonkey::Runtime, @runtime.delegate.class)
    end
  end
end
