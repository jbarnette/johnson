require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class UnaryNodeTest < Johnson::NodeTestCase
  def test_u_positive_sexp
    assert_sexp([[:u_pos, [:name, 'foo']]], @parser.parse('+foo;'))
    assert_ecma('+foo;', @parser.parse('+foo'))
  end

  def test_u_negative_sexp
    assert_sexp([[:u_neg, [:name, 'foo']]], @parser.parse('-foo;'))
    assert_ecma('-foo;', @parser.parse('-foo'))
  end

  def test_u_bit_not_sexp
    assert_sexp([[:bitwise_not, [:name, 'foo']]], @parser.parse('~foo;'))
    assert_ecma('~foo;', @parser.parse('~foo'))
  end

  def test_u_not_sexp
    assert_sexp([[:not, [:name, 'foo']]], @parser.parse('!foo;'))
    assert_ecma('!foo;', @parser.parse('!foo'))
  end
end
