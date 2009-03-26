require "rubygems"
require "hoe"
require "rake/extensiontask"

require "./lib/johnson/version.rb"

HOE = Hoe.new "johnson", Johnson::VERSION do |p|
  p.developer "John Barnette",   "jbarnette@rubyforge.org"
  p.developer "Aaron Patterson", "aaron.patterson@gmail.com"
  p.developer "Yehuda Katz",     "wycats@gmail.com"
  p.developer "Matthew Draper",  "matthew@trebex.net"

  p.history_file     = "CHANGELOG.rdoc"
  p.readme_file      = "README.rdoc"
  p.summary          = "Johnson wraps JavaScript in a loving Ruby embrace."
  p.url              = "http://github.com/jbarnette/johnson/wikis"

  p.extra_rdoc_files = [p.readme_file]
  p.need_tar         = false
  p.test_globs       = %w(test/**/*_test.rb)

  p.clean_globs     << "lib/johnson/spidermonkey.bundle"
  p.clean_globs     << "tmp"
  p.clean_globs     << "vendor/spidermonkey/**/*.OBJ"

  p.extra_deps      << "rake"
  p.extra_dev_deps  << "rake-compiler"
end

Rake::ExtensionTask.new "spidermonkey", HOE.spec do |ext|
  ext.lib_dir = "lib/johnson"
end

HOE.spec.extensions = Dir["ext/**/extconf.rb"]

task :test => :compile

Dir["lib/tasks/*.rake"].each { |f| load f }
