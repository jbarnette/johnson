#include "proxy.h"

static VALUE proxy_class = Qnil;

static VALUE get(VALUE self, VALUE name)
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

static VALUE set(VALUE self, VALUE name, VALUE value)
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

static VALUE initialize(VALUE self)
{
  return Johnson_Error_raise("Johnson::SpiderMonkey::Proxy is an internal support class.");
}

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

VALUE proxify(OurContext* context, jsval value)
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
  rb_define_private_method(proxy_class, "initialize", initialize, 0);
  
  rb_define_method(proxy_class, "[]", get, 1);
  rb_define_method(proxy_class, "[]=", set, 2);  
}
