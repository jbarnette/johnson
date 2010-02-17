require "helper"

class WithTest < Johnson::NodeTestCase
  def test_with
    assert_sexp([[:with, [:name, "o"], [:name, "x"]]],
                @parser.parse('with (o) x;')
               )
    assert_ecma("with(o) x;", @parser.parse('with (o) x;'))
  end
end
