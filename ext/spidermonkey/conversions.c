#include "conversions.h"
#include "js_land_proxy.h"
#include "ruby_land_proxy.h"
#include "error.h"

static JSBool convert_float_or_bignum_to_js(OurContext* context, VALUE float_or_bignum, jsval* retval)
{
  return JS_NewDoubleValue(context->js, NUM2DBL(float_or_bignum), retval);
}

static JSBool convert_symbol_to_js(OurContext* context, VALUE symbol, jsval* retval)
{
  PREPARE_JROOTS(context, "convert_symbol_to_js", 2);

  VALUE to_s = rb_funcall(symbol, rb_intern("to_s"), 0);
  jsval name = STRING_TO_JSVAL(JS_NewStringCopyN(context->js, StringValuePtr(to_s), (unsigned) StringValueLen(to_s)));

  JROOT(name);

  // calls Johnson.symbolize(name) in JS-land. See lib/prelude.js

  jsval nsJohnson;    
  JCHECK(JS_GetProperty(context->js, context->global, "Johnson", &nsJohnson));
  JROOT(nsJohnson);

  JCHECK(JS_CallFunctionName(context->js, JSVAL_TO_OBJECT(nsJohnson), "symbolize", 1, &name, retval));

  JRETURN;
}

static JSBool convert_regexp_to_js(OurContext* context, VALUE regexp, jsval* retval)
{
  VALUE source = rb_funcall(regexp, rb_intern("source"), 0);
  int options = NUM2INT(rb_funcall(regexp, rb_intern("options"), 0));

  JSObject* obj = JS_NewRegExpObject(context->js,
        StringValuePtr(source),
        (unsigned) StringValueLen(source),
        (unsigned) options);

  if (obj) {
    *retval = OBJECT_TO_JSVAL(obj);
    return JS_TRUE;
  } else {
    return JS_FALSE;
  }
}

JSBool convert_to_js(OurContext* context, VALUE ruby, jsval* retval)
{
  switch(TYPE(ruby))
  {
    case T_NIL:
      *retval = JSVAL_NULL;
      return JS_TRUE;

    case T_TRUE:
      *retval = JSVAL_TRUE;
      return JS_TRUE;
    
    case T_FALSE:
      *retval = JSVAL_FALSE;
      return JS_TRUE;

    case T_STRING:
      {
        JSString* str = JS_NewStringCopyN(context->js, StringValuePtr(ruby), (unsigned) StringValueLen(ruby));
        if (str) {
          *retval = STRING_TO_JSVAL(str);
          return JS_TRUE;
        } else {
          return JS_FALSE;
        }
      }

    case T_FIXNUM:
      *retval = INT_TO_JSVAL(NUM2INT(ruby));
      return JS_TRUE;

    case T_FLOAT:
    case T_BIGNUM:
      return convert_float_or_bignum_to_js(context, ruby, retval);

    case T_SYMBOL:
      return convert_symbol_to_js(context, ruby, retval);

    case T_CLASS:
    case T_ARRAY:
    case T_HASH:
    case T_MODULE:
    case T_FILE:
    case T_STRUCT:
    case T_OBJECT:
      return make_js_land_proxy(context, ruby, retval);
      
    case T_REGEXP:
      return convert_regexp_to_js(context, ruby, retval);

    case T_DATA: // HEY! keep T_DATA last for fall-through
      if (ruby_value_is_proxy(ruby))
        return unwrap_ruby_land_proxy(context, ruby, retval);

      // If we can't identify the object, just wrap it
      return make_js_land_proxy(context, ruby, retval);
    
    default:
      Johnson_Error_raise("unknown ruby type in switch");
  }
  
  *retval = JSVAL_NULL;
  return JS_TRUE;
}

VALUE convert_jsstring_to_ruby(OurContext* context, JSString* str)
{
  PREPARE_RUBY_JROOTS(context, "convert_jsstring_to_ruby", 1);
  JROOT(str);
  char* bytes = JS_GetStringBytes(str);
  assert(bytes);
  VALUE result = rb_str_new(bytes, (signed)JS_GetStringLength(str));
  JRETURN_RUBY(result);
}

static VALUE convert_regexp_to_ruby(OurContext* context, jsval regexp)
{
  PREPARE_RUBY_JROOTS(context, "convert_regexp_to_ruby", 1);
  JROOT(regexp);
  JSRegExp* re = (JSRegExp*)JS_GetPrivate(context->js, JSVAL_TO_OBJECT(regexp));

  VALUE result = rb_funcall(rb_cRegexp, rb_intern("new"), 2,
    convert_jsstring_to_ruby(context, re->source),
    INT2NUM(re->flags));

  JRETURN_RUBY(result);
}

static bool js_value_is_regexp(OurContext* context, jsval maybe_regexp)
{
  PREPARE_RUBY_JROOTS(context, "js_value_is_regexp", 1);
  JROOT(maybe_regexp);
  JSBool result = JS_InstanceOf(context->js, JSVAL_TO_OBJECT(maybe_regexp), &js_RegExpClass, NULL);
  JRETURN_RUBY(result ? true : false);
}

static bool js_value_is_symbol(OurContext* context, jsval maybe_symbol)
{
  jsval nsJohnson, cSymbol;

  PREPARE_RUBY_JROOTS(context, "js_value_is_symbol", 3);
  JROOT(maybe_symbol);

  JCHECK(JS_GetProperty(context->js, context->global, "Johnson", &nsJohnson));
  if (!JSVAL_IS_OBJECT(nsJohnson))
    JERROR("Unable to retrieve Johnson from JSLand");
  JROOT(nsJohnson);

  JCHECK(JS_GetProperty(context->js, JSVAL_TO_OBJECT(nsJohnson), "Symbol", &cSymbol));
  if (!JSVAL_IS_OBJECT(cSymbol))
    JERROR("Unable to retrieve Johnson.Symbol from JSLand");
  JROOT(cSymbol);

  JSBool is_a_symbol;
  JCHECK(JS_HasInstance(context->js, JSVAL_TO_OBJECT(cSymbol), maybe_symbol, &is_a_symbol));

  JRETURN_RUBY(is_a_symbol != JS_FALSE);
}

VALUE convert_to_ruby(OurContext* context, jsval js)
{
  if (JSVAL_NULL == js) return Qnil;

  PREPARE_RUBY_JROOTS(context, "convert_to_ruby", 1);
  
  switch (JS_TypeOfValue(context->js, js))
  {
    case JSTYPE_VOID:
      JRETURN_RUBY(Qnil);
      
    case JSTYPE_FUNCTION: 
    case JSTYPE_OBJECT:
      JROOT(js);

      if (OBJECT_TO_JSVAL(context->global) == js)
        // global gets special treatment, since the Prelude might not be loaded
        JRETURN_RUBY(make_ruby_land_proxy(context, js));
      
      // this conditional requires the Prelude
      if (js_value_is_symbol(context, js))
        JRETURN_RUBY(ID2SYM(rb_intern(JS_GetStringBytes(JS_ValueToString(context->js, js)))));
    
      if (js_value_is_proxy(context, js))
        JRETURN_RUBY(unwrap_js_land_proxy(context, js));

      if (js_value_is_regexp(context, js))
        JRETURN_RUBY(convert_regexp_to_ruby(context, js));
    
      JRETURN_RUBY(make_ruby_land_proxy(context, js));
        
    case JSTYPE_BOOLEAN:
      JRETURN_RUBY(JSVAL_TRUE == js ? Qtrue : Qfalse);
      
    case JSTYPE_STRING:
      JRETURN_RUBY(convert_jsstring_to_ruby(context, JSVAL_TO_STRING(js)));
      
    case JSTYPE_NUMBER:
      if (JSVAL_IS_INT(js)) JRETURN_RUBY(INT2FIX(JSVAL_TO_INT(js)));
      else JRETURN_RUBY(rb_float_new(*JSVAL_TO_DOUBLE(js)));

    default:
      JERROR("unknown js type in switch");
  }
  
  JRETURN_RUBY(Qnil);
}

NORETURN(void) raise_js_error_in_ruby(OurContext* context)
{
  if (JS_IsExceptionPending(context->js))
  {
    assert(JS_GetPendingException(context->js, &(context->ex)));
    JS_AddNamedRoot(context->js, &(context->ex), "raise_js_error_in_ruby");
    JS_ClearPendingException(context->js);
    JS_RemoveRoot(context->js, &(context->ex));
  }

  VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
  if (context->ex)
    rb_funcall(ruby_context, rb_intern("handle_js_exception"),
      1, convert_to_ruby(context, context->ex));

  if (!context->msg)
    Johnson_Error_raise("Unknown JavaScript Error");

  Johnson_Error_raise(context->msg);
}

