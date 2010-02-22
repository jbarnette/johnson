require "rubygems"

gem "hoe", "~> 2.5"
require "hoe"

gem "rake-compiler", "~> 0.7"
require "rake/extensiontask"

FILTER = ENV['FILTER'] || ENV['TESTOPTS']

INTERPRETERS = [ "tracemonkey" ]

SUFFIXES = {}
SUFFIXES[ "tracemonkey" ] = "cc"

generated_nodes = []

INTERPRETERS.each do |interpreter|

  suffix = SUFFIXES[interpreter]
  
  generated_nodes << "ext/#{interpreter}/immutable_node.#{suffix}"
  
  generated_node = "ext/#{interpreter}/immutable_node.#{suffix}"
  
  file generated_node => ["ext/#{interpreter}/immutable_node.#{suffix}.erb",
                          "vendor/#{interpreter}/.git"] do |t|
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
Hoe.plugins.delete :rubyforge

Hoe.spec "johnson" do
  developer "John Barnette",   "jbarnette@rubyforge.org"
  developer "Aaron Patterson", "aaron.patterson@gmail.com"
  developer "Yehuda Katz",     "wycats@gmail.com"
  developer "Matthew Draper",  "matthew@trebex.net"
  developer "Steven Parkes",   "smparkes@smparkes.net"

  self.extra_rdoc_files         = FileList["*.rdoc"]
  self.history_file             = "CHANGELOG.rdoc"
  self.readme_file              = "README.rdoc"
  self.spec_extras[:extensions] = %w(ext/tracemonkey/extconf.rb)

  extra_deps << ["stackdeck", "~> 0.2"]
  extra_dev_deps << ["rake-compiler", "~> 0.6"]

  clean_globs    << "ext/**/Makefile"
  clean_globs    << "ext/**/*.{o,so,dylib,bundle,a,log}"
  clean_globs    << "vendor/**/*.{o,so,dylib,bundle,a,log}"
  clean_globs    << "ext/tracemonkey/immutable_node.cc"
  clean_globs    << "lib/johnson/**/*.{bundle,so}"
  clean_globs    << "tmp"

  clean_globs    << "vendor/tracemonkey/**/.deps"
  clean_globs    << "vendor/tracemonkey/dist"
  clean_globs    << "vendor/tracemonkey/**/Makefile"
  clean_globs    << "vendor/tracemonkey/unallmakefiles"
  clean_globs    << "vendor/tracemonkey/config.{cache,status}"
  clean_globs    << "vendor/tracemonkey/config/{autoconf,myconfig,myrules}.mk"
  clean_globs    << "vendor/tracemonkey/config/{nfspwd,nsinstall,revdepth}"
  clean_globs    << "vendor/tracemonkey/{host_jskwgen,host_jsoplengen,js}"
  clean_globs    << "vendor/tracemonkey/{{,shell/}js,js-config,js-config.h}"
  clean_globs    << "vendor/tracemonkey/{jsautocfg.h,jsautokw.h,jsautooplen.h}"
  clean_globs    << "vendor/tracemonkey/{jscpucfg,mozilla-config.h}"

  clean_globs    << "vendor/tracemonkey/**/.deps"
  clean_globs    << "vendor/tracemonkey/{Makefile,config.{status,cache}}"
  clean_globs    << "vendor/tracemonkey/config/{autoconf.mk,Makefile,myconfig.mk,myrules.mk}"
  clean_globs    << "vendor/tracemonkey/config/{nfspwd,nsinstall,system_wrappers_js}"
  clean_globs    << "vendor/tracemonkey/config/mkdepend/{Makefile}"
  clean_globs    << "vendor/tracemonkey/dist"
  clean_globs    << "vendor/tracemonkey/host_jskwgen"
  clean_globs    << "vendor/tracemonkey/host_jsoplengen"
  clean_globs    << "vendor/tracemonkey/imacro_asm.js"
  clean_globs    << "vendor/tracemonkey/js{,-confdefs.h,-config,-config.h}"
  clean_globs    << "vendor/tracemonkey/editline/Makefile"
  clean_globs    << "vendor/tracemonkey/jsapi-tests/{Makefile,jsapi-tests}"
  clean_globs    << "vendor/tracemonkey/{jsautocfg.h,jsautokw.h,jsautooplen.h,jscpucfg}"
  clean_globs    << "vendor/tracemonkey/**/*.a"
  clean_globs    << "vendor/tracemonkey/**/*.so"
  clean_globs    << "vendor/tracemonkey/shell/js"
  clean_globs    << "vendor/tracemonkey/{lirasm,shell,tests}/Makefile"
  clean_globs    << "vendor/tracemonkey/unallmakefiles"

  Rake::ExtensionTask.new "tracemonkey", spec do |ext|
    ext.lib_dir = "lib/johnson/tracemonkey"
    ext.source_pattern = "*.{cc,h}"
  end
end

file "vendor/tracemonkey/.git" do
  sh "git submodule update --init"
end

task :compile => "vendor/tracemonkey/.git"

task(:test).clear
task :test => :compile

task :clean do
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
