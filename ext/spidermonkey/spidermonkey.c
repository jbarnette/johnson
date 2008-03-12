#include "spidermonkey.h"
#include "context.h"
#include "error.h"

void Init_spidermonkey()
{
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  
  init_Johnson_Error(johnson);
  init_Johnson_SpiderMonkey_Context(spidermonkey);
  
  rb_define_const(spidermonkey, "VERSION",
    rb_obj_freeze(rb_str_new2(JS_GetImplementationVersion())));
}
