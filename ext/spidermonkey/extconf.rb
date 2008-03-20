# this needs to happen before mkmf is required.
ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require "mkmf"

$CFLAGS << " -g -DXP_UNIX"

spidermonkey_base_dir = "../../vendor/spidermonkey"

# we can't even run the extconf unless Spidermonkey has built
Dir.chdir(spidermonkey_base_dir) { system "make -f Makefile.ref" }

spidermonkey_obj_dir = Dir[spidermonkey_base_dir + "/*.OBJ"].first

dir_config("johnson/spidermonkey")

find_header("jsautocfg.h", spidermonkey_obj_dir)
find_header("jsapi.h", spidermonkey_base_dir)

$LOCAL_LIBS << spidermonkey_obj_dir + "/libjs.a"

create_makefile("johnson/spidermonkey")
