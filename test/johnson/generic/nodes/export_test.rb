require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ExportTest < Johnson::NodeTestCase
  def test_export
    begin
      assert_sexp([[:export, [[:name, "name1"], [:name, "name2"]]]],
                  @parser.parse('export name1, name2;'))
      assert_ecma('export name1, name2;', @parser.parse('export name1, name2;'))
    rescue Johnson::Parser::SyntaxError; end # okay if an interpreter doesn't implement import/export
  end
end
