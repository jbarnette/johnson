require "rubygems"
require "hoe"
require "./lib/johnson.rb"

GENERATED_NODE = "ext/read_only_node.c"

Hoe.new("johnson", Johnson::VERSION) do |p|
  p.rubyforge_name = "johnson"
  p.author = "John Barnette"
  p.email = "jbarnette@rubyforge.org"
  p.summary = "Johnson wraps Spidermonky in a loving Ruby embrace."
  p.description = p.paragraphs_of("README.txt", 2..5).join("\n\n")
  p.url = p.paragraphs_of("README.txt", 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  
  p.clean_globs = [
    "ext/spidermonkey/Makefile",
    "ext/spidermonkey/*.{o,so,bundle,log}",
    "vendor/spidermonkey/**/*.OBJ",
    GENERATED_NODE]
    
  p.spec_extras = { :extensions => ["ext/spidermonkey/extconf.rb"] }
end
