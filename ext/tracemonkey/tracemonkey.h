#ifndef JOHNSON_TRACEMONKEY_H
#define JOHNSON_TRACEMONKEY_H

#include <assert.h>
#include <stdarg.h>
#include <stdbool.h>
#include <ruby.h>

#include "jsapi.h"
#include "jshash.h"
#include "jsobj.h"
#include "jsregexp.h"

#include "jroot.h"

#ifndef StringValueLen
#define StringValueLen(v) (RSTRING(v)->len)
#endif

#ifndef UNUSED
# if defined(__GNUC__)
#  define MAYBE_UNUSED(name) name __attribute__((unused))
#  define UNUSED(name) MAYBE_UNUSED(UNUSED_ ## name)
# else
#  define MAYBE_UNUSED(name) name
#  define UNUSED(name) name
# endif
#endif

typedef VALUE(*ruby_callback)(...);

#endif
