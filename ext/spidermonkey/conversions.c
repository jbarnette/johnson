#include "conversions.h"
#include "js_land_proxy.h"
#include "ruby_land_proxy.h"

DEFINE_RUBY_WRAPPER(convert_to_ruby, convert_to_ruby, ARGLIST2(runtime, js_value))

DECLARE_RUBY_WRAPPER(rb_funcall_0, VALUE obj; ID sym; int argc)
DEFINE_RUBY_WRAPPER(rb_funcall_0, rb_funcall, ARGLIST3(obj, sym, argc))

DECLARE_RUBY_WRAPPER(rb_funcall_2, VALUE obj; ID sym; int argc; VALUE a; VALUE b)
DEFINE_RUBY_WRAPPER(rb_funcall_2, rb_funcall, ARGLIST5(obj, sym, argc, a, b))

static JSBool convert_float_or_bignum_to_js(JohnsonRuntime* runtime, VALUE float_or_bignum, jsval* retval)
{
  JSContext * context = johnson_get_current_context(runtime);
  return JS_NewDoubleValue(context, NUM2DBL(float_or_bignum), retval);
}

static JSBool convert_symbol_to_js(JohnsonRuntime* runtime, VALUE symbol, jsval* retval)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_JROOTS(context, 2);

  VALUE to_s = CALL_RUBY_WRAPPER(rb_funcall_0, symbol, rb_intern("to_s"), 0);
  jsval name = STRING_TO_JSVAL(JS_NewStringCopyN(context, StringValuePtr(to_s), (size_t) StringValueLen(to_s)));

  JROOT(name);

  // calls Johnson.symbolize(name) in JS-land. See lib/prelude.js

  jsval nsJohnson;    
  JCHECK(JS_GetProperty(context, runtime->global, "Johnson", &nsJohnson));
  JROOT(nsJohnson);

  JCHECK(JS_CallFunctionName(context, JSVAL_TO_OBJECT(nsJohnson), "symbolize", 1, &name, retval));

  JRETURN;
}

static JSBool convert_regexp_to_js(JohnsonRuntime* runtime, VALUE regexp, jsval* retval)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_JROOTS(context, 0);
  VALUE source = rb_funcall(regexp, rb_intern("source"), 0);
  jsint options = (jsint)(NUM2INT(rb_funcall(regexp, rb_intern("options"), 0)));

  JSObject* obj = JS_NewRegExpObject(context,
        StringValuePtr(source),
        (size_t) StringValueLen(source),
        (unsigned) options);

  JCHECK(obj);
  *retval = OBJECT_TO_JSVAL(obj);
  JRETURN;
}

JSBool convert_to_js(JohnsonRuntime* runtime, VALUE ruby, jsval* retval)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_JROOTS(context, 0);
  switch(TYPE(ruby))
  {
    case T_NIL:
      *retval = JSVAL_NULL;
      JRETURN;

    case T_TRUE:
      *retval = JSVAL_TRUE;
      JRETURN;
    
    case T_FALSE:
      *retval = JSVAL_FALSE;
      JRETURN;

    case T_STRING:
      {
        JSString* str = JS_NewStringCopyN(context, StringValuePtr(ruby), (size_t) StringValueLen(ruby));
        JCHECK(str);
        *retval = STRING_TO_JSVAL(str);
        JRETURN;
      }

    case T_FIXNUM:
      {
        long val = NUM2LONG(ruby);
        if (val >= JSVAL_INT_MIN && val <= JSVAL_INT_MAX)
        {
          *retval = INT_TO_JSVAL((jsint)val);
          JRETURN;
        }
      }

    case T_FLOAT:
    case T_BIGNUM:
      JCHECK(convert_float_or_bignum_to_js(runtime, ruby, retval));
      JRETURN;

    case T_SYMBOL:
      JCHECK(convert_symbol_to_js(runtime, ruby, retval));
      JRETURN;

    case T_CLASS:
    case T_ARRAY:
    case T_HASH:
    case T_MODULE:
    case T_FILE:
    case T_STRUCT:
    case T_OBJECT:
      JCHECK(make_js_land_proxy(runtime, ruby, retval));
      JRETURN;
      
    case T_REGEXP:
      JCHECK(convert_regexp_to_js(runtime, ruby, retval));
      JRETURN;

    case T_DATA: // HEY! keep T_DATA last for fall-through
      if (ruby_value_is_proxy(ruby))
        JCHECK(unwrap_ruby_land_proxy(runtime, ruby, retval));
      else // If we can't identify the object, just wrap it
        JCHECK(make_js_land_proxy(runtime, ruby, retval));
      JRETURN;

    default:
      JERROR("unknown ruby type in switch");
  }
  
  *retval = JSVAL_NULL;
  JRETURN;
}

VALUE convert_js_string_to_ruby(JohnsonRuntime* runtime, JSString* str)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_RUBY_JROOTS(context, 1);
  JROOT(str);
  char* bytes = JS_GetStringBytes(str);
  JCHECK(bytes);
  JRETURN_RUBY(rb_str_new(bytes, (signed long)JS_GetStringLength(str)));
}

static VALUE convert_regexp_to_ruby(JohnsonRuntime* runtime, jsval regexp)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_RUBY_JROOTS(context, 1);
  JROOT(regexp);
  JSRegExp* re = (JSRegExp*)JS_GetPrivate(context, JSVAL_TO_OBJECT(regexp));

  JRETURN_RUBY(CALL_RUBY_WRAPPER(rb_funcall_2, rb_cRegexp, rb_intern("new"), 2,
    convert_js_string_to_ruby(runtime, re->source),
    INT2NUM((long)re->flags)));
}

static bool js_value_is_regexp(JohnsonRuntime* runtime, jsval maybe_regexp)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_RUBY_JROOTS(context, 1);
  JROOT(maybe_regexp);
  JSBool result = JS_InstanceOf(context, JSVAL_TO_OBJECT(maybe_regexp), &js_RegExpClass, NULL);
  JRETURN_RUBY(result ? true : false);
}

static bool js_value_is_symbol(JohnsonRuntime* runtime, jsval maybe_symbol)
{
  jsval nsJohnson, cSymbol;
  JSContext * context = johnson_get_current_context(runtime);

  PREPARE_RUBY_JROOTS(context, 3);
  JROOT(maybe_symbol);

  JCHECK(JS_GetProperty(context, runtime->global, "Johnson", &nsJohnson));
  if (!JSVAL_IS_OBJECT(nsJohnson))
    JERROR("Unable to retrieve Johnson from JSLand");
  JROOT(nsJohnson);

  JCHECK(JS_GetProperty(context, JSVAL_TO_OBJECT(nsJohnson), "Symbol", &cSymbol));
  if (!JSVAL_IS_OBJECT(cSymbol))
    JERROR("Unable to retrieve Johnson.Symbol from JSLand");
  JROOT(cSymbol);

  JSBool is_a_symbol;
  JCHECK(JS_HasInstance(context, JSVAL_TO_OBJECT(cSymbol), maybe_symbol, &is_a_symbol));

  JRETURN_RUBY(is_a_symbol != JS_FALSE);
}

VALUE convert_to_ruby(JohnsonRuntime* runtime, jsval js)
{
  if (JSVAL_NULL == js) return Qnil;

  JSContext * context = johnson_get_current_context(runtime);

  PREPARE_RUBY_JROOTS(context, 1);
  JROOT(js);
  
  switch (JS_TypeOfValue(context, js))
  {
    case JSTYPE_VOID:
      JRETURN_RUBY(Qnil);
      
    case JSTYPE_FUNCTION: 
    case JSTYPE_OBJECT:
      if (OBJECT_TO_JSVAL(runtime->global) == js)
        // global gets special treatment, since the Prelude might not be loaded
        JRETURN_RUBY(make_ruby_land_proxy(runtime, js, "GlobalProxy"));
      
      // this conditional requires the Prelude
      if (js_value_is_symbol(runtime, js))
        JRETURN_RUBY(ID2SYM(rb_intern(JS_GetStringBytes(JS_ValueToString(context, js)))));
    
      if (js_value_is_proxy(runtime, js))
        JRETURN_RUBY(unwrap_js_land_proxy(runtime, js));

      if (js_value_is_regexp(runtime, js))
        JRETURN_RUBY(convert_regexp_to_ruby(runtime, js));
    
      JRETURN_RUBY(make_ruby_land_proxy(runtime, js, "RubyLandProxy"));
        
    case JSTYPE_BOOLEAN:
      JRETURN_RUBY(JSVAL_TRUE == js ? Qtrue : Qfalse);
      
    case JSTYPE_STRING:
      JRETURN_RUBY(convert_js_string_to_ruby(runtime, JSVAL_TO_STRING(js)));
      
    case JSTYPE_NUMBER:
      if (JSVAL_IS_INT(js)) JRETURN_RUBY(INT2FIX(JSVAL_TO_INT(js)));
      else JRETURN_RUBY(rb_float_new(*JSVAL_TO_DOUBLE(js)));

    default:
      JERROR("unknown js type in switch");
  }
  
  JRETURN_RUBY(Qnil);
}

NORETURN(void) raise_js_error_in_ruby(JohnsonRuntime* runtime)
{
  JSContext * context = johnson_get_current_context(runtime);
  JohnsonContext * johnson_context = OUR_CONTEXT(context);
  if (JS_IsExceptionPending(context))
  {
    assert(JS_GetPendingException(context, &(johnson_context->ex)));
    JS_AddNamedRoot(context, &(johnson_context->ex), "raise_js_error_in_ruby");
    JS_ClearPendingException(context);
    JS_RemoveRoot(context, &(johnson_context->ex));
  }

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(runtime->js);
  if (johnson_context->ex)
    RAISE_JS_ERROR(ruby_runtime, johnson_context->ex);

  // FIXME: I don't think this is needed, it should
  // be done on the Ruby side.
  if (!johnson_context->msg)
    rb_raise(rb_eRuntimeError, "Unknown JavaScriptError");

  // FIXME: I don't think this can ever happen....
  rb_raise(rb_eRuntimeError, johnson_context->msg);
}

#define TAG_RAISE 0x6
#define TAG_THROW 0x7

JSBool report_ruby_error_in_js(JohnsonRuntime* runtime, int state, VALUE old_errinfo)
{
  JSContext * context = johnson_get_current_context(runtime);
  assert(state);
  switch (state)
  {
    case TAG_RAISE:
      {
        VALUE local_error = ruby_errinfo;
        jsval js_err;
        ruby_errinfo = old_errinfo;
        if (!convert_to_js(runtime, local_error, &js_err))
          return JS_FALSE;
        JS_SetPendingException(context, js_err);
        return JS_FALSE;
      }

    case TAG_THROW:
      // FIXME: This should be propagated to JS... as an exception?

    default:
      {
        JSString* str = JS_NewStringCopyZ(context, "Unexpected longjmp from ruby!");
        if (str)
          JS_SetPendingException(context, STRING_TO_JSVAL(str));
        return JS_FALSE;
      }
  }
}

