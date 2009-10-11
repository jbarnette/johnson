require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class LabelTest < Johnson::NodeTestCase
  def test_label_statement_to_sexp
    assert_sexp([[:label,
                  [:name, "foo"], [:var, [[:assign, [:name, "x"], [:lit, 10]]]]
                ]],
                @parser.parse('foo: var x = 10;')
               )
    assert_sexp([[:label,
                  [:name, "foo"], [:var, [[:assign, [:name, "x"], [:lit, 10]]]]
                ]],
                @parser.parse('foo: var x = 10')
               )
    assert_ecma('foo: var x = 10;',
                @parser.parse('foo: var x = 10;')
               )
  end
end
