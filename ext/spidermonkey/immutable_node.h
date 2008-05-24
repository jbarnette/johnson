#ifndef JOHNSON_SPIDERMONKEY_IMMUTABLE_NODE_H
#define JOHNSON_SPIDERMONKEY_IMMUTABLE_NODE_H

#include "spidermonkey.h"
#include "jsparse.h"
#include "jsatom.h"
#include "jsscan.h"
#include "jsarena.h"
#include "jsfun.h"
#include "jscntxt.h"

typedef struct {
  JSParseContext * pc;
  JSParseNode * node;
  JSContext * js;
  JSRuntime * runtime;
} ImmutableNodeContext;

VALUE jsop_to_symbol(JSUint32 jsop);
void init_Johnson_SpiderMonkey_Immutable_Node(VALUE spidermonkey);

#endif
