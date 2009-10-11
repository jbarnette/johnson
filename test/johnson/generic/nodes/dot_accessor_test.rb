require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class DotAccessorTest < Johnson::NodeTestCase
  def test_expression_statement
    assert_sexp(
                [[:dot_accessor, [:name, "bar"], [:name, "foo"]]],
                @parser.parse('foo.bar;')
               )
    assert_sexp(
                [[:dot_accessor, [:name, "bar"], [:name, "foo"]]],
                @parser.parse('foo.bar')
               )
    assert_ecma('foo.bar;', @parser.parse('foo.bar;'))
  end
end
