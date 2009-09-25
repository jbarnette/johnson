#ifndef JOHNSON_SPIDERMONKEY_CONVERSIONS_H
#define JOHNSON_SPIDERMONKEY_CONVERSIONS_H

#include "spidermonkey.h"
#include "context.h"
#include "runtime.h"

DECLARE_RUBY_WRAPPER(convert_to_ruby, JohnsonRuntime* runtime; jsval js_value)
#define CONVERT_TO_RUBY(runtime, js) CALL_RUBY_WRAPPER(convert_to_ruby, runtime, js)

DECLARE_RUBY_WRAPPER(convert_js_string_to_ruby, JohnsonRuntime* runtime; JSString* str)
#define CONVERT_JS_STRING_TO_RUBY(runtime, js) CALL_RUBY_WRAPPER(convert_js_string_to_ruby, runtime, js)

JSBool convert_to_js(JohnsonRuntime* runtime, VALUE ruby, jsval* retval);
VALUE convert_to_ruby(JohnsonRuntime* runtime, jsval js);
VALUE convert_js_string_to_ruby(JohnsonRuntime* runtime, JSString* str);

NORETURN(void raise_js_error_in_ruby(JohnsonRuntime* runtime));
JSBool report_ruby_error_in_js(JohnsonRuntime* runtime, int state, VALUE old_errinfo);

#endif
