require File.expand_path(File.join(File.dirname(__FILE__), "helper"))
require 'tempfile'

module Johnson
  class RuntimeTest < Johnson::TestCase
    def test_evaluate_returns_nil_for_nil_expression
      assert_nil(@runtime.evaluate(nil))
    end

    def test_global_treats_symbols_as_strings
      @runtime[:foo] = 17
      @runtime['bar'] = 4
      assert_equal 17, @runtime['foo']
      assert_equal 4, @runtime[:bar]
      assert_js_equal 21, 'foo + bar'
    end

    def test_disallows_invalid_key_types
      assert_raises(TypeError) {
        @runtime[4.1] = 3
      }
      assert_raises(TypeError) {
        @runtime[%w(hello world)]
      }
    end

    def test_js_eval
      assert_equal(1, @runtime.evaluate('eval("1");'))
    end

    def test_shebang_removal
      t = Tempfile.new("johnson_shebang")
      t.open { |tf| tf.write "#!/usr/bin/johnson\ntrue;" }
      assert Johnson.load(t.path)
    end

    def test_js_throws_compile_errors
      assert_raises(Johnson::Error) {
        @runtime.evaluate("var js_lambda = function(x) { return x ** 2; }")
      }
      assert_raises(Johnson::Error) {
        @runtime.compile("var js_lambda = function(x) { return x ** 2; }")
      }
    end

    def test_breakpoint_gets_called
      break_times = 0
      @runtime['some_number'] = 0
      script = @runtime.compile("some_number++;
                            var x = 0;
                            for(var i = 0; i < 10; i++) {
                              x++;
                            }
                            some_number++;
                        ")
      script.break(4) do
        break_times += 1
        assert_equal(@runtime['i'], @runtime['x'])
        assert_equal(1, @runtime['some_number'])
      end
      @runtime.evaluate_compiled_script(script)
      assert_equal(10, break_times)
      assert_equal(2, @runtime['some_number'])
    end

    def test_breakpoint_can_raise
      break_times = 0
      @runtime['some_number'] = 0
      @runtime['alert'] = lambda {|x,y| p [x, y] }
      script = @runtime.compile("some_number++;
                            var x = 0;
                            try {
                              for(var i = 0; i < 10; i++) {
                                x++;
                              }
                            } catch(ex) {
                              note_error(ex);
                            }
                            some_number++;
                        ")
      script.break(5) do
        break_times += 1
        assert_equal(@runtime['i'], @runtime['x'])
        assert_equal(1, @runtime['some_number'])
        raise ArgumentError, "Test" if @runtime['i'] > 4
      end
      break_ex = nil
      @runtime['note_error'] = lambda {|ex| break_ex = ex }
      @runtime.evaluate_compiled_script(script)
      assert_kind_of(ArgumentError, break_ex)
      assert_equal('Test', break_ex.message)
      assert_equal(6, break_times)
      assert_equal(2, @runtime['some_number'])
    end

    def test_breakpoints_are_cleared
      break_times = 0
      @runtime['some_number'] = 0
      script = @runtime.compile("some_number++;
                            var x = 0;
                            for(var i = 0; i < 10; i++) {
                              x++;
                            }
                            some_number++;
                        ")
      script.break(4) do
        break_times += 1
        assert_equal(@runtime['i'], @runtime['x'])
        assert_equal(1, @runtime['some_number'] % 2)
      end
      3.times do
        @runtime.evaluate_compiled_script(script)
      end
      assert_equal(10, break_times)
      assert_equal(6, @runtime['some_number'])
    end

    def test_try_to_gc
      10.times {
        thread = Thread.new do
            rt = Johnson::Runtime.new
            rt.evaluate('new Date()').to_s
        end
        thread.join
        GC.start
      }
    end

    def test_evaluated_compiled_script_checks_argument_type
      assert_raises(ArgumentError) {
        @runtime.evaluate_compiled_script(nil)
      }
      assert_raises(ArgumentError) {
        @runtime.evaluate_compiled_script(17)
      }
      assert_raises(ArgumentError) {
        @runtime.evaluate_compiled_script("3+9")
      }
    end
  end
end
