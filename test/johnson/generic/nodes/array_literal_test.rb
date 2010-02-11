require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ArrayLiteralNodeTest < Johnson::NodeTestCase
  def test_array_literal
    assert_sexp(
                [[:var, [[:assign, [:name, "foo"], [:array, [[:lit, 1]]]]]]],
                @parser.parse('var foo = [1];')
               )
    assert_ecma(
                'var foo = [1];',
                @parser.parse('var foo = [1];')
               )
  end

  def test_paren
    assert_ecma("(a && b);", "a && b;", @parser.parse("(a && b)"))
  end

  def test_array_with_commas
    assert_sexp(
                [[:var, [[:assign, [:name, "foo"], [:array, [
                  [:nil],
                  [:nil],
                  [:lit, 1]
                ]]]]]],
                @parser.parse('var foo = [,,1];')
               )
    assert_ecma(
                'var foo = [null, null, 1];',
                @parser.parse('var foo = [,,1];')
               )
    assert_sexp(
                [[:var, [[:assign, [:name, "foo"], [:array, [
                  [:str, 'foo'],
                  [:nil],
                  [:lit, 1]
                ]]]]]],
                @parser.parse('var foo = ["foo",,1];')
               )
    assert_ecma(
                'var foo = ["foo", null, 1];',
                @parser.parse('var foo = ["foo",,1];')
               )
    assert_sexp(
                [[:var, [[:assign, [:name, "foo"], [:array, [
                  [:name, 'bar'],
                  [:nil],
                  [:lit, 1]
                ]]]]]],
                @parser.parse('var foo = [bar,,1];')
               )
    assert_ecma(
                'var foo = [bar, null, 1];',
                @parser.parse('var foo = [bar,,1];')
               )
  end
end
