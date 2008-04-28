#ifndef JOHNSON_SPIDERMONKEY_CONVERSIONS_H
#define JOHNSON_SPIDERMONKEY_CONVERSIONS_H

#include "spidermonkey.h"
#include "context.h"

JSBool convert_to_js(OurContext* context, VALUE ruby, jsval* retval);
VALUE convert_to_ruby(OurContext* context, jsval js);
VALUE convert_jsstring_to_ruby(OurContext* context, JSString* str);

NORETURN(void raise_js_error_in_ruby(OurContext* context));
JSBool report_ruby_error_in_js(OurContext* context, int state, VALUE old_errinfo);

#endif
