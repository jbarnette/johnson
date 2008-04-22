#ifndef JOHNSON_SPIDERMONKEY_CONTEXT_H
#define JOHNSON_SPIDERMONKEY_CONTEXT_H

#include "spidermonkey.h"

#define MAX_EXCEPTION_MESSAGE_SIZE 2048

typedef struct {
  JSContext *js;
  JSObject *global;
  JSRuntime *runtime;
  
  JSHashTable *jsids; // jsid -> rbid
  JSHashTable *rbids; // rbid -> jsid
  JSObject *gcthings;
  
  jsval ex; // an exception value
  char msg[MAX_EXCEPTION_MESSAGE_SIZE]; // the 'backup' message
  
} OurContext;

void init_Johnson_SpiderMonkey_Context(VALUE spidermonkey);
VALUE Johnson_SpiderMonkey_JSLandProxy();

#endif
