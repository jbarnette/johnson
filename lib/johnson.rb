require "generator"
require "johnson/version"

# the command-line option parser and support libs
require "johnson/cli"

unless ENV['JOHNSON_FFI']
  # the native SpiderMonkey extension
  require "johnson/spidermonkey"

  # visitable module and visitors
  require "johnson/visitable"
  require "johnson/visitors"

  # parse tree nodes
  require "johnson/nodes"
end

# the SpiderMonkey bits written in Ruby

unless ENV['JOHNSON_FFI']
  require "johnson/spidermonkey/runtime"
  require "johnson/spidermonkey/context"
  require "johnson/spidermonkey/js_land_proxy"
  require "johnson/spidermonkey/ruby_land_proxy"
  require "johnson/spidermonkey/mutable_tree_visitor"
  require "johnson/spidermonkey/debugger"
  require "johnson/spidermonkey/immutable_node"
else
  require "johnson/spidermonkey/ffi/ffi-spidermonkey"
  require "johnson/spidermonkey/ffi/has_pointer.rb"
  require "johnson/spidermonkey/ffi/js_gc_thing.rb"
  require "johnson/spidermonkey/ffi/value.rb"
  require "johnson/spidermonkey/ffi/native_global.rb"
  require "johnson/spidermonkey/ffi/runtime"
  require "johnson/spidermonkey/ffi/context"
  require "johnson/spidermonkey/ffi/ruby_land_proxy"
end

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

  ###
  # Create a new runtime and load all +files+.  Returns a new Johnson::Runtime.
  def self.load(*files)
    rt = Johnson::Runtime.new
    rt.load(*files)
    rt
  end
end
