# this needs to happen before mkmf is required
ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require "find"
require "mkmf"

cflags  = %w(g)
defines = %w(XP_UNIX)

warnings  = %w(all extra cast-qual write-strings conversion missing-noreturn)
warnings << "inline"

cflags.concat warnings.collect { |w| "W#{w}" }
cflags.concat defines.collect  { |d| "D#{d}" }

$CFLAGS << cflags.collect { |f| " -#{f}" }.join(" ")

spidermonkey_dir = File.expand_path File.dirname(__FILE__) +
  "/../../vendor/spidermonkey"

Dir.chdir spidermonkey_dir do
  system "make -f Makefile.ref" if Dir["**/libjs.a"].empty?
end

libjs = Dir[spidermonkey_dir + "/**/libjs.a"].first
$LOCAL_LIBS << libjs

dir_config "johnson/spidermonkey"

find_header "jsautocfg.h", File.dirname(libjs)
find_header "jsapi.h", spidermonkey_dir

create_makefile "johnson/spidermonkey"
