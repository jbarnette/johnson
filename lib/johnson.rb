require "johnson/version"

# Visitable module and visitors
require 'johnson/visitable'
require 'johnson/visitors'

# Parse tree nodes
require "johnson/nodes"

# the native SpiderMonkey extension
require "johnson/spidermonkey"

# the SpiderMonkey bits written in Ruby
require "johnson/spidermonkey/context"
require "johnson/spidermonkey/proxy"
require "johnson/spidermonkey/mutable_tree_visitor"
require "johnson/spidermonkey/immutable_node"

require "johnson/context"
require "johnson/parser"
