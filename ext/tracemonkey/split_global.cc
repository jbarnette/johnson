#include "split_global.h"

JSObject* johnson_create_split_global_outer_object(JSContext* cx)
{
  JSObject* outer = split_create_outer(cx);
  return outer;
}

JSObject* johnson_create_split_global_inner_object(JSContext* cx, JSObject* outer)
{
  JSObject* inner = split_create_inner(cx, outer);
  JS_ClearScope(cx, outer);
  return inner;
}
