#ifndef JOHNSON_TRACEMONKEY_SPLIT_GLOBAL_H
#define JOHNSON_TRACEMONKEY_SPLIT_GLOBAL_H

#include "tracemonkey.h"
#include "context.h"
#include "runtime.h"

JSObject* johnson_create_split_global_outer_object(JSContext* cx);
JSObject* johnson_create_split_global_inner_object(JSContext* cx, JSObject* outer);

JSObject* split_create_outer(JSContext *cx);
JSObject* split_create_inner(JSContext *cx, JSObject *outer);

#endif
