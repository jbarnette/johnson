require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class IfTest < Johnson::NodeTestCase
  def test_if_no_else
    assert_sexp([
      [:if, [:and, [:name, "x"], [:name, "y"]],
        [:var, [[:assign, [:name, "foo"], [:lit, 20]]]],
        nil
      ]], @parser.parse('if(x && y) var foo = 20;')
    )
    assert_ecma('if(x && y) var foo = 20;',
      @parser.parse('if(x && y) var foo = 20;')
    )
  end

  def test_if_else
    assert_sexp(
      [[:if, [:and, [:lit, 5], [:lit, 10]],
        [:var, [[:assign, [:name, "foo"], [:lit, 20]]]],
        [:var, [[:assign, [:name, "bar"], [:lit, 5]]]]
      ]],
      [[:if, [:true],
        [:var, [[:assign, [:name, "foo"], [:lit, 20]]]],
        [:var, [[:assign, [:name, "bar"], [:lit, 5]]]]
      ]],
      @parser.parse('if(5 && 10) var foo = 20; else var bar = 5;')
    )
    assert_ecma('if(x && y) var foo = 20; else var bar = 5;',
      @parser.parse('if(x && y) var foo = 20; else var bar = 5;')
    )
  end

  def test_if_else_block
    assert_sexp(
      [[:if, [:and, [:lit, 5], [:lit, 10]],
        [[:var, [[:assign, [:name, "foo"], [:lit, 20]]]]],
        [:var, [[:assign, [:name, "bar"], [:lit, 5]]]]
      ]],
      [[:if, [:true],
        [[:var, [[:assign, [:name, "foo"], [:lit, 20]]]]],
        [:var, [[:assign, [:name, "bar"], [:lit, 5]]]]
      ]],
      @parser.parse('if(5 && 10){ var foo = 20; } else var bar = 5;')
    )
    assert_ecma(
     "if(5 && 10) {\n  var foo = 20;\n} else var bar = 5;",
     "if(true) {\n  var foo = 20;\n} else var bar = 5;",
      @parser.parse('if(5 && 10){ var foo = 20; } else var bar = 5;')
    )
  end
end
