#ifndef JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H

#include "spidermonkey.h"
#include "runtime.h"

#ifdef LEAK_ROOT_NAMES
#define LEAKY_ROOT_NAME(static_string, dynamic_detail) \
  ({\
    const char * const _leaky_root__detail = (dynamic_detail);\
    char * _leaky_root__leaked = malloc(strlen(static_string) + strlen(_leaky_root__detail) + 2);\
    strcpy(_leaky_root__leaked, static_string);\
    _leaky_root__leaked[strlen(static_string)] = ':';\
    strcpy(_leaky_root__leaked + strlen(static_string) + 1, _leaky_root__detail);\
    _leaky_root__leaked;\
  })
#else
#define LEAKY_ROOT_NAME(static_string, dynamic_detail) (static_string)
#endif

typedef struct {
  void* key;
  JohnsonRuntime* runtime;
  VALUE self;
} RubyLandProxy;

bool ruby_value_is_proxy(VALUE maybe_proxy);
bool ruby_value_is_script_proxy(VALUE maybe_proxy);
JSBool unwrap_ruby_land_proxy(JohnsonRuntime* runtime, VALUE proxy, jsval* retval);
VALUE make_ruby_land_proxy(JohnsonRuntime* runtime, jsval value, const char const* root_name);
void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey);

#endif
