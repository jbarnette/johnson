# -*- ruby -*-

# Copyright (c) Ryan Davis, Zen Spider Software
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rbconfig'
require 'rubyforge'
require 'yaml'

class Hoe #:nodoc:
  VERSION = '1.5.3'

  ruby_prefix = Config::CONFIG['prefix']
  sitelibdir = Config::CONFIG['sitelibdir']

  ##
  # Used to specify a custom install location (for rake install).

  PREFIX = ENV['PREFIX'] || ruby_prefix

  ##
  # Used to add extra flags to RUBY_FLAGS.

  RUBY_DEBUG = ENV['RUBY_DEBUG']

  default_ruby_flags = "-w -I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}" +
    (RUBY_DEBUG ? " #{RUBY_DEBUG}" : '')

  ##
  # Used to specify flags to ruby [has smart default].

  RUBY_FLAGS = ENV['RUBY_FLAGS'] || default_ruby_flags

  ##
  # Used to add flags to test_unit (e.g., -n test_borked).

  FILTER = ENV['FILTER'] # for tests (eg FILTER="-n test_blah")

  # :stopdoc:

  RUBYLIB = if PREFIX == ruby_prefix then
              sitelibdir
            else
              File.join(PREFIX, sitelibdir[ruby_prefix.size..-1])
            end

  DLEXT = Config::CONFIG['DLEXT']

  WINDOZE = /djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM unless defined? WINDOZE

  DIFF = if WINDOZE
           'diff.exe'
         else
           if system("gdiff", __FILE__, __FILE__)
             'gdiff' # solaris and kin suck
           else
             'diff'
           end
         end unless defined? DIFF

  # :startdoc:

  ##
  # *Recommended*: The author(s) of the package. (can be array)
  # Really. Set this or we'll tease you.

  attr_accessor :author

  ##
  # Populated automatically from the manifest. List of executables.

  attr_accessor :bin_files # :nodoc:

  ##
  # Optional: A description of the release's latest changes. Auto-populates.

  attr_accessor :changes

  ##
  # Optional: An array of file patterns to delete on clean.

  attr_accessor :clean_globs

  ##
  # Optional: A description of the project. Auto-populates.

  attr_accessor :description

  ##
  # Optional: What sections from the readme to use for auto-description. Defaults to %w(description).

  attr_accessor :description_sections

  ##
  # *Recommended*: The author's email address(es). (can be array)

  attr_accessor :email

  ##
  # Optional: An array of rubygem dependencies.

  attr_accessor :extra_deps

  ##
  # Populated automatically from the manifest. List of library files.

  attr_accessor :lib_files # :nodoc:

  ##
  # Optional: Array of incompatible versions for multiruby filtering. Used as a regex.

  attr_accessor :multiruby_skip

  ##
  # *MANDATORY*: The name of the release.

  attr_accessor :name

  ##
  # Optional: Should package create a tarball? [default: true]

  attr_accessor :need_tar

  ##
  # Optional: Should package create a zipfile? [default: false]

  attr_accessor :need_zip

  ##
  # Optional: A post-install message to be displayed when gem is installed.

  attr_accessor :post_install_message

  ##
  # Optional: A regexp to match documentation files against the manifest.

  attr_accessor :rdoc_pattern

  ##
  # Optional: Name of RDoc destination directory on Rubyforge. [default: +name+]

  attr_accessor :remote_rdoc_dir

  ##
  # Optional: Flags for RDoc rsync. [default: "-av --delete"]

  attr_accessor :rsync_args

  ##
  # Optional: The name of the rubyforge project. [default: name.downcase]

  attr_accessor :rubyforge_name

  ##
  # The Gem::Specification.

  attr_accessor :spec # :nodoc:

  ##
  # Optional: A hash of extra values to set in the gemspec. Value may be a proc.

  attr_accessor :spec_extras

  ##
  # Optional: A short summary of the project. Auto-populates.

  attr_accessor :summary

  ##
  # Optional: Number of sentences from description for summary. Defaults to 1.

  attr_accessor :summary_sentences

  ##
  # Populated automatically from the manifest. List of tests.

  attr_accessor :test_files # :nodoc:

  ##
  # Optional: An array of test file patterns [default: test/**/test_*.rb]

  attr_accessor :test_globs

  ##
  # Optional: The url(s) of the project. (can be array). Auto-populates.

  attr_accessor :url

  ##
  # *MANDATORY*: The version. Don't hardcode! use a constant in the project.

  attr_accessor :version

  def initialize(name, version) # :nodoc:
    self.name = name
    self.version = version

    # Defaults
    self.author = []
    self.clean_globs = %w(diff diff.txt email.txt ri
                          *.gem *~ **/*~ *.rbc **/*.rbc)
    self.description_sections = %w(description)
    self.email = []
    self.extra_deps = []
    self.multiruby_skip = []
    self.need_tar = true
    self.need_zip = false
    self.rdoc_pattern = /^(lib|bin|ext)|(rdoc|txt)$/
    self.remote_rdoc_dir = name
    self.rsync_args = '-av --delete'
    self.rubyforge_name = name.downcase
    self.spec_extras = {}
    self.summary_sentences = 1
    self.test_globs = ['test/**/test_*.rb']
    self.post_install_message = nil

    yield self if block_given?

    # Intuit values:

    def missing name
      warn "** #{name} is missing or in the wrong format for auto-intuiting."
      warn "   run `sow blah` and look at its text files"
    end

    readme   = File.read("README.rdoc").split(/^(=+ .*)$/)[1..-1] rescue ''
    unless readme.empty? then
      sections = readme.map { |s|
        s =~ /^=/ ? s.strip.downcase.chomp(':').split.last : s.strip
      }
      sections = Hash[*sections]
      desc = sections.values_at(*description_sections).join("\n\n")
      summ = desc.split(/\.\s+/).first(summary_sentences).join(". ")

      self.description ||= desc
      self.summary ||= summ
      self.url ||= readme[1].gsub(/^\* /, '').split(/\n/).grep(/\S+/)
    else
      missing 'README.rdoc'
    end

    self.changes ||= begin
                       h = File.read("CHANGELOG")
                       h.split(/^(===.*)/)[1..2].join.strip
                     rescue
                       missing 'CHANGELOG'
                       ''
                     end

    %w(email author).each do |field|
      value = self.send(field)
      if value.nil? or value.empty? then
        if Time.now < Time.local(2008, 4, 1) then
          warn "Hoe #{field} value not set - Fix by 2008-04-01!"
          self.send "#{field}=", "doofus"
        else
          abort "Hoe #{field} value not set. aborting"
        end
      end
    end

    self.extra_deps = Array(extra_deps).map { |o| String === o ? [o] : o }

    define_tasks
  end

  def developer name, email
    self.author << name
    self.email << email
  end

  def define_tasks # :nodoc:
    def with_config # :nodoc:
      rc = File.expand_path("~/.hoerc")
      exists = File.exist? rc
      config = exists ? YAML.load_file(rc) : {}
      yield(config, rc)
    end

    desc 'Run the default tasks.'
    task :default => :test

    desc 'Run the test suite. Use FILTER to add to the command line.'
    task :test do
      run_tests
    end

    desc 'Show which test files fail when run alone.'
    task :test_deps do
      tests = Dir["test/**/test_*.rb"]  +  Dir["test/**/*_test.rb"]

      tests.each do |test|
        if not system "ruby -Ibin:lib:test #{test} &> /dev/null" then
          puts "Dependency Issues: #{test}"
        end
      end
    end

    desc 'Run the test suite using multiruby.'
    task :multi do
      run_tests :multi
    end

    ############################################################
    # Packaging and Installing

    signing_key = nil
    cert_chain = []

    with_config do |config, path|
      break unless config['signing_key_file'] and config['signing_cert_file']
      key_file = File.expand_path config['signing_key_file'].to_s
      signing_key = key_file if File.exist? key_file

      cert_file = File.expand_path config['signing_cert_file'].to_s
      cert_chain << cert_file if File.exist? cert_file
    end

    self.spec = Gem::Specification.new do |s|
      s.name = name
      s.version = version
      s.summary = summary
      case author
      when Array
        s.authors = author
      else
        s.author = author
      end
      s.email = email
      s.homepage = Array(url).first
      s.rubyforge_project = rubyforge_name

      s.description = description

      extra_deps.each do |dep|
        s.add_dependency(*dep)
      end

      s.files = File.read("MANIFEST").delete("\r").split(/\n/)
      s.executables = s.files.grep(/^bin/) { |f| File.basename(f) }

      s.bindir = "bin"
      dirs = Dir['{lib,ext}']
      s.require_paths = dirs unless dirs.empty?

      s.rdoc_options = ['--main', 'README.rdoc']
      s.extra_rdoc_files = s.files.grep(/(txt|rdoc)$/)
      s.has_rdoc = true

      s.post_install_message = post_install_message

      if test ?f, "test/test_all.rb" then
        s.test_file = "test/test_all.rb"
      else
        s.test_files = Dir[*test_globs]
      end

      if signing_key and cert_chain then
        s.signing_key = signing_key
        s.cert_chain = cert_chain
      end

      ############################################################
      # Allow automatic inclusion of compiled extensions
      if ENV['INLINE'] then
        s.platform = ENV['FORCE_PLATFORM'] || Gem::Platform::CURRENT
        # name of the extension is CamelCase
        alternate_name = if name =~ /[A-Z]/ then
                           name.gsub(/([A-Z])/, '_\1').downcase.sub(/^_/, '')
                         elsif name =~ /_/ then
                           name.capitalize.gsub(/_([a-z])/) { $1.upcase }
                         end

        # Try collecting Inline extensions for +name+
        if defined?(Inline) then
          directory 'lib/inline'

          extensions = Dir.chdir(Inline::directory) {
            Dir["Inline_{#{name},#{alternate_name}}_*.#{DLEXT}"]
          }
          extensions.each do |ext|
            # add the inlined extension to the spec files
            s.files += ["lib/inline/#{ext}"]

            # include the file in the tasks
            file "lib/inline/#{ext}" => ["lib/inline"] do
              cp File.join(Inline::directory, ext), "lib/inline"
            end
          end
        end
      end

      # Do any extra stuff the user wants
      spec_extras.each do |msg, val|
        case val
        when Proc
          val.call(s.send(msg))
        else
          s.send "#{msg}=", val
        end
      end
    end

    desc 'Show information about the gem.'
    task :debug_gem do
      puts spec.to_ruby
    end
    
    desc "Generate #{name}.gemspec"
    task :gemspec do
      File.open("#{name}.gemspec", "w") do |f|
        f.write spec.to_ruby
      end
    end

    self.lib_files = spec.files.grep(/^(lib|ext)/)
    self.bin_files = spec.files.grep(/^bin/)
    self.test_files = spec.files.grep(/^test/)

    Rake::GemPackageTask.new spec do |pkg|
      pkg.need_tar = @need_tar
      pkg.need_zip = @need_zip
    end

    desc 'Install the package as a gem.'
    task :install_gem => [:clean, :package] do
      sh "#{'sudo ' unless WINDOZE}gem install --local pkg/*.gem"
    end

    desc 'Package and upload the release to rubyforge.'
    task :release => [:clean, :package] do |t|
      v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
      abort "Versions don't match #{v} vs #{version}" if v != version
      pkg = "pkg/#{name}-#{version}"

      if $DEBUG then
        puts "release_id = rf.add_release #{rubyforge_name.inspect}, #{name.inspect}, #{version.inspect}, \"#{pkg}.tgz\""
        puts "rf.add_file #{rubyforge_name.inspect}, #{name.inspect}, release_id, \"#{pkg}.gem\""
      end

      rf = RubyForge.new.configure
      puts "Logging in"
      rf.login

      c = rf.userconfig
      c["release_notes"] = description if description
      c["release_changes"] = changes if changes
      c["preformatted"] = true

      files = [(@need_tar ? "#{pkg}.tgz" : nil),
               (@need_zip ? "#{pkg}.zip" : nil),
               "#{pkg}.gem"].compact

      puts "Releasing #{name} v. #{version}"
      rf.add_release rubyforge_name, name, version, *files
    end

    ############################################################
    # Doco

    Rake::RDocTask.new(:docs) do |rd|
      rd.main = "README.rdoc"
      rd.options << '-d' if RUBY_PLATFORM !~ /win32/ and `which dot` =~ /\/dot/ and not ENV['NODOT']
      rd.rdoc_dir = 'doc'
      files = spec.files.grep(rdoc_pattern)
      files -= ['MANIFEST', 'lib/hoe.rb']
      rd.rdoc_files.push(*files)

      title = "#{name}-#{version} Documentation"
      title = "#{rubyforge_name}'s " + title if rubyforge_name != name

      rd.options << "-t #{title}"
    end

    desc 'Generate ri locally for testing.'
    task :ridocs => :clean do
      sh %q{ rdoc --ri -o ri . }
    end

    desc 'Publish RDoc to RubyForge.'
    task :publish_docs => [:clean, :docs] do
      config = YAML.load(File.read(File.expand_path("~/.rubyforge/user-config.yml")))
      host = "#{config["username"]}@rubyforge.org"

      remote_dir = "/var/www/gforge-projects/#{rubyforge_name}/#{remote_rdoc_dir}"
      local_dir = 'doc'

      sh %{rsync #{rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
    end

    # no doco for this one
    task :publish_on_announce do
      with_config do |config, _|
        Rake::Task['publish_docs'].invoke if config["publish_on_announce"]
      end
    end

    ############################################################
    # Misc/Maintenance:

    desc 'Run ZenTest against the package.'
    task :audit do
      libs = %w(lib test ext).join(File::PATH_SEPARATOR)
      sh "zentest -I=#{libs} #{spec.files.grep(/^(lib|test)/).join(' ')}"
    end

    desc 'Clean up all the extras.'
    task :clean => [ :clobber_docs, :clobber_package ] do
      clean_globs.each do |pattern|
        files = Dir[pattern]
        rm_rf files, :verbose => true unless files.empty?
      end
    end

    desc 'Create a fresh ~/.hoerc file.'
    task :config_hoe do
      with_config do |config, path|
        default_config = {
          "exclude" => /tmp$|CVS|\.svn/,
          "publish_on_announce" => false,
          "signing_key_file" => "~/.gem/gem-private_key.pem",
          "signing_cert_file" => "~/.gem/gem-public_cert.pem",
          "blogs" => [ {
                         "user" => "user",
                         "url" => "url",
                         "extra_headers" => {
                           "mt_convert_breaks" => "markdown"
                         },
                         "blog_id" => "blog_id",
                         "password"=>"password",
                       } ],
        }
        File.open(path, "w") do |f|
          YAML.dump(default_config.merge(config), f)
        end

        editor = ENV['EDITOR'] || 'vi'
        system "#{editor} #{path}" if ENV['SHOW_EDITOR'] != 'no'
      end
    end

    desc 'Generate email announcement file.'
    task :email do
      require 'rubyforge'
      subject, title, body, urls = announcement

      File.open("email.txt", "w") do |mail|
        mail.puts "Subject: [ANN] #{subject}"
        mail.puts
        mail.puts title
        mail.puts
        mail.puts urls
        mail.puts
        mail.puts body
        mail.puts
        mail.puts urls
      end
      puts "Created email.txt"
    end

    desc 'Post announcement to blog.'
    task :post_blog do
      require 'xmlrpc/client'

      with_config do |config, path|
        break unless config['blogs']

        subject, title, body, urls = announcement
        body += "\n\n#{urls}"

        config['blogs'].each do |site|
          server = XMLRPC::Client.new2(site['url'])
          content = site['extra_headers'].merge(:title => title,
                                                :description => body)
          result = server.call('metaWeblog.newPost',
                               site['blog_id'],
                               site['user'],
                               site['password'],
                               content,
                               true)
        end
      end
    end

    desc 'Post announcement to rubyforge.'
    task :post_news do
      require 'rubyforge'
      subject, title, body, urls = announcement

      rf = RubyForge.new.configure
      rf.login
      rf.post_news(rubyforge_name, subject, "#{title}\n\n#{body}")
      puts "Posted to rubyforge"
    end

    desc 'Create news email file and post to rubyforge.'
    task :announce => [:email, :post_news, :post_blog, :publish_on_announce ]

    desc 'Verify the manifest.'
    task :check_manifest => :clean do
      f = "Manifest.tmp"
      require 'find'
      files = []
      with_config do |config, _|
        exclusions = config["exclude"]
        abort "exclude entry missing from .hoerc. Aborting." if exclusions.nil?
        Find.find '.' do |path|
          next unless File.file? path
          next if path =~ exclusions
          files << path[2..-1]
        end
        files = files.sort.join "\n"
        File.open f, 'w' do |fp| fp.puts files end
        system "#{DIFF} -du MANIFEST #{f}"
        rm f
      end
    end

    desc 'Generate a key for signing your gems.'
    task :generate_key do
      email = spec.email
      abort "No email in your gemspec" if email.nil? or email.empty?

      key_file = with_config { |config, _| config['signing_key_file'] }
      cert_file = with_config { |config, _| config['signing_cert_file'] }

      if key_file.nil? or cert_file.nil? then
        ENV['SHOW_EDITOR'] ||= 'no'
        Rake::Task['config_hoe'].invoke

        key_file = with_config { |config, _| config['signing_key_file'] }
        cert_file = with_config { |config, _| config['signing_cert_file'] }
      end

      key_file = File.expand_path key_file
      cert_file = File.expand_path cert_file

      unless File.exist? key_file or File.exist? cert_file then
        sh "gem cert --build #{email}"
        mv "gem-private_key.pem", key_file, :verbose => true
        mv "gem-public_cert.pem", cert_file, :verbose => true

        puts "Installed key and certificate."

        rf = RubyForge.new.configure
        rf.login

        cert_package = "#{rubyforge_name}-certificates"

        begin
          rf.lookup 'package', cert_package
        rescue
          rf.create_package rubyforge_name, cert_package
        end

        begin
          rf.lookup('release', cert_package)['certificates']
          rf.add_file rubyforge_name, cert_package, 'certificates', cert_file
        rescue
          rf.add_release rubyforge_name, cert_package, 'certificates', cert_file
        end

        puts "Uploaded certificate to release \"certificates\" in package #{cert_package}"
      else
        puts "Keys already exist."
      end
    end

  end # end define

  def announcement # :nodoc:
    changes = self.changes.rdoc_to_markdown

    subject = "#{name} #{version} Released"
    title = "#{name} version #{version} has been released!"
    body = "#{description}\n\nChanges:\n\n#{changes}".rdoc_to_markdown
    urls = Array(url).map { |s| "* <#{s.strip.rdoc_to_markdown}>" }.join("\n")

    return subject, title, body, urls
  end

  def run_tests(multi=false) # :nodoc:
    msg = multi ? :sh : :ruby
    cmd = if test ?f, 'test/test_all.rb' then
            "#{RUBY_FLAGS} test/test_all.rb #{FILTER}"
          else
            tests = ['test/unit'] + test_globs.map { |g| Dir.glob(g) }.flatten
            tests.map! {|f| %Q(require "#{f}")}
            "#{RUBY_FLAGS} -e '#{tests.join("; ")}' #{FILTER}"
          end

    excludes = multiruby_skip.join(":")
    ENV['EXCLUDED_VERSIONS'] = excludes
    cmd = "multiruby #{cmd}" if multi

    send msg, cmd
  end

  ##
  # Reads a file at +path+ and spits out an array of the +paragraphs+ specified.
  #
  #   changes = p.paragraphs_of('CHANGELOG', 0..1).join("\n\n")
  #   summary, *description = p.paragraphs_of('README.rdoc', 3, 3..8)

  def paragraphs_of(path, *paragraphs)
    File.read(path).delete("\r").split(/\n\n+/).values_at(*paragraphs)
  end
end

# :enddoc:

class ::Rake::SshDirPublisher # :nodoc:
  attr_reader :host, :remote_dir, :local_dir
end

class String
  def rdoc_to_markdown
    self.gsub(/^mailto:/, '').gsub(/^(=+)/) { "#" * $1.size }
  end
end

if $0 == __FILE__ then
  out = `rake -T | egrep -v "redocs|repackage|clobber|trunk"`
  puts out.gsub(/\#/, '-').gsub(/^rake /, '# * ')
end
