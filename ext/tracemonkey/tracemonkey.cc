#include "tracemonkey.h"
#include "context.h"
#include "ruby_land_proxy.h"
#include "debugger.h"
#include "immutable_node.h"

extern "C"
void Init_tracemonkey()
{
  JS_SetCStringsAreUTF8();

  VALUE johnson = rb_const_get(rb_mKernel, rb_intern("Johnson"));
  VALUE tracemonkey = rb_define_module_under(johnson, "TraceMonkey");
  
  init_Johnson_TraceMonkey_Context(tracemonkey);
  init_Johnson_TraceMonkey_Proxy(tracemonkey);
  init_Johnson_TraceMonkey_Debugger(tracemonkey);
  init_Johnson_TraceMonkey_Immutable_Node(tracemonkey);
  init_Johnson_TraceMonkey_Runtime(tracemonkey);
  
  rb_define_const(tracemonkey, "VERSION",
    rb_obj_freeze(rb_str_new2(JS_GetImplementationVersion())));
}
