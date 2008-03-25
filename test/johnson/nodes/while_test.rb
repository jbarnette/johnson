require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class WhileTest < Johnson::NodeTestCase
  def test_while
    assert_sexp([[:while, [:true], [:var, [[:assign, [:name, "x"], [:lit, 10]]]]]],
                @parser.parse('while(true) var x = 10;'))
  end
end
