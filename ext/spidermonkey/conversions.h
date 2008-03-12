#ifndef JOHNSON_SPIDERMONKEY_CONVERSIONS_H
#define JOHNSON_SPIDERMONKEY_CONVERSIONS_H

#include "spidermonkey.h"
#include "context.h"

jsval convert_to_js(OurContext* context, VALUE ruby);
VALUE convert_to_ruby(OurContext* context, jsval js);

#endif
