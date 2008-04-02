#include "ruby_proxy.h"

static VALUE proxy_class = Qnil;

static VALUE /* [] */
get(VALUE self, VALUE name)
{
  Check_Type(name, T_STRING);
  
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  jsval js_value;  
  
  assert(JS_GetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), StringValuePtr(name), &js_value));
  
  return convert_to_ruby(proxy->context, js_value);
}

static VALUE /* []= */
set(VALUE self, VALUE name, VALUE value)
{
  Check_Type(name, T_STRING);
  
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  jsval js_value = convert_to_js(proxy->context, value);
  
  assert(JS_SetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), StringValuePtr(name), &js_value));
  
  return value;
}

static VALUE /* function? */
function_p(VALUE self)
{
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  return JS_TypeOfValue(proxy->context->js, proxy->value) == JSTYPE_FUNCTION;
}

static VALUE /* respond_to?(sym) */
respond_to_p(VALUE self, VALUE sym)
{
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  char* name = rb_id2name(SYM2ID(sym));
  
  // assignment is always okay
  if (name[strlen(name) - 1] == '=')
    return Qtrue;
  
  JSObject *obj;
  JSBool found;
  
  assert(JS_ValueToObject(proxy->context->js, proxy->value, &obj));
  assert(JS_HasProperty(proxy->context->js, obj, name, &found));

  return found ? Qtrue : rb_call_super(1, &sym);
}

static VALUE
call(int argc, VALUE* argv, VALUE self)
{
  if (!function_p(self))
    Johnson_Error_raise("This Johnson::SpiderMonkey::Proxy isn't a function.");

  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  jsval args[argc];  
  int i;

  for(i = 0; i < argc; ++i)
    args[i] = convert_to_js(proxy->context, argv[i]);
  
  jsval js;
  
  assert(JS_CallFunctionValue(proxy->context->js,
    proxy->context->global, proxy->value, argc, args, &js));
  
  return convert_to_ruby(proxy->context, js);
}

static VALUE /* each(&block) */ 
each(VALUE self)
{
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  JSObject* value = JSVAL_TO_OBJECT(proxy->value);
  
  // arrays behave like you'd expect, indexes in order
  if (JS_IsArrayObject(proxy->context->js, value))
  {
    jsuint length;
    assert(JS_GetArrayLength(proxy->context->js, value, &length));
    
    int i = 0;
    for (i = 0; i < length; ++i)
    {
      jsval element;
      assert(JS_GetElement(proxy->context->js, value, i, &element));  
      rb_yield(convert_to_ruby(proxy->context, element));
    }
  }
  else
  {
    // not an array? behave like each on Hash; yield [key, value]
    JSIdArray *ids = JS_Enumerate(proxy->context->js, value);
    assert(ids != NULL);
  
    int i;
    for (i = 0; i < ids->length; ++i)
    {
      jsval js_key, js_value;

      assert(JS_IdToValue(proxy->context->js, ids->vector[i], &js_key));

      if (JSVAL_IS_STRING(js_key))
      {
        // regular properties have string keys
        assert(JS_GetProperty(proxy->context->js, value,
          JS_GetStringBytes(JSVAL_TO_STRING(js_key)), &js_value));        
      }
      else
      {
        // it's a numeric property, use array access
        assert(JS_GetElement(proxy->context->js, value,
          JSVAL_TO_INT(js_key), &js_value));
      }
    
      VALUE key = convert_to_ruby(proxy->context, js_key);
      VALUE value = convert_to_ruby(proxy->context, js_value);

      rb_yield(rb_ary_new3(2, key, value));
    }
  
    JS_DestroyIdArray(proxy->context->js, ids);
  }
  
  return self; 
}

static VALUE
length(VALUE self)
{
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  JSObject* value = JSVAL_TO_OBJECT(proxy->value);
  
  if (JS_IsArrayObject(proxy->context->js, value))
  {
    jsuint length;
    assert(JS_GetArrayLength(proxy->context->js, value, &length));

    return INT2FIX(length);
  }
  else
  {
    JSIdArray *ids = JS_Enumerate(proxy->context->js, value);
    VALUE length = INT2FIX(ids->length);
    
    JS_DestroyIdArray(proxy->context->js, ids);
    return length;
  }
}

/* private */ static VALUE /* function_property?(name) */
function_property_p(VALUE self, VALUE name)
{
  Check_Type(name, T_STRING);
  
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  jsval js_value;  

  assert(JS_GetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), StringValuePtr(name), &js_value));
    
  return JS_TypeOfValue(proxy->context->js, js_value) == JSTYPE_FUNCTION;
}

/* private */ static VALUE
call_function_property(int argc, VALUE* argv, VALUE self)
{
  OurRubyProxy* proxy;
  Data_Get_Struct(self, OurRubyProxy, proxy);
  
  jsval function;
  
  assert(JS_GetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), StringValuePtr(argv[0]), &function));
  
  // should never be anything but a function
  assert(JS_TypeOfValue(proxy->context->js, function) == JSTYPE_FUNCTION);
  
  // first thing in argv is the property name; skip it
  jsval args[argc - 1];
  int i;
  
  for(i = 1; i < argc; ++i)
    args[i - 1] = convert_to_js(proxy->context, argv[i]);
    
  jsval js;
  
  assert(JS_CallFunctionValue(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), function, argc - 1, args, &js));
  
  return convert_to_ruby(proxy->context, js);
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void finalize(OurRubyProxy* proxy)
{
  // could get finalized after the context has been freed
  if (proxy->context)
  {
    // remove this proxy from the OID map
    JS_HashTableRemove(proxy->context->jsids, (void *)proxy->value);
  
    // remove our GC handle on the JS value
    char key[10];
  	sprintf(key, "%x", (int)proxy->value);
    JS_DeleteProperty(proxy->context->js, proxy->context->gcthings, key);
    
    proxy->context = 0;
  }
  
  proxy->value = 0;
  free(proxy);
}

JSBool ruby_value_is_proxy(VALUE maybe_proxy)
{
  return proxy_class == CLASS_OF(maybe_proxy); 
}

jsval unwrap_ruby_proxy(OurContext* context, VALUE wrapped)
{
  assert(ruby_value_is_proxy(wrapped));
  
  OurRubyProxy* proxy;
  Data_Get_Struct(wrapped, OurRubyProxy, proxy);
  
  return proxy->value; 
}

VALUE make_ruby_proxy(OurContext* context, jsval value)
{
  VALUE id = (VALUE)JS_HashTableLookup(context->jsids, (void *)value);
  
  if (id)
  {
    // if we already have a proxy, return it
    // FIXME: don't depend on ObjectSpace!
    return rb_funcall(rb_const_get(rb_cObject,
      rb_intern("ObjectSpace")), rb_intern("_id2ref"), 1, id);
  }
  else
  {
    // otherwise make one and cache it
    OurRubyProxy* our_proxy; 
    VALUE proxy = Data_Make_Struct(proxy_class, OurRubyProxy, 0, finalize, our_proxy);

    our_proxy->value = value;
    our_proxy->context = context;

  	// put the proxy OID in the id map
    assert(JS_HashTableAdd(context->jsids, (void *)value, (void *)rb_obj_id(proxy)));
    
    // root the value for JS GC
    char key[10];
  	sprintf(key, "%x", (int)value);
  	JS_SetProperty(context->js, context->gcthings, key, &value);
    
    return proxy;
  }
}

void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey)
{
  proxy_class = rb_define_class_under(spidermonkey, "RubyProxy", rb_cObject);

  rb_define_method(proxy_class, "[]", get, 1);
  rb_define_method(proxy_class, "[]=", set, 2);
  rb_define_method(proxy_class, "function?", function_p, 0);
  rb_define_method(proxy_class, "respond_to?", respond_to_p, 1);
  rb_define_method(proxy_class, "call", call, -1);
  rb_define_method(proxy_class, "each", each, 0);
  rb_define_method(proxy_class, "length", length, 0);

  rb_define_private_method(proxy_class, "function_property?", function_property_p, 1);
  rb_define_private_method(proxy_class, "call_function_property", call_function_property, -1);
}
