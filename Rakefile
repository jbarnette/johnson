require "rubygems"
require "hoe"
require 'erb'
require "./lib/johnson/version.rb"

# what sort of extension are we building?
kind = Config::CONFIG["DLEXT"]

GENERATED_NODE = "ext/spidermonkey/immutable_node.c"

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
    GENERATED_NODE,
    "vendor/spidermonkey/**/*.OBJ"]
    
  p.test_globs = ["test/**/*_test.rb"]
    
  p.spec_extras = { :extensions => ["ext/spidermonkey/extconf.rb"] }
end

# make sure the C bits are up-to-date when testing
Rake::Task[:test].prerequisites << :extensions
Rake::Task[:check_manifest].prerequisites << GENERATED_NODE

task :build => :extensions

# gem depends on the native extension actually building
Rake::Task[:gem].prerequisites << :extensions

desc "Our johnson requires extensions."
task :extensions => ["lib/johnson/spidermonkey.#{kind}"]

task :spidermonkey => :submodules do
  if ENV['CROSS']
    Dir.chdir("vendor/spidermonkey") { sh "make -f Makefile.ref OS_CONFIG=#{ENV['CROSS']}" }
  else
    Dir.chdir("vendor/spidermonkey") { sh "make -f Makefile.ref" }
  end
end
task :spidermonkey => "vendor/spidermonkey/config/#{ENV['CROSS']}.mk" if ENV['CROSS']

file "vendor/spidermonkey/config/MINGW32.mk" => "MINGW32.mk" do |t|
  File.copy(t.prerequisites.first, t.name)
end

task :submodules do
  sh "git submodule init && git submodule update"
end

file "ext/spidermonkey/spidermonkey.#{kind}" =>
  ["ext/spidermonkey/Makefile"] + FileList["ext/spidermonkey/*.{c,h}"].to_a do
  
  Dir.chdir("ext/spidermonkey") { sh "make" }
end

# for testing, we toss the SpiderMonkey extension in lib/johnson
file "lib/johnson/spidermonkey.#{kind}" =>
  "ext/spidermonkey/spidermonkey.#{kind}" do |t|

  File.copy(t.prerequisites.first, t.name)
end

file "ext/spidermonkey/Makefile" =>
  [:spidermonkey, GENERATED_NODE, "ext/spidermonkey/extconf.rb"] do
  
  dirs = (ENV['CROSS'] ? [ENV["CROSSLIB"]] : []) + $:
  command = ["ruby"] + dirs.map{|dir| "-I#{File.expand_path dir}"} + ["extconf.rb"]
  Dir.chdir("ext/spidermonkey") { sh *command }
end

def jsops
  ops = []
  File.open('vendor/spidermonkey/jsopcode.tbl', 'rb') { |f|
    f.each_line do |line|
      if line =~ /^OPDEF\((\w+),/
        ops << $1
      end
    end
  }
  ops
end

def tokens
  toks = []
  File.open('vendor/spidermonkey/jsscan.h', 'rb') { |f|
    f.each_line do |line|
      line.scan(/TOK_\w+/).each do |token|
        next if token == 'TOK_ERROR'
        toks << token
      end
    end
  }
  toks.uniq
end

file GENERATED_NODE => ["ext/spidermonkey/immutable_node.c.erb", "vendor/spidermonkey/jsopcode.tbl", "vendor/spidermonkey/jsscan.h"] do |t|
  template = ERB.new(File.open(t.prerequisites.first, 'rb') { |x| x.read })
  File.open(GENERATED_NODE, 'wb') { |f|
    f.write template.result(binding)
  }
end
