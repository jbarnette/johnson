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

    def assert_sexp(expected, actual)
      assert_equal(expected, actual.to_sexp)
    end

    def assert_ecma(expected, actual)
      assert_equal(expected, actual.to_ecma)
    end
  end
end
