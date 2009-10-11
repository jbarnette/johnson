require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class LetNodeTest < Johnson::NodeTestCase
  def test_let_to_sexp
    assert_sexp(
              [[:lexical_scope, [:name, "unnamed"], [[:let, [[:assign, [:name, "a"], [:lit, 1],
]]]]]],
                @parser.parse('if(true) { let a = 1; }')
               )

  end

  def test_let_to_ecma
    assert_ecma(
      "{\n  let a = 1;\n};",
      @parser.parse('if(true) { let a = 1; }')
    )
  end

  def test_enumerating_visitor
    count = 0
    @parser.parse('if(true) { let a = 1; }').each do |node|
      count += 1
    end
    assert_equal 7, count
  end

  def test_dot_visitor
    @parser.parse('if(true) { let a = 1; }').to_dot
  end
end
