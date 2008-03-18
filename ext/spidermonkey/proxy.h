#ifndef JOHNSON_SPIDERMONKEY_PROXY_H
#define JOHNSON_SPIDERMONKEY_PROXY_H

#include "spidermonkey.h"
#include "context.h"

typedef struct {
  jsval value;
  OurContext* context;
} OurRubyProxy;

VALUE make_proxy(OurContext* context, jsval value);

#endif
