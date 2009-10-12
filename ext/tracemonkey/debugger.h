#ifndef JOHNSON_TRACEMONKEY_DEBUGGER_H
#define JOHNSON_TRACEMONKEY_DEBUGGER_H

#include "tracemonkey.h"
#include "jsdbgapi.h"

void init_Johnson_TraceMonkey_Debugger(VALUE tracemonkey);
bool ruby_value_is_debugger(VALUE maybe_debugger);

#endif
