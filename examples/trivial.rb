$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "../lib")))
require 'johnson'

include Johnson

@rt = Runtime.new

retval = @rt.evaluate("1 + 1")
puts "Result of evaluation is #{retval}"

## Proxies get reused

foo = @rt.evaluate('foo = { bar: 10 }')
@rt['same_foo'] = foo

puts @rt.evaluate('foo == same_foo')

## Inject ruby objects in js land

@rt[:foo] = 'Hola'
puts @rt.evaluate('foo')

## Use multiple runtimes

@rt_2 = Runtime.new
@rt_2[:foo] = 'Ola'

puts @rt_2.evaluate('foo')
