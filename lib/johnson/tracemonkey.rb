require "johnson"

# the native TraceMonkey extension
require "johnson/tracemonkey/tracemonkey"

# the TraceMonkey bits written in Ruby
require "johnson/tracemonkey/runtime"
require "johnson/tracemonkey/context"
require "johnson/tracemonkey/js_land_proxy"
require "johnson/tracemonkey/ruby_land_proxy"
require "johnson/tracemonkey/mutable_tree_visitor"
require "johnson/tracemonkey/debugger"
require "johnson/tracemonkey/immutable_node"
