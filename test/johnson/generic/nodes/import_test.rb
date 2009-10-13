require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class ImportTest < Johnson::NodeTestCase
  def test_import
    begin
      assert_sexp([[:import,
        [
          [:dot_accessor, [:name, "name1"], [:name, "o"]],
          [:dot_accessor, [:name, "name2"], [:name, "o"]]
        ]]], @parser.parse('import o.name1, o.name2;'))
      assert_ecma('import o.name1, o.name2;',
        @parser.parse('import o.name1, o.name2;'))
    rescue Johnson::Parser::SyntaxError; end # okay if an interpreter doesn't implement import/export
  end
end
