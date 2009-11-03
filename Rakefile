require "rubygems"

gem "hoe", "~> 2.3"
require "hoe"

gem "rake-compiler", "~> 0.6"
require "rake/extensiontask"

FILTER = ENV['FILTER'] || ENV['TESTOPTS']

INTERPRETERS = [ "spidermonkey", "tracemonkey" ]

SUFFIXES = {}
SUFFIXES[ "spidermonkey" ] = "c"
SUFFIXES[ "tracemonkey" ] = "cc"

generated_nodes = []

INTERPRETERS.each do |interpreter|

  suffix = SUFFIXES[interpreter]
  
  generated_nodes << "ext/#{interpreter}/immutable_node.#{suffix}"
  
  generated_node = "ext/#{interpreter}/immutable_node.#{suffix}"
  
  file generated_node => "ext/#{interpreter}/immutable_node.#{suffix}.erb"  do |t|
    template = ERB.new(File.open(t.prerequisites.first, "rb") { |x| x.read })
    jsops = jsops interpreter
    tokens = tokens interpreter
    template.result(binding)
    File.open(generated_node, "wb") { |f| f.write template.result(binding) }
  end

  task :"compile:#{interpreter}" => generated_node
  task :compile => :"compile:#{interpreter}"

end

Hoe.plugin :debugging, :doofus, :git

Hoe.spec "smparkes-johnson" do
  developer "John Barnette",   "jbarnette@rubyforge.org"
  developer "Aaron Patterson", "aaron.patterson@gmail.com"
  developer "Yehuda Katz",     "wycats@gmail.com"
  developer "Matthew Draper",  "matthew@trebex.net"

  self.extra_rdoc_files         = FileList["*.rdoc"]
  self.history_file             = "CHANGELOG.rdoc"
  self.readme_file              = "README.rdoc"
  self.spec_extras[:extensions] = %w(ext/spidermonkey/extconf.rb 
                                     ext/tracemonkey/extconf.rb)

  extra_dev_deps << ["rake-compiler", "~> 0.6"]

  clean_globs    << "ext/**/Makefile"
  clean_globs    << "ext/**/*.{o,so,dylib,bundle,a,log}"
  clean_globs    << "vendor/**/*.{o,so,dylib,bundle,a,log}"
  clean_globs    << "ext/spidermonkey/immutable_node.c"
  clean_globs    << "ext/tracemonkey/immutable_node.cc"
  clean_globs    << "lib/johnson/spidermonkey/spidermonkey.bundle"
  clean_globs    << "lib/johnson/tracemonkey/tracemonkey.bundle"
  clean_globs    << "tmp"
  clean_globs    << "vendor/spidermonkey/**/*.OBJ"
  clean_globs    << "vendor/tracemonkey/**/*.OBJ"

  Rake::ExtensionTask.new "spidermonkey", spec do |ext|
    ext.lib_dir = "lib/johnson/spidermonkey"
  end

  Rake::ExtensionTask.new "tracemonkey", spec do |ext|
    ext.lib_dir = "lib/johnson/tracemonkey"
  end
end

task(:test).clear

task :test => :compile

task :clean do
  Dir.chdir "vendor/spidermonkey" do
    sh "make clean -f Makefile.ref" unless Dir["**/libjs.a"].empty?
  end

  Dir.chdir "vendor/tracemonkey" do
    sh "make clean -f Makefile.ref" unless Dir["**/libjs.a"].empty?
  end
end

require "erb"

def jsops interpreter
  ops = []
  File.open("vendor/#{interpreter}/jsopcode.tbl", "rb") { |f|
    f.each_line do |line|
      if line =~ /^OPDEF\((\w+),/
        ops << $1
      end
    end
  }
  ops
end

def tokens interpreter
  toks = []
  File.open("vendor/#{interpreter}/jsscan.h", "rb") { |f|
    f.each_line do |line|
      line.scan(/TOK_\w+/).each do |token|
        next if token == "TOK_ERROR"
        toks << token
      end
    end
  }
  toks.uniq
end

task :"test:default" do
  ruby %(#{Hoe::RUBY_FLAGS} -rrubygems -rjohnson -e 'require "test/johnson/generic/default_test"' #{FILTER})
end

task :test => :"test:default"

INTERPRETERS.each do |interpreter|

  task :"test:#{interpreter}" do
    tests = Dir["test/**/generic/**/*_test.rb"] + Dir["test/**/#{interpreter}/**/*_test.rb"]
    tests.map! { |t| %(require "#{t}";) }
    ruby "#{Hoe::RUBY_FLAGS} -rrubygems -rjohnson -rjohnson/#{interpreter} -e '#{tests.join("; ")}' #{FILTER}"
  end

  task :test => :"test:#{interpreter}"

end

task :package        => generated_nodes
task :check_manifest => generated_nodes

# Local Variables:
# mode:ruby
# End:
