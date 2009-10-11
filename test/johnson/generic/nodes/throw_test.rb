require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ThrowTest < Johnson::NodeTestCase
  def test_to_sexp
    assert_sexp([[:throw, [:lit, 10]]], @parser.parse('throw 10;'))
    assert_sexp([[:throw, [:lit, 10]]], @parser.parse('throw 10'))
    assert_ecma("throw 10;", @parser.parse('throw 10;'))
  end
end
