require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class BinaryNodeTest < Johnson::NodeTestCase
  {
    :op_equal           => '=',
    :op_multiply_equal  => '*=',
    :op_divide_equal    => '/=',
    :op_plus_equal      => '+=',
    :op_lshift_equal    => '<<=',
    :op_rshift_equal    => '>>=',
    :op_urshift_equal   => '>>>=',
    :op_bitand_equal    => '&=',
    :op_bitxor_equal    => '^=',
    :op_bitor_equal     => '|=',
    :op_mod_equal       => '%=',
  }.each do |op,sym|
    define_method(:"test_#{op}_to_sexp") do
      assert_sexp(
                  [[op, [:name, 'i'], [:lit, 10]]],
                  @parser.parse("i #{sym} 10")
                 )
    end
  end
end
