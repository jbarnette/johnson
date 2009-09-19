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

# make sure all the Johnson JavaScript libs are in the load path
$LOAD_PATH.push(File.expand_path("#{File.dirname(__FILE__)}/../js"))

module Johnson
  PRELUDE = IO.read(File.dirname(__FILE__) + "/../js/johnson/prelude.js")
  VERSION = "1.1.2"

  def self.evaluate(expression, vars={})
    runtime = Johnson::Runtime.new
    vars.each { |key, value| runtime[key] = value }

    runtime.evaluate(expression)
  end

  def self.parse(js, *args)
    Johnson::Parser.parse(js, *args)
  end

  ###
  # Create a new runtime and load all +files+.  Returns a new Johnson::Runtime.
  def self.load(*files)
    rt = Johnson::Runtime.new
    rt.load(*files)
    rt
  end
end
