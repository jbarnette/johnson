require "helper"

class TypeofNodeTest < Johnson::NodeTestCase
  def test_typeof_sexp
    assert_sexp(
      [[:typeof, [:name, 'foo']]],
      @parser.parse('typeof foo;')
    )
    assert_ecma('typeof foo;', @parser.parse('typeof foo;'))
  end
end
