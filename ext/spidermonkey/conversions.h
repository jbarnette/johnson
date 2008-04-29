#ifndef JOHNSON_SPIDERMONKEY_CONVERSIONS_H
#define JOHNSON_SPIDERMONKEY_CONVERSIONS_H

#include "spidermonkey.h"
#include "context.h"

DECLARE_RUBY_WRAPPER(convert_to_ruby, OurContext* context; jsval js_value)
#define CONVERT_TO_RUBY(context, js) CALL_RUBY_WRAPPER(convert_to_ruby, context, js)

JSBool convert_to_js(OurContext* context, VALUE ruby, jsval* retval);
VALUE convert_to_ruby(OurContext* context, jsval js);
VALUE convert_jsstring_to_ruby(OurContext* context, JSString* str);

NORETURN(void raise_js_error_in_ruby(OurContext* context));
JSBool report_ruby_error_in_js(OurContext* context, int state, VALUE old_errinfo);

#endif
