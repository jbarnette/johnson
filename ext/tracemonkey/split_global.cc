#include "split_global.h"

JSObject* johnson_create_split_global_outer_object(JSContext* cx)
{
  JSObject* outer = split_create_outer(cx);
  // fprintf(stderr,"outer %08x\n", outer);
  return outer;
}

JSObject* johnson_create_split_global_inner_object(JSContext* cx, JSObject* outer)
{
  // JSObject* current = JS_GetGlobalObject(cx);
  // JS_SetGlobalObject(cx, outer);
  JSObject* inner = split_create_inner(cx, outer);
  JS_ClearScope(cx, outer);
  // fprintf(stderr,"inner %08x outer %08x\n", inner, outer);
  // JS_SetGlobalObject(cx, current);
  return inner;
}
