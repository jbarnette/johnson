require "stackdeck"
require 'date'
require "generator"

# the 'public' interface
require "johnson/error"
require "johnson/runtime"
require "johnson/ruby_land_proxy"
require "johnson/parser"

# visitable module and visitors
require "johnson/visitable"
require "johnson/visitors"

# parse tree nodes
require "johnson/nodes"

module Johnson
  VERSION = "2.0.0.pre3"

  def self.version
    VERSION
  end

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
  
  def self.runtimes
    Runtime.runtimes
  end

end
