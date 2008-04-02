#ifndef JOHNSON_SPIDERMONKEY_JS_FUNCTION_PROXY_H
#define JOHNSON_SPIDERMONKEY_JS_FUNCTION_PROXY_H

#include "spidermonkey.h"
#include "context.h"

#define JS_FUNCTION_PROXY_PROPERTY "__rubyProcOID"

JSBool js_value_is_function_proxy(OurContext* context, jsval maybe_function_proxy);
VALUE unwrap_js_function_proxy(OurContext* context, jsval function_proxy);
jsval make_js_function_proxy(OurContext* context, VALUE proc);

#endif
