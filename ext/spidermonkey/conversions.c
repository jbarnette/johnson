#include "conversions.h"

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

    // UNIMPLEMENTED BELOW THIS LINE

  	case T_OBJECT:
  	case T_CLASS:
  	case T_FILE:
  	case T_STRUCT:
  	case T_MODULE:
  	case T_FLOAT:
  	case T_REGEXP:
  	case T_ARRAY:
  	case T_FIXNUM:
  	case T_HASH:
  	case T_BIGNUM:
  	case T_DATA:
  	case T_SYMBOL: 
    
    default:
      Johnson_Error_raise("unknown ruby type in switch");
  }
  
  return JSVAL_NULL;
}

VALUE convert_to_ruby(OurContext* context, jsval js)
{
  switch (JS_TypeOfValue(context->js, js))
  {
    case JSTYPE_VOID:
      return Qnil;
      
    case JSTYPE_OBJECT:
      if (JSVAL_NULL == js) return Qnil;

    case JSTYPE_BOOLEAN:
      return JSVAL_TRUE == js ? Qtrue : Qfalse;
      
    case JSTYPE_STRING:
      return rb_str_new2(JS_GetStringBytes(JSVAL_TO_STRING(js)));  
      

    // UNIMPLEMENTED BELOW THIS LINE

    case JSTYPE_FUNCTION:
    case JSTYPE_NUMBER:
      
    default:
      Johnson_Error_raise("unknown js type in switch");
  }
  
  return Qnil;
}
