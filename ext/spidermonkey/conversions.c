#include "conversions.h"
#include "proxy.h"

static jsval convert_float_or_bignum_to_js(OurContext* context, VALUE float_or_bignum)
{
  jsval js;
  assert(JS_NewDoubleValue(context->js, NUM2DBL(float_or_bignum), &js));
  return js;
}

static jsval convert_symbol_to_js(OurContext* context, VALUE symbol)
{
  VALUE to_s = rb_funcall(symbol, rb_intern("to_s"), 0);
  jsval name = STRING_TO_JSVAL(JS_NewStringCopyZ(context->js, StringValuePtr(to_s)));

  // calls Ruby.symbolize(name) in JS-land. See prelude.js.

  jsval nsRuby;    
  assert(JS_GetProperty(context->js, context->global, "Ruby", &nsRuby) || JSVAL_VOID == nsRuby);

  jsval js = JSVAL_NULL;    
  assert(JS_CallFunctionName(context->js, JSVAL_TO_OBJECT(nsRuby), "symbolize", 1, &name, &js));

  return js;
}

jsval convert_to_js(OurContext* context, VALUE ruby)
{
  switch(TYPE(ruby))
  {
    case T_NIL:
      return JSVAL_NULL;

  	case T_TRUE:
      return JSVAL_TRUE;
    
  	case T_FALSE:
      return JSVAL_FALSE;

  	case T_STRING:
  	  return STRING_TO_JSVAL(JS_NewStringCopyZ(context->js, StringValuePtr(ruby)));

  	case T_FIXNUM:
    	return INT_TO_JSVAL(NUM2INT(ruby));

  	case T_FLOAT:
  	case T_BIGNUM:
      return convert_float_or_bignum_to_js(context, ruby);

    case T_SYMBOL:
      return convert_symbol_to_js(context, ruby);
      
    // UNIMPLEMENTED BELOW THIS LINE

  	case T_OBJECT:
  	case T_CLASS:
  	case T_FILE:
  	case T_STRUCT:
  	case T_MODULE:
  	case T_REGEXP:
  	case T_ARRAY:
  	case T_HASH:
  	case T_DATA:
    
    default:
      Johnson_Error_raise("unknown ruby type in switch");
  }
  
  return JSVAL_NULL;
}

static JSBool jsval_is_a_symbol(OurContext* context, jsval maybe_symbol)
{
  jsval nsRuby, cSymbol;

  assert(JS_GetProperty(context->js, context->global, "Ruby", &nsRuby));
  if(JSVAL_VOID == nsRuby) Johnson_Error_raise("aaaaaaaugh!");
  
  assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(nsRuby), "Symbol", &cSymbol));
  assert(JSVAL_VOID != cSymbol);
  
  JSBool is_a_symbol;
  assert(JS_HasInstance(context->js, JSVAL_TO_OBJECT(cSymbol), maybe_symbol, &is_a_symbol));

  return is_a_symbol;
}


VALUE convert_to_ruby(OurContext* context, jsval js)
{
  switch (JS_TypeOfValue(context->js, js))
  {
    case JSTYPE_VOID:
      return Qnil;
      
    case JSTYPE_FUNCTION:  
    case JSTYPE_OBJECT:
      if (JSVAL_NULL == js) return Qnil;
      
      if (jsval_is_a_symbol(context, js))
        return ID2SYM(rb_intern(JS_GetStringBytes(JS_ValueToString(context->js, js))));
      
      VALUE id = (VALUE)JS_HashTableLookup(context->ids, (void *)js);
      
      if (id)
      {
        // if we already have a proxy, return it
        return rb_funcall(rb_const_get(rb_cObject,
          rb_intern("ObjectSpace")), rb_intern("_id2ref"), 1, id);
      }
      else
      {
        // otherwise make one and cache it
        VALUE proxy = make_proxy(context, js); 
        
      	// put the proxy OID in the id map
        assert(JS_HashTableAdd(context->ids, (void *)js, (void *)rb_obj_id(proxy)));
        
        // root the value for JS GC
        char key[10];
      	sprintf(key, "%x", (int)js);
      	JS_SetProperty(context->js, context->gcthings, key, &js);
        
        return proxy;
      }
        
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
