require "rubygems"
require "test/unit"

%w(../lib ../ext/spidermonkey).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

# If the test isn't running from Rake, make sure the extension's current.
Rake rescue Dir.chdir(File.dirname(__FILE__) + "/..") { %x(rake extensions) }

require "johnson"

module Johnson
  class TestCase < Test::Unit::TestCase
    class TestLogger
      def debug(string)
        puts string
      end
    end

    undef :default_test
    
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
    include Johnson::Nodes
  
    undef :default_test
    
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
