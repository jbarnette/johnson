require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

class JohnsonTest < Test::Unit::TestCase
  def test_shortcut_evaluate
    assert_equal(4, Johnson.evaluate("2 + 2"))
  end
  
  def test_can_provide_context_vars_to_evaluate
    assert_equal(4, Johnson.evaluate("2 + foo", :foo => 2))
  end
  
  def test_evaluate_uses_a_new_runtime_each_time
    assert_equal(4, Johnson.evaluate("foo", :foo => 4))
    assert_raise(Johnson::Error) { Johnson.evaluate("foo") }
  end
end
