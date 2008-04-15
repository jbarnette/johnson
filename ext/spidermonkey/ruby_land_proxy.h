#ifndef JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H
#define JOHNSON_SPIDERMONKEY_RUBY_LAND_PROXY_H

#include "spidermonkey.h"
#include "context.h"

typedef struct {
  jsval value;
  OurContext* context;
} RubyLandProxy;

JSBool ruby_value_is_proxy(VALUE maybe_proxy);
jsval unwrap_ruby_land_proxy(OurContext* context, VALUE proxy);
VALUE make_ruby_land_proxy(OurContext* context, jsval value);

#endif
