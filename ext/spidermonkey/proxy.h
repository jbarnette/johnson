#ifndef JOHNSON_SPIDERMONKEY_PROXY_H
#define JOHNSON_SPIDERMONKEY_PROXY_H

#include "spidermonkey.h"
#include "context.h"

#endif

typedef struct {
  jsval value;
  OurContext* context;
} OurRubyProxy;
