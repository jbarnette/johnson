require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class RuntimeTest < Johnson::TestCase
    def test_default_delegate_is_spidermonkey
      if Johnson.runtimes.length == 0
        rt = @runtime.delegate
        assert_equal(Johnson::SpiderMonkey::Runtime, rt.class)
      end
    end
  end
end
