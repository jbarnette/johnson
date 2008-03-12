require "rubygems"
require "hoe"
require "./lib/johnson/version.rb"

# what sort of extension are we building?
kind = Config::CONFIG["DLEXT"]

Hoe.new("johnson", Johnson::VERSION) do |p|
  p.rubyforge_name = "johnson"
  p.author = "John Barnette"
  p.email = "jbarnette@rubyforge.org"
  p.summary = "Johnson wraps JavaScript in a loving Ruby embrace."
  p.description = p.paragraphs_of("README.txt", 2..5).join("\n\n")
  p.url = p.paragraphs_of("README.txt", 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  
  p.clean_globs = [
    "lib/johnson/spidermonkey.#{kind}",
    "ext/spidermonkey/Makefile",
    "ext/spidermonkey/*.{o,so,bundle,log}",
    "vendor/spidermonkey/**/*.OBJ"]
    
  p.test_globs = ["test/**/*_test.rb"]
    
  p.spec_extras = { :extensions => ["ext/spidermonkey/extconf.rb"] }
end

# make sure the C bits are up-to-date when testing
Rake::Task[:test].prerequisites << :extensions

desc "Our johnson requires extensions."
task :extensions => "lib/johnson/spidermonkey.#{kind}"

# for testing, we toss the SpiderMonkey extension in lib/johnson
file "lib/johnson/spidermonkey.#{kind}" =>
  FileList["ext/spidermonkey/Makefile", "ext/spidermonkey/*.{c,h}"] do
  
  Dir.chdir("ext/spidermonkey") { sh "make" }
  sh "cp ext/spidermonkey/spidermonkey.#{kind} lib/johnson/spidermonkey.#{kind}"
end

file "ext/spidermonkey/Makefile" => "ext/spidermonkey/extconf.rb" do
  Dir.chdir("ext/spidermonkey") { ruby "extconf.rb" }
end
