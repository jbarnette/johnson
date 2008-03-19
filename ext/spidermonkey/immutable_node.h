#ifndef JOHNSON_SPIDERMONKEY_IMMUTABLE_NODE_H
#define JOHNSON_SPIDERMONKEY_IMMUTABLE_NODE_H

#include "spidermonkey.h"
#include "jsparse.h"
#include "jsatom.h"
#include "jsscan.h"
#include "jsarena.h"
#include "jsfun.h"
#include "jscntxt.h"

#define MAX_EXCEPTION_MESSAGE_SIZE 2048

void init_Johnson_SpiderMonkey_Immutable_Node(VALUE spidermonkey);

typedef struct {
  JSParseContext * pc;
  JSParseNode * node;
  JSContext * js;
  JSRuntime * runtime;

  jsval ex; // an exception value
  char msg[MAX_EXCEPTION_MESSAGE_SIZE]; // the 'backup' message
} ImmutableNodeContext;

#endif
