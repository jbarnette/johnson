# this needs to happen before mkmf is required. also, FIXME
ENV["ARCHFLAGS"] = "-arch #{`uname -p` =~ /powerpc/ ? 'ppc' : 'i386'}"

require "mkmf"

$CFLAGS << " -g -DXP_UNIX"

spidermonkey_base_dir = "../../vendor/spidermonkey"

# FIXME: hack? we can't even run the extconf unless Spidermonkey has built
# Figure out how to generate a makefile with a dependency on vendor/spidermonkey

Dir.chdir(spidermonkey_base_dir) { system "make -f Makefile.ref" }

spidermonkey_obj_dir = Dir[spidermonkey_base_dir + "/*.OBJ"].first

dir_config("johnson/spidermonkey")

find_header("jsautocfg.h", spidermonkey_obj_dir)
find_header("jsapi.h", spidermonkey_base_dir)

$LOCAL_LIBS << spidermonkey_obj_dir + "/libjs.a"

create_makefile("johnson/spidermonkey")
