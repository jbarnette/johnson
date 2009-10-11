require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class DeleteNodeTest < Johnson::NodeTestCase
  def test_delete_sexp
    assert_sexp(
      [[:delete, [:name, 'foo']]],
      @parser.parse('delete foo;')
    )
    assert_ecma('delete foo;', @parser.parse('delete foo;'))
  end
end
