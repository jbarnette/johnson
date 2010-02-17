require "helper"

class SemiTest < Johnson::NodeTestCase
  def test_null_semi
    assert_sexp([], @parser.parse(';'))
    assert_ecma('', @parser.parse(';'))
  end
end
