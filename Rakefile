require "rubygems"
require "hoe"
require "rake/extensiontask"

Hoe.plugin :debugging, :git

HOE = Hoe.spec "johnson" do
  developer "John Barnette",   "jbarnette@rubyforge.org"
  developer "Aaron Patterson", "aaron.patterson@gmail.com"
  developer "Yehuda Katz",     "wycats@gmail.com"
  developer "Matthew Draper",  "matthew@trebex.net"

  self.extra_rdoc_files = FileList["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"
  self.test_globs       = %w(test/**/*_test.rb)

  clean_globs << "lib/johnson/spidermonkey.bundle"
  clean_globs << "tmp"
  clean_globs << "vendor/spidermonkey/**/*.OBJ"
  clean_globs << "ext/**/*.{o,so,bundle,a,log}"

  # FIX: this crap needs to die
  extra_deps << "rake"
  extra_dev_deps << "rake-compiler"
  self.spec_extras = { :extensions => %w(Rakefile) }
end

Rake::ExtensionTask.new "spidermonkey", HOE.spec do |ext|
  ext.lib_dir = "lib/johnson"
end

task :test => :compile

Dir["lib/tasks/*.rake"].each { |f| load f }

# HACK: If Rake is running as part of the gem install, clear out the
# default task and make the extensions compile instead.

Rake::Task[:default].prerequisites.replace %w(compile) if ENV["RUBYARCHDIR"]
