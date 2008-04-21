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
  VALUE to_s = rb_funcall(symbol, rb_intern("to_s"), 0);
  jsval name = STRING_TO_JSVAL(JS_NewStringCopyN(context->js, StringValuePtr(to_s), StringValueLen(to_s)));

  // calls Johnson.symbolize(name) in JS-land. See lib/prelude.js

  jsval nsJohnson;    
  assert(JS_GetProperty(context->js, context->global, "Johnson", &nsJohnson) || JSVAL_VOID == nsJohnson);

  return JS_CallFunctionName(context->js, JSVAL_TO_OBJECT(nsJohnson), "symbolize", 1, &name, retval);
}

static JSBool convert_regexp_to_js(OurContext* context, VALUE regexp, jsval* retval)
{
  VALUE source = rb_funcall(regexp, rb_intern("source"), 0);
  int options = NUM2INT(rb_funcall(regexp, rb_intern("options"), 0));

  *retval = OBJECT_TO_JSVAL(JS_NewRegExpObject(context->js,
        StringValuePtr(source),
        StringValueLen(source),
        options));
  return JS_TRUE;
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
      *retval = STRING_TO_JSVAL(JS_NewStringCopyN(context->js, StringValuePtr(ruby), StringValueLen(ruby)));
      return JS_TRUE;

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

      if (rb_cProc == rb_class_of(ruby) || rb_cMethod == rb_class_of(ruby))
        return make_js_land_proxy(context, ruby, retval);
    
    default:
      Johnson_Error_raise("unknown ruby type in switch");
  }
  
  *retval = JSVAL_NULL;
  return JS_TRUE;
}

static VALUE convert_regexp_to_ruby(OurContext* context, jsval regexp)
{
  JSRegExp* re = (JSRegExp*)JS_GetPrivate(context->js, JSVAL_TO_OBJECT(regexp));

  return rb_funcall(rb_cRegexp, rb_intern("new"), 2,
    rb_str_new2(JS_GetStringBytes(re->source)),
    INT2NUM(re->flags));
}

static bool js_value_is_regexp(OurContext* context, jsval maybe_regexp)
{
  return JS_InstanceOf(context->js, JSVAL_TO_OBJECT(maybe_regexp), &js_RegExpClass, NULL);
}

static bool js_value_is_symbol(OurContext* context, jsval maybe_symbol)
{
  jsval nsJohnson, cSymbol;

  assert(JS_GetProperty(context->js, context->global, "Johnson", &nsJohnson));
  assert(JSVAL_VOID != nsJohnson);
  
  assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(nsJohnson), "Symbol", &cSymbol));
  assert(JSVAL_VOID != cSymbol);
  
  JSBool is_a_symbol;
  assert(JS_HasInstance(context->js, JSVAL_TO_OBJECT(cSymbol), maybe_symbol, &is_a_symbol));

  return is_a_symbol != JS_FALSE;
}

VALUE convert_to_ruby(OurContext* context, jsval js)
{
  if (JSVAL_NULL == js) return Qnil;
  
  switch (JS_TypeOfValue(context->js, js))
  {
    case JSTYPE_VOID:
      return Qnil;
      
    case JSTYPE_FUNCTION: 
    case JSTYPE_OBJECT:
      if (OBJECT_TO_JSVAL(context->global) == js)
        // global gets special treatment, since the Prelude might not be loaded
        return make_ruby_land_proxy(context, js);
      
      // this conditional requires the Prelude
      if (js_value_is_symbol(context, js))
        return ID2SYM(rb_intern(JS_GetStringBytes(JS_ValueToString(context->js, js))));
    
      if (js_value_is_proxy(context, js))
        return unwrap_js_land_proxy(context, js);

      if (js_value_is_regexp(context, js))
        return convert_regexp_to_ruby(context, js);
    
      return make_ruby_land_proxy(context, js);
        
    case JSTYPE_BOOLEAN:
      return JSVAL_TRUE == js ? Qtrue : Qfalse;
      
    case JSTYPE_STRING:
      return rb_str_new2(JS_GetStringBytes(JSVAL_TO_STRING(js)));  
      
    case JSTYPE_NUMBER:
      if (JSVAL_IS_INT(js)) return INT2FIX(JSVAL_TO_INT(js));
      else return rb_float_new(*JSVAL_TO_DOUBLE(js));

    default:
      Johnson_Error_raise("unknown js type in switch");
  }
  
  return Qnil;
}
