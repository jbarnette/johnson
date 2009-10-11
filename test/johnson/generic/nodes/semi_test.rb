require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class SemiTest < Johnson::NodeTestCase
  def test_null_semi
    assert_sexp([], @parser.parse(';'))
    assert_ecma('', @parser.parse(';'))
  end
end
