# if you want to configure tracemonkey for debugging, just configure yourself with something like
# ./configure --enable-debug --disable-optimize
# Note that enabling debugging breaks the API (!, some members are added to structs).
# so the debugging flags are extracted from the config defs and passed to the ext build.

ENV["RC_ARCHS"] = "" if RUBY_PLATFORM =~ /darwin/

require "find"
require "mkmf"

cflags  = %w(g)
defines = %w(XP_UNIX)

warnings  = %w(all extra cast-qual write-strings conversion missing-noreturn)
warnings << "inline"

cflags.concat warnings.collect { |w| "W#{w}" }
cflags.concat defines.collect  { |d| "D#{d}" }

tracemonkey_dir = File.expand_path File.dirname(__FILE__) +
  "/../../vendor/tracemonkey"

Dir.chdir tracemonkey_dir do
  system "autoconf213" or
    system "autoconf-2.13" or 
    raise "could not run autoconf" if Dir["configure"].empty?
  system "./configure --enable-static" or raise "could not run configure" if Dir["Makefile"].empty?
  system 'egrep -q '+%q('MOZ_DEBUG[[:space:]]*=[[:space:]]*1')+' config/autoconf.mk'
  debug = ""
  if $?.exitstatus == 0
    debug = `egrep MOZ_DEBUG_ENABLE_DEFS config/autoconf.mk`
  else
    # you might think this would be a good idea: it's not
    # debug = `egrep MOZ_DEBUG_DISABLE_DEFS config/autoconf.mk`
  end
  cflags.concat debug.sub( %r(^.*=\s*), "" ).split.map { |f| f.sub %r(^-), "" }
  system "make" or raise "could not make tracemonkey" if Dir["**/libjs_static.a"].empty?
end

libjs = Dir[tracemonkey_dir + "/**/libjs_static.a"].first
$LOCAL_LIBS << libjs
$LIBS += " -lstdc++ "

dir_config "johnson/tracemonkey"

find_header "jsautocfg.h", File.dirname(libjs)
find_header "jsapi.h", tracemonkey_dir

$CFLAGS << cflags.collect { |f| " -#{f}" }.join(" ")

create_makefile "johnson/tracemonkey/tracemonkey"
