require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TryTest < Johnson::NodeTestCase
  def test_try_finally
    assert_sexp(
      [[:try,
        [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
        nil,
        [[:var, [[:op_equal, [:name, "x"], [:lit, 20]]]]]
      ]],
      [[:try,
        [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
        nil,
        [[:var, [[:assign, [:name, "x"], [:lit, 20]]]]]
      ]],
      @parser.parse('try { var x = 10; } finally { var x = 20; }'))
    assert_ecma(
      "try {\n  var x = 10;\n} finally {\n  var x = 20;\n}",
      @parser.parse('try { var x = 10; } finally { var x = 20; }'))
  end

  def test_try_catch
    assert_sexp(
    [[:try,
      [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
      [[:catch, [:name, "a"], nil,
      [
        [:var, [[:op_equal, [:name, "x"], [:lit, 20]]]],
        [:postfix_inc, [:name, "x"]]
      ]
      ]],
    nil]],
    [[:try,
      [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
      [[:catch, [:name, "a"], nil,
      [
        [:var, [[:assign, [:name, "x"], [:lit, 20]]]],
        [:postfix_inc, [:name, "x"]]
      ]
      ]],
    nil]],
    @parser.parse('try { var x = 10; } catch(a) { var x = 20; x++; }'))
    assert_ecma("try {\n  var x = 10;\n} catch(a) {\n  var x = 20;\n  x++;\n}",
      @parser.parse('try { var x = 10; } catch(a) { var x = 20; x++; }'))
  end

  def test_try_multi_catch
    assert_sexp(
      [[:try,
        [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
      [
        [:catch, [:name, "a"], [:true],
        [
          [:var, [[:op_equal, [:name, "x"], [:lit, 20]]]],
          [:postfix_inc, [:name, "x"]]
        ]],
        [:catch, [:name, "b"], [:true],
        [
          [:var, [[:op_equal, [:name, "x"], [:lit, 20]]]],
          [:postfix_inc, [:name, "x"]]
        ]]
      ],
      nil]],
      [[:try,
        [[:var, [[:assign, [:name, "x"], [:lit, 10]]]]],
      [
        [:catch, [:name, "a"], [:true],
        [
          [:var, [[:assign, [:name, "x"], [:lit, 20]]]],
          [:postfix_inc, [:name, "x"]]
        ]],
        [:catch, [:name, "b"], [:true],
        [
          [:var, [[:assign, [:name, "x"], [:lit, 20]]]],
          [:postfix_inc, [:name, "x"]]
        ]]
      ],
      nil]],
      @parser.parse(' try { var x = 10; }
                      catch(a if true) { var x = 20; x++; }
                      catch(b if true) { var x = 20; x++; }
                    '))
    assert_ecma("try {\n  var x = 10;\n} catch(a) {\n  var x = 20;\n  x++;\n} catch(b) {\n  var x = 20;\n  x++;\n}",
      @parser.parse(' try { var x = 10; }
                      catch(a if true) { var x = 20; x++; }
                      catch(b if true) { var x = 20; x++; }
                    '))
  end
end
