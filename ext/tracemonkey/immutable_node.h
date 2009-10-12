#ifndef JOHNSON_TRACEMONKEY_IMMUTABLE_NODE_H
#define JOHNSON_TRACEMONKEY_IMMUTABLE_NODE_H

#include "tracemonkey.h"
#include "jscntxt.h"
#include "jsparse.h"
#include "jsatom.h"
#include "jsscan.h"
#include "jsarena.h"
#include "jsfun.h"

typedef struct {
  JSCompiler * pc;
  JSParseNode * node;
  JSContext * js;
  JSRuntime * runtime;
} ImmutableNodeContext;

VALUE jsop_to_symbol(JSUint32 jsop);
void init_Johnson_TraceMonkey_Immutable_Node(VALUE tracemonkey);

#endif
