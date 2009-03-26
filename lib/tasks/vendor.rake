namespace :vendor do
  namespace :spidermonkey do
    desc "Clean the vendored SpiderMonkey."
    task :clean do
      Dir.chdir "vendor/spidermonkey" do
        sh "make clean -f Makefile.ref" unless Dir["**/libjs.a"].empty?
      end
    end

    desc "Compile the vendored SpiderMonkey."
    task :compile do
      Dir.chdir "vendor/spidermonkey" do
        sh "make -f Makefile.ref" if Dir["**/libjs.a"].empty?
      end
    end
  end
end

task :clean                        => "vendor:spidermonkey:clean"
file "ext/spidermonkey/extconf.rb" => "vendor:spidermonkey:compile"
