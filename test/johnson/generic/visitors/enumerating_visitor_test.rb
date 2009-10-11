require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class EnumeratingVisitorTest < Test::Unit::TestCase
  def test_for
    ast = Johnson.parse('for(var x = 0; x < 10; x++) { }')
    counter = 0
    ast.each do |node|
      counter += 1
    end
    assert_equal(12, counter)
  end
end
