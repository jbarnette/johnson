#include "proxy.h"

static VALUE proxy_class = Qnil;

static VALUE /* [] */
get(VALUE self, VALUE name)
{
  // FIXME: support lookup by symbol
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
  // FIXME: support lookup by symbol
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
  
  // FIXME: exception handling here

  jsval js;
  
  assert(JS_CallFunctionValue(proxy->context->js,
    proxy->context->global, proxy->value, argc, args, &js));
  
  return convert_to_ruby(proxy->context, js);
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
    
  // FIXME: exception handling here
  
  jsval js;
  
  assert(JS_CallFunctionValue(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), function, argc - 1, args, &js));
  
  return convert_to_ruby(proxy->context, js);
}

/* private */ static VALUE
initialize(VALUE self)
{
  return Johnson_Error_raise("Johnson::SpiderMonkey::Proxy is an internal support class.");
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void deallocate(OurRubyProxy* proxy)
{
  // could get finalized after the context has been freed
  if (proxy->context)
  {
    // remove this proxy from the OID map
    JS_HashTableRemove(proxy->context->ids, (void *)proxy->value);
  
    // remove our GC handle on the JS value
    char key[10];
  	sprintf(key, "%x", (int)proxy->value);
    JS_DeleteProperty(proxy->context->js, proxy->context->gcthings, key);
    
    proxy->context = 0;
  }
  
  proxy->value = 0;
  free(proxy);
}

VALUE make_proxy(OurContext* context, jsval value)
{
  OurRubyProxy* proxy; 
  VALUE rbproxy = Data_Make_Struct(proxy_class, OurRubyProxy, 0, deallocate, proxy);
  
  proxy->value = value;
  proxy->context = context;
  
  return rbproxy;
}

void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey)
{
  proxy_class = rb_define_class_under(spidermonkey, "Proxy", rb_cObject);

  rb_define_method(proxy_class, "[]", get, 1);
  rb_define_method(proxy_class, "[]=", set, 2);
  rb_define_method(proxy_class, "function?", function_p, 0);
  rb_define_method(proxy_class, "respond_to?", respond_to_p, 1);
  rb_define_method(proxy_class, "call", call, -1);

  rb_define_private_method(proxy_class, "initialize", initialize, 0);
  rb_define_private_method(proxy_class, "function_property?", function_property_p, 1);
  rb_define_private_method(proxy_class, "call_function_property", call_function_property, -1);
}
