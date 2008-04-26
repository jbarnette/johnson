#ifndef JOHNSON_SPIDERMONKEY_ERROR_H
#define JOHNSON_SPIDERMONKEY_ERROR_H

#include "spidermonkey.h"

void init_Johnson_Error(VALUE johnson);
NORETURN(VALUE Johnson_Error_raise(const char* message));

#endif
