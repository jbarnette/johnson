require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class BracketAccessTest < Johnson::NodeTestCase
  def test_to_sexp
    assert_sexp(
      [
        [:var,
          [[:assign, [:name, 'a'],
            [:bracket_access, [:name, "foo"], [:lit, 10]],
          ]]
        ]
      ],
      @parser.parse('var a = foo[10];'))
    assert_ecma("var a = foo[10];", @parser.parse('var a = foo[10];'))
  end
end
