require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class VersionTest < Johnson::TestCase
    def test_has_a_version
      assert_not_nil(Johnson::VERSION)
    end
  
    def test_has_a_spidermonkey_version
      assert_not_nil(Johnson::SpiderMonkey::VERSION)
    end
  end
end
