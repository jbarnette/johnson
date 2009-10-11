require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Johnson
  class PreludeTest < Johnson::TestCase
    def test_symbols_are_interned
      assert(@runtime.evaluate("Johnson.symbolize('foo') === Johnson.symbolize('foo')"))
    end
    
    def test_strings_had_a_to_symbol_method
      assert_js_equal(:monkeys, "'monkeys'.toSymbol()")
    end
    
    def test_string_to_symbol_is_not_enumerable
      assert(!@runtime.evaluate(<<-END))
        var flag = false;
        for (x in "foo") { if (x == 'toSymbol') flag = true }
        flag
      END
    end
    
    def test_symbol_to_string
      assert_equal("monkey", @runtime.evaluate("Johnson.symbolize('monkey').toString()"))
    end

    def test_symbol_inspect
      assert_equal(":monkey", @runtime.evaluate("Johnson.symbolize('monkey').inspect()"))
    end
    
    def test_all_of_ruby_is_available
      assert_raise(Johnson::Error) { @runtime.evaluate("Ruby.Set.new()") }
      
      @runtime.evaluate("Ruby.require('set')")
      assert_kind_of(Set, @runtime.evaluate("Ruby.Set.new()"))
    end
    
    # def test_require_an_existing_js_file_without_extension
    #   assert_js("Johnson.require('johnson/template')")
    # end
    
    # def test_require_returns_false_the_second_time_around
    #   assert_js("Johnson.require('johnson/template')")
    #   assert(!@runtime.evaluate("Johnson.require('johnson/template')"))
    # end
    
    def test_missing_requires_throw_LoadError
      assert_js(<<-END)
        var flag = false;
        
        try { Johnson.require("johnson/__nonexistent"); }
        catch(ex) { flag = true; }
        
        flag;
      END
    end

    def test_apply_without_second_param_works
      assert_js(<<-END)
        var func = function() { return arguments.length; };
        func.apply(null, null) == 0 && func.apply(null) == 0;
      END
    end

    def test_apply_with_non_array_throws
      assert_raise(Johnson::Error) {
        @runtime.evaluate(<<-END)
          var func = function() { return arguments.length; };
          func.apply(null, "foo");
        END
      }

      assert_raise(Johnson::Error) {
        @runtime.evaluate(<<-END)
          var func = function() { return arguments.length; };
          func.apply(null, { foo: 'bar' });
        END
      }
    end
  end
end
