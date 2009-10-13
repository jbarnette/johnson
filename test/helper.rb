require "rubygems"
require "test/unit"

require "johnson"

module Johnson
  module GCTearDown
    def teardown
      if ENV['JOHNSON_GC']
        STDOUT.putc '!'
        GC.start
      end
    end
  end

  class TestCase < Test::Unit::TestCase
    include GCTearDown

    class TestLogger
      def debug(string)
        puts string
      end
    end

    undef :default_test if method_defined? :default_test

    def setup
      @runtime = Johnson::Runtime.new
      raise "hell" if !@runtime
      #@runtime.delegate.gc_zeal = 2
      #@runtime.delegate.debugger = Johnson::SpiderMonkey::Debugger.new(TestLogger.new)
    end
    
    def assert_js(expression, options={})
      runtime = options[:runtime] || @runtime
      assert(runtime.evaluate(expression), "Expected JS expression [#{expression}] to be true.")
    end
    
    def assert_js_equal(expected, expression, options={})
      runtime = options.delete(:runtime) || @runtime
      options.each { |k, v| runtime[k.to_s] = v }
      assert_equal(expected, runtime.evaluate(expression))
    end
  end

  class NodeTestCase < Test::Unit::TestCase
    include GCTearDown
    include Johnson::Nodes
  
    undef :default_test if method_defined? :default_test
    
    def setup
      @parser = Johnson::Parser
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
end
