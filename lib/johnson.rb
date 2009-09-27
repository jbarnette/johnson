require "generator"

# the native SpiderMonkey extension
require "johnson/spidermonkey"

# visitable module and visitors
require "johnson/visitable"
require "johnson/visitors"

# parse tree nodes
require "johnson/nodes"

# the SpiderMonkey bits written in Ruby
require "johnson/spidermonkey/runtime"
require "johnson/spidermonkey/context"
require "johnson/spidermonkey/js_land_proxy"
require "johnson/spidermonkey/ruby_land_proxy"
require "johnson/spidermonkey/mutable_tree_visitor"
require "johnson/spidermonkey/debugger"
require "johnson/spidermonkey/immutable_node"

# the 'public' interface
require "johnson/error"
require "johnson/runtime"
require "johnson/parser"

module Johnson
  VERSION = "1.1.2"

  ###
  # Evaluate the given JavaScript +expression+ in a new runtime, after
  # setting the given +vars+ into the global object.
  #
  # Returns the result of evaluating the given expression.
  def self.evaluate(expression, vars={})
    runtime = Johnson::Runtime.new
    vars.each { |key, value| runtime[key] = value }

    runtime.evaluate(expression)
  end

  def self.parse(js, *args)
    Johnson::Parser.parse(js, *args)
  end

  ###
  # Create a new runtime and load all +files+.
  #
  # Returns the new Johnson::Runtime.
  def self.load(*files)
    rt = Johnson::Runtime.new
    rt.load(*files)
    rt
  end
end
