require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ForTest < Johnson::NodeTestCase
  def test_empty_for
    assert_sexp([[:for, nil, nil, nil, [:var, [[:assign, [:name, "x"], [:lit, 10]]]]]],
                @parser.parse('for( ; ; ) var x = 10;'))
    assert_ecma('for( ; ; ) var x = 10;',
                @parser.parse('for( ; ; ) var x = 10;'))
  end

  def test_in_no_bf
    assert_sexp([[:in, [:lit, 0], [:name, "foo"]]],
      @parser.parse('0 in foo')
               )
    assert_ecma('0 in foo;', @parser.parse('0 in foo'))
  end

  def test_for_in_loop
    assert_sexp(
      [
        [:for_in,
          [:in, [:var, [[:name, "foo"]]], [:name, "bar"]],
          [
            [:var, [[:assign, [:name, "x"], [:lit, 10]]]]
          ]
      ]],
      @parser.parse('for(var foo in bar) { var x = 10; }')
               )
    assert_ecma("for(var foo in bar) {\n  var x = 10;\n}",
      @parser.parse('for(var foo in bar) { var x = 10; }'))
  end

  def test_for_loop
    assert_sexp([
      [:for,
        [:op_equal, [:name, "foo"], [:lit, 10]],
        [:lt, [:name, "foo"], [:lit, 10]],
        [:postfix_inc, [:name, "foo"]],
        [
          [:var, [[:assign, [:name, "x"], [:lit, 10]]]],
          [:var, [[:assign, [:name, "y"], [:lit, 11]]]]
        ]
      ]],
      @parser.parse('for(foo = 10; foo < 10; foo++) { 
                    var x = 10;
                    var y = 11; }')
               )
    assert_ecma("for(foo = 10; foo < 10; foo++) {\n  var x = 10;\n  var y = 11;\n}",
      @parser.parse('for(foo = 10; foo < 10; foo++) { 
                    var x = 10;
                    var y = 11; }')
    )
  end
end
