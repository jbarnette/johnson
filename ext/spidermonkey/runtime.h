#ifndef JOHNSON_SPIDERMONKEY_RUNTIME_H
#define JOHNSON_SPIDERMONKEY_RUNTIME_H

#include "spidermonkey.h"

typedef struct {
  JSHashTable* contexts;
  JSObject* global;
  JSRuntime* js;
} JohnsonRuntime;

JSContext* johnson_get_current_context(JohnsonRuntime* runtime);
void init_Johnson_SpiderMonkey_Runtime(VALUE spidermonkey);

#endif
