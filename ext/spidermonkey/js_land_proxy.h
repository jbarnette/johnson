#ifndef JOHNSON_SPIDERMONKEY_JS_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_JS_LAND_PROXY_H

#include "spidermonkey.h"
#include "context.h"

#define JS_FUNCTION_PROXY_PROPERTY "__isProxyForRubyProc"

bool js_value_is_proxy(OurContext* context, jsval maybe_proxy);
VALUE unwrap_js_land_proxy(OurContext* context, jsval proxy);
JSBool make_js_land_proxy(OurContext* context, VALUE value, jsval* retval);

// FIXME: WTF
#include "node.h"
typedef struct {
  VALUE klass, rklass;
  VALUE recv;
  ID id, oid;
  int safe_level;
  NODE *body;
} METHOD;

#endif
