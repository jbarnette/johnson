#ifndef JOHNSON_SPIDERMONKEY_JS_PROXY_H
#define JOHNSON_SPIDERMONKEY_JS_PROXY_H

#include "spidermonkey.h"
#include "context.h"

jsval make_js_proxy(OurContext* context, VALUE value);

#endif
