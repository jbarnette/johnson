#ifndef JOHNSON_TRACEMONKEY_PROXY_H
#define JOHNSON_TRACEMONKEY_PROXY_H

#include "tracemonkey.h"
#include "context.h"
#include "runtime.h"

// NOTE: one of the FEW places a context should be passed around
JSObject* johnson_create_proxy_object(JSContext* context, JSObject* target);
void johnson_set_proxy_target(JSContext* context, JSObject* proxy, JSObject* target);

#endif
