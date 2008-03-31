require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class PlusTest < Johnson::NodeTestCase
  def test_plus
    assert_sexp([[:plus, [[:str, "a"], [:function_call, [[:name, "replace"]]], [:str, "b"]]]],
                @parser.parse('"a" + replace() + "b";')
    )
  end
end
