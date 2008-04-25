# this needs to happen before mkmf is required.
ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require "mkmf"

if Config::CONFIG['target_os'] == 'mingw32'
  $libs = append_library($libs, "winmm")
  $CFLAGS << " -DXP_WIN -DXP_WIN32"
else
  $CFLAGS << " -g -DXP_UNIX"
end
$CFLAGS << " -Wall"

spidermonkey_base_dir = "../../vendor/spidermonkey"

spidermonkey_obj_dir = Dir[spidermonkey_base_dir + "/#{ENV['CROSS'] || ''}*.OBJ"].first

dir_config("johnson/spidermonkey")

find_header("jsautocfg.h", spidermonkey_obj_dir)
find_header("jsapi.h", spidermonkey_base_dir)

$LOCAL_LIBS << spidermonkey_obj_dir + "/libjs.a"

create_makefile("johnson/spidermonkey")
