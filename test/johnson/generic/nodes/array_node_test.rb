require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ArrayNodeTest < Johnson::NodeTestCase
  def test_function_call
    assert_sexp([[:function_call, [[:name, "foo"], [:name, "a"]]]],
                @parser.parse('foo(a)'))
    assert_ecma("foo(a);", @parser.parse("foo(a);"))
    assert_ecma("foo(a, b);", @parser.parse("foo(a,b);"))
  end

  def test_new
    assert_sexp([[:new, [[:name, "foo"], [:name, "a"]]]],
                @parser.parse('new foo(a)'))
    assert_ecma('new foo(a);', @parser.parse('new foo(a);'))
    assert_ecma('new foo(a, b);', @parser.parse('new foo(a,b);'))
  end

  def test_comma
    assert_sexp([[:comma,
      [[:op_add_equal, [:name, "result"], [:name, "source"]],
      [:op_equal, [:name, "source"], [:str, ""]]]]],
                @parser.parse('result += source, source = "";'))
    assert_ecma('result += source, source = "";',
                @parser.parse('result += source, source = "";'))
  end
end
