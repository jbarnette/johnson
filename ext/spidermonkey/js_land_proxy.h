#ifndef JOHNSON_SPIDERMONKEY_JS_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_JS_LAND_PROXY_H

#include "spidermonkey.h"
#include "context.h"

bool js_value_is_proxy(OurContext* context, jsval maybe_proxy);
VALUE unwrap_js_land_proxy(OurContext* context, jsval proxy);
JSBool make_js_land_proxy(OurContext* context, VALUE value, jsval* retval);

#include "node.h"
typedef struct {
  VALUE klass, rklass;
  VALUE recv;
  ID id, oid;
  int safe_level;
  NODE *body;
} METHOD;

#endif
