module Rakey
  def self.clean(*patterns)
    patterns.each do |pattern|
      files = Dir[pattern]
      rm_rf(files) unless files.empty?
    end
  end
end

namespace :spidermonkey do
  # this scabrous hack is a temporary stand-in for real deps
  task :compile => "vendor/spidermonkey/up2date"
  
  file "vendor/spidermonkey/up2date" do
    Dir.chdir("vendor/spidermonkey") { sh "make -f Makefile.ref && touch up2date" }
  end
  
  task :clean do
    Rakey.clean("vendor/spidermonkey/**/*.OBJ", "vendor/spidermonkey/uptodate")
  end
end
