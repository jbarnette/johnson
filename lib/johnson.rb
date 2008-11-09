require "generator"
require "johnson/version"

# the command-line option parser and support libs
require "johnson/cli"

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
  
  def self.evaluate(expression, vars={})
    runtime = Johnson::Runtime.new
    vars.each { |key, value| runtime[key] = value }
    
    runtime.evaluate(expression)
  end
  
  def self.parse(js, *args)
    Johnson::Parser.parse(js, *args)
  end

  # Create a new runtime and load all +files+.  Returns a new Johnson::Runtime.

  def self.load(*files)
    rt = Johnson::Runtime.new
    rt.load(*files)
    rt
  end
  
  # Mark +obj+ for by-value conversion to JavaScript. When +obj+ crosses
  # over into JSLand, it'll be converted into a JS-native type. This
  # happens already for strings, numbers, and regular expressions.
  #
  # Only arrays are currently supported for explicit by-value conversion.
  # If you mark an array, it will be shallowly copied into a JavaScript
  # array any time it crosses over.
  
  def self.mark_for_conversion_by_value obj
    unless obj.respond_to? :convert_to_js_by_value?
      def obj.convert_to_js_by_value?; true; end
    end
  end
end
