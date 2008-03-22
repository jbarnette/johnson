require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class ForTest < Johnson::NodeTestCase
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
  end
end
