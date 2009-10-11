#ifndef JOHNSON_SPIDERMONKEY_DEBUGGER_H
#define JOHNSON_SPIDERMONKEY_DEBUGGER_H

#include "spidermonkey.h"
#include "jsdbgapi.h"

void init_Johnson_SpiderMonkey_Debugger(VALUE spidermonkey);
bool ruby_value_is_debugger(VALUE maybe_debugger);

#endif
