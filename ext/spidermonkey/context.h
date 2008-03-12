#ifndef JOHNSON_SPIDERMONKEY_CONTEXT_H
#define JOHNSON_SPIDERMONKEY_CONTEXT_H

#include "spidermonkey.h"

#define MAX_EXCEPTION_MESSAGE_SIZE 2048

typedef struct {
  JSContext *js;
  JSObject *global;
  JSRuntime *runtime;
  
  jsval ex; // an exception value
  char msg[MAX_EXCEPTION_MESSAGE_SIZE]; // the 'backup' message
  
} OurContext;

static JSClass OurGlobalClass = {
  "global", JSCLASS_NEW_RESOLVE | JSCLASS_GLOBAL_FLAGS,
  JS_PropertyStub, // addProperty
  JS_PropertyStub, // delProperty
  JS_PropertyStub, // getProperty
  JS_PropertyStub, // setProperty
  JS_EnumerateStub,
  JS_ResolveStub,
  JS_ConvertStub,
  JS_FinalizeStub
};

void init_Johnson_SpiderMonkey_Context(VALUE spidermonkey);

#endif
