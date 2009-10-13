require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class VersionTest < Johnson::TestCase
    def test_has_a_version
      assert_not_nil(Johnson.version)
    end
  
    def test_has_a_runtime_version
      assert_not_nil(Johnson::Runtime.new.version)
    end
  end
end
