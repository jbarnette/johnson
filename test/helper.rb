require "rubygems"
require "test/unit"
require "mocha"

%w(../lib ../ext/spidermonkey).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

# If the test isn't running from Rake, make sure the extension's current.
Rake rescue Dir.chdir(File.dirname(__FILE__) + "/..") { %x(rake extensions) }

require "johnson"

module Johnson
  class TestCase < Test::Unit::TestCase
    def default_test; end
    
    def assert_js(expression, options={})
      context = options[:context] || @context
      assert(context.evaluate(expression), "Expected JS expression [#{expression}] to be true.")
    end
    
    def assert_js_equal(expected, expression, options={})
      context = options[:context] || @context
      assert_equal(expected, context.evaluate(expression))
    end
  end
end
