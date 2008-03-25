require File.expand_path(File.join(File.dirname(__FILE__), "/../../helper"))

class SwitchTest < Johnson::NodeTestCase
  def test_empty_switch
    assert_sexp([[:switch, [:name, "o"], []]],
                @parser.parse('switch(o) { }')
               )
  end

  def test_switch_with_body
    assert_sexp([[:switch, [:name, "o"],
                [
                  [:case, [:name, "j"], [[:name, "foo"]]]
                ]
      ]], @parser.parse('switch(o) { case j: foo; }')
    )
  end

  def test_switch_with_body_2_case
    assert_sexp([[:switch, [:name, "o"],
                [
                  [:case, [:name, "j"], [[:name, "foo"]]],
                  [:case, [:name, "k"], [[:name, "bar"]]]
                ]
      ]], @parser.parse('switch(o) { case j: foo; case k: bar; }')
    )
  end

  def test_switch_with_default
    assert_sexp([[:switch, [:name, "o"], [[:default, nil, [[:name, "bar"]]]]]],
                @parser.parse('switch(o) { default: bar; }')
    )
    assert_sexp([[:switch, [:name, "o"], [[:default, nil, []]]]],
                @parser.parse('switch(o) { default: }')
    )
  end
end
