#ifndef JOHNSON_TRACEMONKEY_CONVERSIONS_H
#define JOHNSON_TRACEMONKEY_CONVERSIONS_H

#include "tracemonkey.h"
#include "context.h"
#include "runtime.h"

DECLARE_RUBY_WRAPPER(convert_to_ruby, JohnsonRuntime* runtime; jsval js_value)
#define CONVERT_TO_RUBY(runtime, js) CALL_RUBY_WRAPPER(convert_to_ruby, runtime, js)

DECLARE_RUBY_WRAPPER(convert_js_string_to_ruby, JohnsonRuntime* runtime; JSString* str)
#define CONVERT_JS_STRING_TO_RUBY(runtime, js) CALL_RUBY_WRAPPER(convert_js_string_to_ruby, runtime, js)

DECLARE_RUBY_WRAPPER(rb_funcall_0, VALUE obj; ID sym; int argc)
#define RB_FUNCALL_0(obj, sym) CALL_RUBY_WRAPPER(rb_funcall_0, obj, sym, 0)
#define RB_FUNCALL_0T(obj, sym, T) CALL_RUBY_WRAPPER_T(rb_funcall_0, T, obj, sym, 0)
DECLARE_RUBY_WRAPPER(rb_funcall_1, VALUE obj; ID sym; int argc; VALUE a)
#define RB_FUNCALL_1(obj, sym, a) CALL_RUBY_WRAPPER(rb_funcall_1, obj, sym, 1, a)
DECLARE_RUBY_WRAPPER(rb_funcall_2, VALUE obj; ID sym; int argc; VALUE a; VALUE b)
#define RB_FUNCALL_2(obj, sym, a, b) CALL_RUBY_WRAPPER(rb_funcall_2, obj, sym, 2, a, b)

DECLARE_RUBY_WRAPPER(rb_intern, const char* name)
#define RB_INTERN(name) CALL_RUBY_WRAPPER(rb_intern, name)

JSBool convert_to_js(JohnsonRuntime* runtime, VALUE ruby, jsval* retval);
VALUE convert_to_ruby(JohnsonRuntime* runtime, jsval js);
VALUE convert_js_string_to_ruby(JohnsonRuntime* runtime, JSString* str);

NORETURN(void raise_js_error_in_ruby(JohnsonRuntime* runtime));
JSBool report_ruby_error_in_js(JohnsonRuntime* runtime, int state, VALUE old_errinfo);

#endif
