require "johnson/version"

# the native SpiderMonkey extension
require "johnson/spidermonkey"

# visitable module and visitors
require "johnson/visitable"
require "johnson/visitors"

# parse tree nodes
require "johnson/nodes"

# the SpiderMonkey bits written in Ruby
require "johnson/spidermonkey/context"
require "johnson/spidermonkey/js_proxy"
require "johnson/spidermonkey/ruby_proxy"
require "johnson/spidermonkey/mutable_tree_visitor"
require "johnson/spidermonkey/immutable_node"

# the 'public' interface
require "johnson/context"
require "johnson/parser"

module Johnson
  PRELUDE = IO.read(File.dirname(__FILE__) + "/prelude.js")
end
