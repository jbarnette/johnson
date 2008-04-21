#ifndef JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H

#include "spidermonkey.h"
#include "context.h"

typedef struct {
  jsval value;
  OurContext* context;
} RubyLandProxy;

JSBool ruby_value_is_proxy(VALUE maybe_proxy);
JSBool unwrap_ruby_land_proxy(OurContext* context, VALUE proxy, jsval* retval);
VALUE make_ruby_land_proxy(OurContext* context, jsval value);
void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey);

#endif
