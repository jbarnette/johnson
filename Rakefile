require "rubygems"
require "hoe"
require "rake/extensiontask" unless RUBY_PLATFORM =~ /java/

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

  unless ENV['JOHNSON_FFI']
    p.test_globs       = %w(test/**/*_test.rb)
  else
    p.test_globs       = %w(test/*_test.rb test/johnson/*_test.rb test/johnson/conversions/*_test.rb test/johnson/spidermonkey/**/*_test.rb)
  end

  p.clean_globs     << "lib/johnson/spidermonkey.bundle"
  p.clean_globs     << "tmp"
  p.clean_globs     << "vendor/spidermonkey/**/*.OBJ"
  p.clean_globs     << "ext/**/*.{o,so,bundle,a,log}"

  p.extra_deps      << "rake"
  p.extra_dev_deps  << "rake-compiler"
  p.spec_extras      = { :extensions => %w(Rakefile) }
end

unless ENV['JOHNSON_FFI'] 
  Rake::ExtensionTask.new "spidermonkey", HOE.spec do |ext|
    ext.lib_dir = "lib/johnson"
  end
  
  task :test => :compile
else
  task :compile
end

Dir["lib/tasks/*.rake"].each { |f| load f }

# HACK: If Rake is running as part of the gem install, clear out the
# default task and make the extensions compile instead.

Rake::Task[:default].prerequisites.replace %w(compile) if ENV["RUBYARCHDIR"]
