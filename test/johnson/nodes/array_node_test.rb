require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class ArrayNodeTest < Johnson::NodeTestCase
  def test_function_call
    assert_sexp([[:function_call, [[:name, "foo"], [:name, "a"]]]],
                @parser.parse('foo(a)'))
    assert_ecma("foo(a);", @parser.parse("foo(a);"))
    assert_ecma("foo(a, b);", @parser.parse("foo(a,b);"))
  end
end
