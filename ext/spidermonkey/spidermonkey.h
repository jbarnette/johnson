#ifndef JOHNSON_SPIDERMONKEY_H
#define JOHNSON_SPIDERMONKEY_H

#include <assert.h>
#include <stdio.h>
#include <stdbool.h>

#include <ruby.h>
#include "jsapi.h"
#include "jshash.h"
#include "jsregexp.h"

#ifndef StringValueLen
#define StringValueLen(v) (RSTRING(v)->len)
#endif

#endif
