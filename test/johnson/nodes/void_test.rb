require "helper"

class VoidNodeTest < Johnson::NodeTestCase
  def test_delete_sexp
    assert_sexp(
      [[:void, [:name, 'foo']]],
      @parser.parse('void foo;')
    )
    assert_ecma('void foo;', @parser.parse('void foo;'))
  end
end
