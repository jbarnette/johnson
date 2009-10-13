ENV["RC_ARCHS"] = "" if RUBY_PLATFORM =~ /darwin/

require "find"
require "mkmf"

cflags  = %w(g)
defines = %w(XP_UNIX)

warnings  = %w(all extra cast-qual write-strings conversion missing-noreturn)
warnings << "inline"

cflags.concat warnings.collect { |w| "W#{w}" }
cflags.concat defines.collect  { |d| "D#{d}" }

$CFLAGS << cflags.collect { |f| " -#{f}" }.join(" ")

tracemonkey_dir = File.expand_path File.dirname(__FILE__) +
  "/../../vendor/tracemonkey"

Dir.chdir tracemonkey_dir do
  system "autoconf213" or
    system "autoconf-2.13" or 
    raise "could not run autoconf" if Dir["configure"].empty?
  system "./configure --enable-static" or raise "could not run configure" if Dir["Makefile"].empty?
  system "make" or raise "could not make tracemonkey" if Dir["**/libjs_static.a"].empty?
end

libjs = Dir[tracemonkey_dir + "/**/libjs_static.a"].first
$LOCAL_LIBS << libjs
$LIBS += " -lstdc++ "

dir_config "johnson/tracemonkey"

find_header "jsautocfg.h", File.dirname(libjs)
find_header "jsapi.h", tracemonkey_dir

create_makefile "johnson/tracemonkey/tracemonkey"
