require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

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
  
  def test_mark_an_object_for_conversion_by_value
    a = []
    Johnson.mark_for_conversion_by_value(a)
    
    assert_respond_to(a, :convert_to_js_by_value?)
    assert(a.convert_to_js_by_value?)
  end
end
