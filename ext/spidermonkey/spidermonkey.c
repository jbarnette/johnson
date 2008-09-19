#include "spidermonkey.h"
#include "context.h"
#include "ruby_land_proxy.h"
#include "debugger.h"
#include "immutable_node.h"

void Init_spidermonkey()
{
  VALUE johnson = rb_define_module("Johnson"); // FIXME: this belongs outside the extension
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  
  init_Johnson_SpiderMonkey_Context(spidermonkey);
  init_Johnson_SpiderMonkey_Proxy(spidermonkey);
  init_Johnson_SpiderMonkey_Debugger(spidermonkey);
  init_Johnson_SpiderMonkey_Immutable_Node(spidermonkey);
  init_Johnson_SpiderMonkey_Runtime(spidermonkey);
  
  rb_define_const(spidermonkey, "VERSION",
    rb_obj_freeze(rb_str_new2(JS_GetImplementationVersion())));
}
