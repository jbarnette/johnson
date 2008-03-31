#ifndef JOHNSON_SPIDERMONKEY_JS_PROXY_H
#define JOHNSON_SPIDERMONKEY_JS_PROXY_H

#include "spidermonkey.h"
#include "context.h"

JSBool js_value_is_proxy(jsval maybe_proxy);
VALUE unwrap_js_proxy(OurContext* context, jsval proxy);
jsval make_js_proxy(OurContext* context, VALUE value);

#endif
