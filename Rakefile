require "rubygems"

gem "hoe", "~> 2.3"
require "hoe"

gem "rake-compiler", "~> 0.6"
require "rake/extensiontask"

Hoe.plugin :debugging, :doofus, :git
Hoe.plugins.delete :rubyforge

Hoe.spec "johnson" do
  developer "John Barnette",   "jbarnette@rubyforge.org"
  developer "Aaron Patterson", "aaron.patterson@gmail.com"
  developer "Yehuda Katz",     "wycats@gmail.com"
  developer "Matthew Draper",  "matthew@trebex.net"

  self.extra_rdoc_files         = FileList["*.rdoc"]
  self.history_file             = "CHANGELOG.rdoc"
  self.readme_file              = "README.rdoc"
  self.test_globs               = %w(test/**/*_test.rb)
  self.spec_extras[:extensions] = %w(ext/spidermonkey/extconf.rb)

  extra_dev_deps << ["rake-compiler", "~> 0.6"]

  clean_globs    << "ext/**/Makefile"
  clean_globs    << "ext/**/*.{o,so,bundle,a,log}"
  clean_globs    << "ext/spidermonkey/immutable_node.c"
  clean_globs    << "lib/johnson/**/*.{bundle,so}"
  clean_globs    << "tmp"
  clean_globs    << "vendor/spidermonkey/**/*.OBJ"

  Rake::ExtensionTask.new "spidermonkey", spec do |ext|
    ext.lib_dir = "lib/johnson/spidermonkey"
  end
end

task :clean do
  Dir.chdir "vendor/spidermonkey" do
    sh "make clean -f Makefile.ref" unless Dir["**/libjs.a"].empty?
  end
end

task :test => :compile

require "erb"

GENERATED_NODE = "ext/spidermonkey/immutable_node.c"

task :package        => GENERATED_NODE
task :check_manifest => GENERATED_NODE

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

file GENERATED_NODE => "ext/spidermonkey/immutable_node.c.erb"  do |t|
  template = ERB.new(File.open(t.prerequisites.first, "rb") { |x| x.read })
  File.open(GENERATED_NODE, "wb") { |f| f.write template.result(binding) }
end

file "ext/spidermonkey/extconf.rb" => GENERATED_NODE
