require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ObjectLiteralTest < Johnson::NodeTestCase
  def test_object_literal
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:property, [:name, "bar"], [:lit, 10]]]]
                  ]]
                ]],
                @parser.parse('var foo = { bar: 10 }'))
    assert_ecma('var foo = { bar: 10 };',
                @parser.parse('var foo = { bar: 10 }')
               )
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, []]
                  ]]
                ]],
                @parser.parse('var foo = { }'))
    assert_ecma('var foo = {  };',
                @parser.parse('var foo = { }')
               )
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:property, [:str, "bar"], [:lit, 10]]]]
                  ]]
                ]],
                @parser.parse('var foo = { "bar": 10 }'))
    assert_ecma('var foo = { "bar": 10 };',
                @parser.parse('var foo = { "bar": 10 }')
               )
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:property, [:lit, 5], [:lit, 10]]]]
                  ]]
                ]],
                @parser.parse('var foo = { 5: 10 }'))
    assert_ecma('var foo = { 5: 10 };',
                @parser.parse('var foo = { 5: 10 }')
               )
  end

  def test_object_literal_getter
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:getter, [:name, 'a'], [:func_expr, nil, [], []]]]]
                  ]]
                ]],
                @parser.parse('var foo = { get a() { } }'))
    assert_ecma("var foo = { get a() {  } };",
                @parser.parse('var foo = { get a() { } }')
               )
  end

  def test_object_literal_setter
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:setter, [:name, 'a'], [:func_expr, nil, ["bar"], []]]]]
                  ]]
                ]],
                @parser.parse('var foo = { set a(bar) { } }'))
    assert_ecma("var foo = { set a(bar) {  } };",
                @parser.parse('var foo = { set a(bar) { } }')
               )
  end
  
  def test_to_sexp_multi_property
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [
                      [:property, [:lit, 5], [:lit, 10]],
                      [:property, [:name, "a"], [:lit, 10]]
                    ]]
                  ]]
                ]],
                @parser.parse('var foo = { 5: 10, a: 10 }'))
    assert_ecma("var foo = { f: 10,\n  a: 10 };",
                @parser.parse('var foo = { f: 10, a: 10 }')
               )
  end

  def test_ol_with_string_keys
    assert_sexp([[:var,
      [[:assign,
        [:name, "foo"],
        [:object,
         [[:property, [:str, "\n"], [:lit, 10]],
          [:property, [:str, "\t"], [:lit, 10]]]]]]]],
                @parser.parse('var foo = { "\n": 10, "\t": 10 }')
               )
    assert_ecma("var foo = { \"\\n\": 10,\n  \"\\t\": 10 };",
      @parser.parse('var foo = { "\n": 10, "\t": 10 }'))

    assert_ecma('"\"";', @parser.parse('"\""'))
  end
end
