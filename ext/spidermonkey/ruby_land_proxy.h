#ifndef JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H

#include "spidermonkey.h"
#include "runtime.h"

typedef struct {
  void* key;
  JohnsonRuntime* runtime;
} RubyLandProxy;

bool ruby_value_is_proxy(VALUE maybe_proxy);
JSBool unwrap_ruby_land_proxy(JohnsonRuntime* runtime, VALUE proxy, jsval* retval);
VALUE make_ruby_land_proxy(JohnsonRuntime* runtime, jsval value);
void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey);

#endif
