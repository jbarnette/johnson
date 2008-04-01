require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

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
end
