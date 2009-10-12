#ifndef JOHNSON_TRACEMONKEY_JS_LAND_PROXY_H
#define JOHNSON_TRACEMONKEY_JS_LAND_PROXY_H

#include "tracemonkey.h"
#include "runtime.h"

bool js_value_is_proxy(JohnsonRuntime* runtime, jsval maybe_proxy);
VALUE unwrap_js_land_proxy(JohnsonRuntime* runtime, jsval proxy);
JSBool make_js_land_proxy(JohnsonRuntime* runtime, VALUE value, jsval* retval);

#include "node.h"
typedef struct {
  VALUE klass, rklass;
  VALUE recv;
  ID id, oid;
  int safe_level;
  NODE *body;
} METHOD;

#endif
