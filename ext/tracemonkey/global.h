#ifndef JOHNSON_SPIDERMONKEY_GLOBAL_H
#define JOHNSON_SPIDERMONKEY_GLOBAL_H

#include "spidermonkey.h"
#include "context.h"
#include "runtime.h"

// NOTE: one of the FEW places a context should be passed around
JSObject* johnson_create_global_object(JSContext* context);

#endif
