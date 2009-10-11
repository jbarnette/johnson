require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ReturnTest < Johnson::NodeTestCase
  def test_return
    assert_sexp([[:func_expr, "foo", [], [[:return, nil]]]],
      @parser.parse('function foo() { return; }'))
    assert_ecma("function foo() {\n  return;\n}",
      @parser.parse('function foo() { return; }'))


    assert_sexp([[:func_expr, "foo", [], [[:return, [:lit, 10]]]]],
      @parser.parse('function foo() { return 10; }'))
    assert_ecma("function foo() {\n  return 10;\n}",
      @parser.parse('function foo() { return 10; }'))
  end
end
