require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class DoWhileTest < Johnson::NodeTestCase
  def test_do_while
    assert_sexp([[:do_while, [:var, [[:assign, [:name, "x"], [:lit, 10]]]], [:true]]],
                @parser.parse('do var x = 10; while(true);'))
    assert_ecma('do var x = 10; while(true);',
                @parser.parse('do var x = 10; while(true);'))
    assert_ecma("do {\n  var x = 10;\n  y = 20;\n} while(true);",
                @parser.parse('do { var x = 10; y = 20; } while(true);'))
  end
end
