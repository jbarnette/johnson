require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

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
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, []]
                  ]]
                ]],
                @parser.parse('var foo = { }'))
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:property, [:str, "bar"], [:lit, 10]]]]
                  ]]
                ]],
                @parser.parse('var foo = { "bar": 10 }'))
    assert_sexp(
                [[:var,
                  [[:assign,
                    [:name, "foo"],
                    [:object, [[:property, [:lit, 5], [:lit, 10]]]]
                  ]]
                ]],
                @parser.parse('var foo = { 5: 10 }'))
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
  end
end
