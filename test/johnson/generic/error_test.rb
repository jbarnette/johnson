require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class ErrorTest < Johnson::TestCase
    def test_inherits_from_standard_error
      assert(Johnson::Error < StandardError)
    end
  end
end
