#ifndef JOHNSON_SPIDERMONKEY_PROXY_H
#define JOHNSON_SPIDERMONKEY_PROXY_H

#include "spidermonkey.h"
#include "context.h"

typedef struct {
  jsval value;
  OurContext* context;
} OurRubyProxy;

JSBool ruby_value_is_proxy(VALUE maybe_proxy);
jsval unwrap_proxy(OurContext* context, VALUE proxy);
VALUE make_proxy(OurContext* context, jsval value);

#endif
