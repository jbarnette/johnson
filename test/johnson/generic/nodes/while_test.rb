require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class WhileTest < Johnson::NodeTestCase
  def test_while
    assert_sexp([[:while, [:true], [:var, [[:assign, [:name, "x"], [:lit, 10]]]]]],
                @parser.parse('while(true) var x = 10;'))
    assert_ecma('while(true) var x = 10;',
      @parser.parse('while(true) var x = 10;'))
  end
  
  def test_break
    assert_sexp([[:while, [:true], [:break]]],
                @parser.parse('while(true) break;'))
    assert_ecma('while(true) break;',
      @parser.parse('while(true) break;'))
  end

  def test_continue
    assert_sexp([[:while, [:true], [:continue]]],
                @parser.parse('while(true) continue;'))
    assert_ecma('while(true) continue;',
      @parser.parse('while(true) continue;'))
    assert_ecma("while(true) {\n  continue;\n}",
      @parser.parse('while(true) { continue; }'))
  end
end
