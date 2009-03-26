require "rubygems"
require "erb"
require "hoe"

require "./lib/johnson/version.rb"
abort "Need Ruby version 1.8.x!" unless RUBY_VERSION > "1.8"

# what sort of extension are we building?
kind = Config::CONFIG["DLEXT"]

CROSS = ENV["CROSS"]
MAKE  = ENV["MAKE"] || RUBY_PLATFORM =~ /freebsd/ ? 'gmake' : 'make'
LIBJS = FileList["vendor/spidermonkey/#{CROSS || ''}*.OBJ/libjs.{#{kind},so}"].first || :libjs

GENERATED_NODE = "ext/spidermonkey/immutable_node.c"

HOE = Hoe.new("johnson", Johnson::VERSION) do |p|
  p.developer "John Barnette",   "jbarnette@rubyforge.org"
  p.developer "Aaron Patterson", "aaron.patterson@gmail.com"
  p.developer "Yehuda Katz",     "wycats@gmail.com"
  p.developer "Matthew Draper",  "matthew@trebex.net"

  p.summary          = "Johnson wraps JavaScript in a loving Ruby embrace."
  p.history_file     = "CHANGELOG.rdoc"
  p.readme_file      = "README.rdoc"
  p.extra_rdoc_files = [p.readme_file]
  p.need_tar         = false
  p.url              = "http://github.com/jbarnette/johnson/wikis"

  p.clean_globs = [
    "lib/johnson/spidermonkey.#{kind}",
    "ext/spidermonkey/Makefile",
    "ext/spidermonkey/*.{o,so,bundle,log}",
    GENERATED_NODE,
    "vendor/spidermonkey/**/*.OBJ"]

  p.test_globs  = %w(test/**/*_test.rb)
  p.spec_extras = { :extensions => ["Rakefile"] }
  p.extra_deps  = ["rake"]
end

namespace :gem do
  task :spec do
    File.open("#{HOE.name}.gemspec", "w") do |f|
      HOE.spec.version = "#{HOE.version}.#{Time.now.strftime("%Y%m%d%H%M%S")}"
      f.puts(HOE.spec.to_ruby)
    end
  end
end

# make sure the C bits are up-to-date when testing
Rake::Task[:test].prerequisites << :extensions

Rake::Task[:check_manifest].prerequisites << GENERATED_NODE

task :build => :extensions
task :extension => :build # FIXME: why is this here?

task :extensions => ["lib/johnson/spidermonkey.#{kind}"]

namespace :extensions do
  task :clean do
    Dir.chdir("ext/spidermonkey") do
      sh "rm -f Makefile"
      sh "rm -f *.{o,so,bundle,log}"
    end
  end
end

build_sm = lambda do
  cmd = "#{MAKE} -f Makefile.ref"
  cmd << " OS_CONFIG=#{CROSS}" if CROSS
  Dir.chdir("vendor/spidermonkey") { sh cmd }
end

if Symbol === LIBJS
  task LIBJS, &build_sm
else
  file LIBJS, &build_sm

  task LIBJS => "vendor/spidermonkey/Makefile.ref"
  task LIBJS => Dir["vendor/spidermonkey/*.[ch]"]
  task LIBJS => Dir["vendor/spidermonkey/config/*.mk"]
end

task LIBJS => "vendor/spidermonkey/jsapi.h"
task LIBJS => "vendor/spidermonkey/config/#{CROSS}.mk" if CROSS

file "vendor/spidermonkey/config/MINGW32.mk" => "MINGW32.mk" do |t|
  cp t.prerequisites.first, t.name
end

file "ext/spidermonkey/spidermonkey.#{kind}" =>
  ["ext/spidermonkey/Makefile"] + FileList["ext/spidermonkey/*.{c,h}"].to_a do |t|

  old_time = File.mtime(t.name) rescue nil
  Dir.chdir("ext/spidermonkey") { sh "#{MAKE}" }

  # If make chose not to rebuild the file, we'll touch it, so we don't
  # bother to call make again next time.
  sh "touch #{t.name}" if old_time && File.mtime(t.name) <= old_time
end

# for testing, we toss the SpiderMonkey extension in lib/johnson
file "lib/johnson/spidermonkey.#{kind}" =>
  "ext/spidermonkey/spidermonkey.#{kind}" do |t|

  cp t.prerequisites.first, t.name
end

file "ext/spidermonkey/Makefile" =>
  [LIBJS, GENERATED_NODE, "ext/spidermonkey/extconf.rb"] do
  
  dirs = (CROSS ? [ENV["CROSSLIB"]] : []) + $:
  if defined?(RbConfig)
    ruby_exec = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"])
  end
  ruby_exec ||= "ruby"
  command = [ruby_exec] + dirs.map{|dir| "-I#{File.expand_path dir}"} + ["extconf.rb"]
  Dir.chdir("ext/spidermonkey") { sh *command }
end

def jsops
  ops = []
  File.open("vendor/spidermonkey/jsopcode.tbl", "rb") { |f|
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
  File.open("vendor/spidermonkey/jsscan.h", "rb") { |f|
    f.each_line do |line|
      line.scan(/TOK_\w+/).each do |token|
        next if token == "TOK_ERROR"
        toks << token
      end
    end
  }
  toks.uniq
end

file GENERATED_NODE => ["ext/spidermonkey/immutable_node.c.erb", "vendor/spidermonkey/jsopcode.tbl", "vendor/spidermonkey/jsscan.h"] do |t|
  template = ERB.new(File.open(t.prerequisites.first, "rb") { |x| x.read })
  File.open(GENERATED_NODE, "wb") { |f|
    f.write template.result(binding)
  }
end

Dir["lib/tasks/*.rake"].each { |f| load f }

# Evil evil hack.  Do not run tests when gem installs
if ENV['RUBYARCHDIR']
  prereqs = Rake::Task[:default].prerequisites
  prereqs.clear
  prereqs << :build
end
