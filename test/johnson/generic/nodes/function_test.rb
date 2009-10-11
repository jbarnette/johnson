require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class FunctionTest < Johnson::NodeTestCase
  def test_anon_function_no_args_to_sexp
    assert_sexp(
                [[:var,
                  [[:assign, [:name, 'foo'],
                    [:func_expr, nil, [], []]
                  ]]
                ]],
                @parser.parse("var foo = function() { }"))
    assert_ecma('var foo = function() {  };',
                @parser.parse("var foo = function() { }"))
  end

  def test_anon_function_one_args_to_sexp
    assert_sexp(
                [[:var,
                  [[:assign, [:name, 'foo'],
                    [:func_expr, nil, ["a"], []]
                  ]]
                ]],
                @parser.parse("var foo = function(a) { }"))
    assert_ecma('var foo = function(a) {  };',
                @parser.parse("var foo = function(a) { }"))
  end

  def test_anon_function_two_args_to_sexp
    assert_sexp(
                [[:var,
                  [[:assign, [:name, 'foo'],
                    [:func_expr, nil, ["a",'b'], []]
                  ]]
                ]],
                @parser.parse("var foo = function(a,b) { }"))
    assert_ecma('var foo = function(a, b) {  };',
                @parser.parse("var foo = function(a,b) { }"))
  end

  # 8 args is a threshold in spidermonkey
  def test_anon_function_nine_args_to_sexp
    assert_sexp(
                [[:var,
                  [[:assign, [:name, 'foo'],
                    [:func_expr, nil, ('a'..'i').to_a, []]
                  ]]
                ]],
      @parser.parse("var foo = function(#{('a'..'i').to_a.join(',')}) { }"))
    assert_ecma("var foo = function(#{('a'..'i').to_a.join(', ')}) {  };",
      @parser.parse("var foo = function(#{('a'..'i').to_a.join(',')}) { }"))
  end

  def test_named_function
    assert_sexp(
                [[:func_expr, 'a', ['b'], []]],
                @parser.parse("function a(b) { }")
               )
    assert_ecma("function a(b) {  }",
                @parser.parse("function a(b) { }"))
  end

  def test_named_function_with_body
    assert_sexp(
                [[:func_expr, 'a', ['b'],
                  [[:op_equal, [:name, 'b'], [:lit, 10]]]]],
                @parser.parse("function a(b) { b = 10; }")
               )
    assert_ecma("function a(b) {\n  b = 10;\n}",
                @parser.parse("function a(b) { b = 10 }"))
  end
end
