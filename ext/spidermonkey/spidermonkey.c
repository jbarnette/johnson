#include "spidermonkey.h"
#include "error.h"

void Init_spidermonkey()
{
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_class_under(johnson, "SpiderMonkey", rb_cObject);
  
  init_Johnson_Error(johnson);
  
  rb_define_const(spidermonkey, "VERSION",
    rb_obj_freeze(rb_str_new2(JS_GetImplementationVersion())));
}
