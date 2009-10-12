#ifndef JOHNSON_TRACEMONKEY_CONTEXT_H
#define JOHNSON_TRACEMONKEY_CONTEXT_H

#include "tracemonkey.h"

#define MAX_EXCEPTION_MESSAGE_SIZE 2048L

typedef struct {
  JSContext *js;
  
  jsval ex; // an exception value
  char msg[MAX_EXCEPTION_MESSAGE_SIZE]; // the 'backup' message
  
} JohnsonContext;

void init_Johnson_TraceMonkey_Context(VALUE tracemonkey);
VALUE Johnson_TraceMonkey_JSLandProxy();

#endif
