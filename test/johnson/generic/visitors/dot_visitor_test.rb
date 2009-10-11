require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class DotVisitorTest < Test::Unit::TestCase
  def test_var_foo
    dot = Johnson.parse('var foo;').to_dot
    assert_equal(3, dot.nodes.length)
    assert_equal(2, dot.links.length)
  end

  def test_for
    dot = Johnson.parse('for(var x = 0; x < 10; x++) { }').to_dot
    assert_equal(12, dot.nodes.length)
    assert_equal(11, dot.links.length)
  end

  def test_for_in
    dot = Johnson.parse('for(var x in johnson(1,2,"asdf")) { }').to_dot
    assert_equal(11, dot.nodes.length)
    assert_equal(10, dot.links.length)
  end

  def test_try
    dot = Johnson.parse('try { var x = 10; } finally { var x = 20; }').to_dot
    assert_equal(12, dot.nodes.length)
    assert_equal(11, dot.links.length)
  end

  def test_try_catch
    dot = Johnson.parse('try { var x = 10; } catch(a) { var x = 20; x++; }').to_dot
    assert_equal(16, dot.nodes.length)
    assert_equal(15, dot.links.length)
  end

  def test_function
    dot = Johnson.parse("var foo = function(a,b) { }").to_dot
    assert_equal(6, dot.nodes.length)
    assert_equal(5, dot.links.length)
  end
end
