require File.expand_path(File.join(File.dirname(__FILE__), "..", "helper"))

require 'stringio'
class ParserTest < Test::Unit::TestCase
  include Johnson::Nodes
  def setup
    @parser = Johnson::Parser
  end

  def test_parser_init
    assert @parser
    tree = @parser.parse(StringIO.new(""))
    assert_kind_of SourceElements, tree
    assert_equal 0, tree.line
    assert_equal 0, tree.column
    assert_sexp([], tree)
  end

  def test_exception_raised
    assert_raises(Johnson::Parser::SyntaxError) {
      @parser.parse('if(')
    }
  end

  def test_exception_has_info
    begin
      @parser.parse('if(')
    rescue Johnson::Parser::SyntaxError => ex
      assert_equal(1, ex.line_number)
      assert_equal('', ex.file_name)
      assert_equal('syntax error', ex.message)
    end
  end

  def test_exception_has_filename
    begin
      @parser.parse('if(', 'test.js')
    rescue Johnson::Parser::SyntaxError => ex
      assert_equal(1, ex.line_number)
      assert_equal('test.js', ex.file_name)
      assert_equal('syntax error', ex.message)
    end
  end

  def test_exception_has_linenum
    begin
      @parser.parse('if(', 'test.js', 10)
    rescue Johnson::Parser::SyntaxError => ex
      assert_equal(10, ex.line_number)
      assert_equal('test.js', ex.file_name)
      assert_equal('syntax error', ex.message)
    end
  end

  def test_variable_declaration_no_init
    assert_sexp(
      [[:var, [[:name, 'foo']]]],
      @parser.parse('var foo;')
    )
    assert_ecma('var foo;', @parser.parse('var foo;'))
  end

  def test_new_foo
    assert_sexp([[:var, [[:assign, [:name, "a"], [:new, [[:name, "foo"]]]]]]],
                      @parser.parse('var a = new foo;'))
    assert_sexp([[:new, [[:name, "foo"]]]],
                      @parser.parse('new foo;'))
  end

  def test_function_call
    assert_sexp([[:bracket_access,
                [:function_call, [[:name, "bar"]]],
                [:lit, 1]]],
                      @parser.parse('bar()[1];'))
    assert_ecma('bar()[1];', @parser.parse('bar()[1]'))
  end

  def test_postfix_inc
    assert_sexp([[:postfix_inc, [:name, "x"]]],
                  @parser.parse('x++;'))
    assert_ecma('x++;', @parser.parse('x++;'))
    assert_sexp([[:postfix_inc, [:dot_accessor, [:name, "x"], [:name, "foo"]]]],
                  @parser.parse('foo.x++;'))
    assert_ecma('foo.x++;', @parser.parse('foo.x++;'))
    assert_sexp([[:postfix_inc, [:bracket_access, [:name, "x"], [:lit, 1]]]],
                  @parser.parse('x[1]++;'))
    assert_ecma('x[1]++;', @parser.parse('x[1]++;'))
  end

  def test_prefix_inc
    assert_sexp([[:prefix_inc, [:name, "x"]]],
                  @parser.parse('++x;'))
    assert_ecma('++x;', @parser.parse('++x;'))
    assert_sexp([[:prefix_inc, [:dot_accessor, [:name, "x"], [:name, "foo"]]]],
                  @parser.parse('++foo.x;'))
    assert_ecma('++foo.x;', @parser.parse('++foo.x;'))
    assert_sexp([[:prefix_inc, [:bracket_access, [:name, "x"], [:lit, 1]]]],
                  @parser.parse('++x[1];'))
    assert_ecma('++x[1];', @parser.parse('++x[1];'))
  end

  def test_postfix_dec
    assert_sexp([[:postfix_dec, [:name, "x"]]],
                  @parser.parse('x--;'))
    assert_ecma('x--;', @parser.parse('x--;'))
    assert_sexp([[:postfix_dec, [:dot_accessor, [:name, "x"], [:name, "foo"]]]],
                  @parser.parse('foo.x--;'))
    assert_ecma('foo.x--;', @parser.parse('foo.x--;'))
    assert_sexp([[:postfix_dec, [:bracket_access, [:name, "x"], [:lit, 1]]]],
                  @parser.parse('x[1]--;'))
    assert_ecma('x[1]--;', @parser.parse('x[1]--;'))
  end

  def test_prefix_dec
    assert_sexp([[:prefix_dec, [:name, "x"]]],
                  @parser.parse('--x;'))
    assert_ecma('--x;', @parser.parse('--x;'))
    assert_sexp([[:prefix_dec, [:dot_accessor, [:name, "x"], [:name, "foo"]]]],
                  @parser.parse('--foo.x;'))
    assert_ecma('--foo.x;', @parser.parse('--foo.x;'))
    assert_sexp([[:prefix_dec, [:bracket_access, [:name, "x"], [:lit, 1]]]],
                  @parser.parse('--x[1];'))
    assert_ecma('--x[1];', @parser.parse('--x[1];'))
  end

  def test_expr_comma
    assert_sexp([[:comma,
                [[:op_equal, [:name, 'i'], [:lit, 10]],
                [:op_equal, [:name, 'j'], [:lit, 11]]]]],
                @parser.parse('i = 10, j = 11;')
               )
    assert_ecma('i = 10, j = 11;', @parser.parse('i = 10, j = 11'))
  end

  def test_primary_expr_paren
    assert_sexp(
      [[:var,
        [[:assign, [:name, "a"], [:paren, [:lit, 10]]]]
      ]],
      [[:var,
        [[:assign, [:name, "a"], [:lit, 10]]]
      ]],
      @parser.parse('var a = (10);'))
    assert_ecma('var a = (10);', 'var a = 10;', @parser.parse('var a = (10);'))
  end

  def test_parser_var_ints
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = 10, bar = 1;"))
    assert_kind_of SourceElements, tree
    assert_kind_of VarStatement, tree.value.first
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:lit, 10]],
          [:assign, [:name, "bar"], [:lit, 1]],
      ]]],
      tree
    )
    assert_ecma('var foo = 10, bar = 1;',
                @parser.parse('var foo = 10, bar = 1'))
  end

  def test_parser_var_string_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = 'hello world';"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:str, 'hello world']],
      ]]],
      tree
    )
    assert_ecma('var foo = "hello world";',
                @parser.parse('var foo = "hello world"'))
  end

  def test_accessor_as_square_brace
    assert_ecma("foo['hello-world'];",
                @parser.parse("foo['hello-world']"))
  end

  def test_paren_around_function
    assert_ecma("(function() {  }).foo();",
                @parser.parse('(function() { }).foo()'))
    assert_ecma("(function() {  })();",
                @parser.parse('(function() { })()'))
  end

  def test_parser_var_nil_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = null;"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:nil]],
      ]]],
      tree
    )
    assert_ecma('var foo = null;', @parser.parse('var foo = null'))
  end

  def test_parser_var_true_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = true;"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:true]],
      ]]],
      tree
    )
    assert_ecma('var foo = true;', @parser.parse('var foo = true'))
  end

  def test_parser_var_false_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = false;"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:false]],
      ]]],
      tree
    )
    assert_ecma('var foo = false;', @parser.parse('var foo = false'))
  end

  def test_parser_var_this_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = this;"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:this]],
      ]]],
      tree
    )
    assert_ecma('var foo = this;', @parser.parse('var foo = this'))
  end

  def test_parser_var_regex_lit
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = /abc/;"))
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:lit, "/abc/"]],
      ]]],
      tree
    )
    assert_ecma('var foo = /abc/;', @parser.parse('var foo = /abc/'))
  end

  def test_parser_var_float
    assert @parser
    tree = @parser.parse(StringIO.new("var foo = 10, bar = 1.1;"))
    assert_kind_of SourceElements, tree
    assert_kind_of VarStatement, tree.value.first
    assert_sexp(
      [[:var,
        [
          [:assign, [:name, "foo"], [:lit, 10]],
          [:assign, [:name, "bar"], [:lit, 1.1]],
      ]]],
      tree
    )
    assert_ecma('var foo = 10, bar = 1.1;',
                @parser.parse('var foo = 10, bar = 1.1'))
  end

  def assert_includes enumerable, element
    if !enumerable.include?( element )
      flunk element.to_s + " not in [" + enumerable.map { |e| e.to_s }.join(" ") + "]"
    end
  end

  def assert_sexp(*args)
    if args.length == 2
      assert_equal(args[0],args[1].to_sexp)
    else
      expected = args[0,args.length-1]
      actual = args.last
      assert_includes expected, actual.to_sexp
    end
  end

  def assert_ecma(*args)
    if args.length == 2
      assert_equal(args[0],args[1].to_ecma)
    else
      expected = args[0,args.length-1]
      actual = args.last
      assert_includes expected, actual.to_ecma
    end
  end

end
