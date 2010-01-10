#ifndef JOHNSON_SPIDERMONKEY_RUNTIME_H
#define JOHNSON_SPIDERMONKEY_RUNTIME_H

#include "spidermonkey.h"

//#define LEAK_ROOT_NAMES

#define RAISE_JS_ERROR(rb_runtime, ex) \
  do {\
    JohnsonRuntime * _rt = NULL;\
    Data_Get_Struct(rb_runtime, JohnsonRuntime, _rt);\
    rb_funcall(rb_runtime, rb_intern("raise_js_exception"), 1,\
      convert_to_ruby(_rt, ex)); \
  } while(0)

typedef struct {
  JSObject* global;
  JSRuntime* js;

  JSHashTable *jsids; // jsid -> rbid
  JSHashTable *rbids; // rbid -> jsid
} JohnsonRuntime;

JSContext* johnson_get_current_context(JohnsonRuntime* runtime);
void init_Johnson_SpiderMonkey_Runtime(VALUE spidermonkey);

#endif
