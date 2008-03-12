require "rubygems"
require "test/unit"
require "mocha"

%w(../lib ../ext/spidermonkey).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

# If the test isn't running from Rake, make sure the extension's current.
Rake rescue Dir.chdir(File.dirname(__FILE__) + "/..") { %x(rake extensions) }

require "johnson"
