require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TernaryNodeTest < Johnson::NodeTestCase
  def test_ternary
    assert_sexp([
      [:var, [[:assign,
        [:name, "x"],
        [:ternary,
          [:lt, [:name, "y"], [:lit, 10]],
          [:lit, 20],
          [:lit, 30]
        ]
      ]]]],
                @parser.parse('var x = y < 10 ? 20 : 30')
               )
    assert_ecma('var x = y < 10 ? 20 : 30;',
                @parser.parse('var x = y < 10 ? 20 : 30')
               )
  end

  def test_weird_rounding
    ecma = @parser.parse('(value < 0.00001) ? 0 : value;').to_ecma
    assert_match(/\(?value < 1.0e-[0]*5\)? \? 0 : value;/, ecma)
  end
end
