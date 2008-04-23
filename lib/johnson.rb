require "generator"
require "johnson/version"

# the command-line option parser
require "johnson/cli/options"

# the native SpiderMonkey extension
require "johnson/spidermonkey"

# visitable module and visitors
require "johnson/visitable"
require "johnson/visitors"

# parse tree nodes
require "johnson/nodes"

# the SpiderMonkey bits written in Ruby
require "johnson/spidermonkey/context"
require "johnson/spidermonkey/js_land_proxy"
require "johnson/spidermonkey/ruby_land_proxy"
require "johnson/spidermonkey/mutable_tree_visitor"
require "johnson/spidermonkey/immutable_node"

# the 'public' interface
require "johnson/context"
require "johnson/parser"

$LOAD_PATH.push(File.expand_path("#{File.dirname(__FILE__)}/../js"))
$LOAD_PATH.push(File.expand_path("#{File.dirname(__FILE__)}/../browser"))

module Johnson
  PRELUDE = IO.read(File.dirname(__FILE__) + "/../js/johnson/prelude.js")
  
  def self.evaluate(expression, vars={})
    context = Johnson::Context.new
    vars.each { |key, value| context[key] = value }
    
    context.evaluate(expression)
  end
  
  def self.parse(js, *args)
    Johnson::Parser.parse(js, *args)
  end
end
