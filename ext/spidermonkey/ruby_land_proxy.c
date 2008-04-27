#include "ruby_land_proxy.h"
#include "conversions.h"
#include "error.h"

static VALUE proxy_class = Qnil;

static VALUE call_js_function_value(OurContext* context, jsval target, jsval function, int argc, VALUE* argv)
{
  PREPARE_RUBY_JROOTS(context, "call_js_function_value", argc + 2);

  JROOT(target);
  JROOT(function);

  assert(JSVAL_IS_OBJECT(target));

  jsval args[argc];
  jsval result;

  int i;
  for(i = 0; i < argc; ++i)
  {
    JCHECK(convert_to_js(context, argv[i], &(args[i])));
    JROOT(args[i]);
  }

  JCHECK(JS_CallFunctionValue(context->js,
    JSVAL_TO_OBJECT(target), function, (unsigned) argc, args, &result));

  JRETURN_RUBY(convert_to_ruby(context, result));
}

static VALUE /* [] */
get(VALUE self, VALUE name)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, "get", 1);

  JROOT(proxy->value);

  jsval js_value;  

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_GetElement(proxy->context->js,
          JSVAL_TO_OBJECT(proxy->value), NUM2INT(name), &js_value));
      break;
    default:
      Check_Type(name, T_STRING);
      JCHECK(JS_GetProperty(proxy->context->js,
          JSVAL_TO_OBJECT(proxy->value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(convert_to_ruby(proxy->context, js_value));
}

static VALUE /* []= */
set(VALUE self, VALUE name, VALUE value)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, "set", 2);
  JROOT(proxy->value);

  jsval js_value;
  JCHECK(convert_to_js(proxy->context, value, &js_value));
  
  JROOT(js_value);

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_SetElement(proxy->context->js,
              JSVAL_TO_OBJECT(proxy->value), NUM2INT(name), &js_value));
      break;
    default:
      Check_Type(name, T_STRING);
      JCHECK(JS_SetProperty(proxy->context->js,
            JSVAL_TO_OBJECT(proxy->value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(value);
}

static VALUE /* function? */
function_p(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  return JS_TypeOfValue(proxy->context->js, proxy->value) == JSTYPE_FUNCTION;
}

static VALUE /* respond_to?(sym) */
respond_to_p(VALUE self, VALUE sym)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, "respond_to_p", 2);
  
  char* name = rb_id2name(SYM2ID(sym));
  
  // assignment is always okay
  if (name[strlen(name) - 1] == '=')
    JRETURN_RUBY(Qtrue);
  
  JROOT(proxy->value);

  JSObject *obj;
  JSBool found;
  
  JCHECK(JS_ValueToObject(proxy->context->js, proxy->value, &obj));
  JROOT(obj);

  JCHECK(JS_HasProperty(proxy->context->js, obj, name, &found));

  JRETURN_RUBY(found ? Qtrue : rb_call_super(1, &sym));
}

/* private */ static VALUE /* native_call(global, *args) */
native_call(int argc, VALUE* argv, VALUE self)
{
  if (!function_p(self))
    Johnson_Error_raise("This Johnson::SpiderMonkey::RubyLandProxy isn't a function.");

  if (argc < 1)
    rb_raise(rb_eArgError, "Target object required");

  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, "native_call", 1);
  JROOT(proxy->value);

  jsval global;
  JCHECK(convert_to_js(proxy->context, argv[0], &global));

  JRETURN_RUBY(call_js_function_value(proxy->context, global, proxy->value, argc - 1, &(argv[1])));
}

static VALUE /* each(&block) */ 
each(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, "each", 4);
  JROOT(proxy->value);

  JSObject* value = JSVAL_TO_OBJECT(proxy->value);
  JROOT(value);
  
  // arrays behave like you'd expect, indexes in order
  if (JS_IsArrayObject(proxy->context->js, value))
  {
    jsuint length;
    JCHECK(JS_GetArrayLength(proxy->context->js, value, &length));
    
    jsuint i = 0;
    for (i = 0; i < length; ++i)
    {
      jsval element;
      JCHECK(JS_GetElement(proxy->context->js, value, (signed) i, &element));
      rb_yield(convert_to_ruby(proxy->context, element));
    }
  }
  else
  {
    // not an array? behave like each on Hash; yield [key, value]
    JSIdArray *ids = JS_Enumerate(proxy->context->js, value);
    JCHECK(ids);

    // FIXME: We leak ids if something goes wrong inside this loop...
  
    int i;
    for (i = 0; i < ids->length; ++i)
    {
      jsval js_key, js_value;

      JCHECK(JS_IdToValue(proxy->context->js, ids->vector[i], &js_key));
      JROOT(js_key);

      if (JSVAL_IS_STRING(js_key))
      {
        // regular properties have string keys
        JCHECK(JS_GetProperty(proxy->context->js, value,
          JS_GetStringBytes(JSVAL_TO_STRING(js_key)), &js_value));
      }
      else
      {
        // it's a numeric property, use array access
        JCHECK(JS_GetElement(proxy->context->js, value,
          JSVAL_TO_INT(js_key), &js_value));
      }
      JROOT(js_value);

      VALUE key = convert_to_ruby(proxy->context, js_key);
      VALUE value = convert_to_ruby(proxy->context, js_value);

      rb_yield(rb_ary_new3(2, key, value));

      JUNROOT(js_value);
      JUNROOT(js_key);
    }
  
    JS_DestroyIdArray(proxy->context->js, ids);
  }

  JRETURN_RUBY(self);
}

static VALUE
length(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, "length", 2);
  
  JROOT(proxy->value);

  JSObject* value = JSVAL_TO_OBJECT(proxy->value);
  JROOT(value);
  
  if (JS_IsArrayObject(proxy->context->js, value))
  {
    jsuint length;
    JCHECK(JS_GetArrayLength(proxy->context->js, value, &length));

    JRETURN_RUBY(INT2FIX(length));
  }
  else
  {
    JSIdArray *ids = JS_Enumerate(proxy->context->js, value);
    JCHECK(ids);
    VALUE length = INT2FIX(ids->length);
    
    JS_DestroyIdArray(proxy->context->js, ids);

    JRETURN_RUBY(length);
  }
}

/* private */ static VALUE /* context */
context(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  return (VALUE)JS_GetContextPrivate(proxy->context->js);
}

/* private */ static VALUE /* function_property?(name) */
function_property_p(VALUE self, VALUE name)
{
  Check_Type(name, T_STRING);
  
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, "function_property_p", 2);

  JROOT(proxy->value);

  jsval js_value;  

  JCHECK(JS_GetProperty(proxy->context->js,
      JSVAL_TO_OBJECT(proxy->value), StringValueCStr(name), &js_value));

  JROOT(js_value);

  JSType type = JS_TypeOfValue(proxy->context->js, js_value);

  JRETURN_RUBY(type == JSTYPE_FUNCTION ? Qtrue : Qfalse);
}

/* private */ static VALUE
call_function_property(int argc, VALUE* argv, VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  if (argc < 1)
    rb_raise(rb_eArgError, "Function name required");

  PREPARE_RUBY_JROOTS(proxy->context, "call_function_property", 2);
  JROOT(proxy->value);

  jsval function;
  
  JCHECK(JS_GetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy->value), StringValueCStr(argv[0]), &function));

  JROOT(function);

  JSType funtype = JS_TypeOfValue(proxy->context->js, function);
  
  // should never be anything but a function
  if (funtype != JSTYPE_FUNCTION)
    JERROR("Specified property \"%s\" isn't a function.", StringValueCStr(argv[0]));

  JRETURN_RUBY(call_js_function_value(proxy->context, proxy->value, function, argc - 1, &(argv[1])));
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void finalize(RubyLandProxy* proxy)
{
  // could get finalized after the context has been freed
  if (proxy->context && proxy->context->jsids)
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

bool ruby_value_is_proxy(VALUE maybe_proxy)
{
  return proxy_class == CLASS_OF(maybe_proxy); 
}

JSBool unwrap_ruby_land_proxy(OurContext* UNUSED(context), VALUE wrapped, jsval* retval)
{
  assert(ruby_value_is_proxy(wrapped));
  
  RubyLandProxy* proxy;
  Data_Get_Struct(wrapped, RubyLandProxy, proxy);
  
  *retval = proxy->value; 
  return JS_TRUE;
}

VALUE make_ruby_land_proxy(OurContext* context, jsval value)
{
  VALUE id = (VALUE)JS_HashTableLookup(context->jsids, (void *)value);
  
  if (id)
  {
    // if we already have a proxy, return it
    return rb_funcall(rb_const_get(rb_cObject,
      rb_intern("ObjectSpace")), rb_intern("_id2ref"), 1, id);
  }
  else
  {
    // otherwise make one and cache it
    RubyLandProxy* our_proxy; 
    VALUE proxy = Data_Make_Struct(proxy_class, RubyLandProxy, 0, finalize, our_proxy);

    PREPARE_RUBY_JROOTS(context, "make_ruby_land_proxy", 1);
    JROOT(value);

    our_proxy->value = value;
    our_proxy->context = context;

    // put the proxy OID in the id map
    JCHECK(JS_HashTableAdd(context->jsids, (void *)value, (void *)rb_obj_id(proxy)));
    
    // root the value for JS GC
    char key[10];
    sprintf(key, "%x", (int)value);
    JCHECK(JS_SetProperty(context->js, context->gcthings, key, &value));

    JRETURN_RUBY(proxy);
  }
}

static VALUE to_s(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, "to_s", 1);
  JROOT(proxy->value);
  JSString* str = JS_ValueToString(proxy->context->js, proxy->value);

  JRETURN_RUBY(convert_jsstring_to_ruby(proxy->context, str));
}

void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey)
{
  proxy_class = rb_define_class_under(spidermonkey, "RubyLandProxy", rb_cObject);

  rb_define_method(proxy_class, "[]", get, 1);
  rb_define_method(proxy_class, "[]=", set, 2);
  rb_define_method(proxy_class, "function?", function_p, 0);
  rb_define_method(proxy_class, "respond_to?", respond_to_p, 1);
  rb_define_method(proxy_class, "each", each, 0);
  rb_define_method(proxy_class, "length", length, 0);
  rb_define_method(proxy_class, "to_s", to_s, 0);

  rb_define_private_method(proxy_class, "native_call", native_call, -1);
  rb_define_private_method(proxy_class, "context", context, 0);
  rb_define_private_method(proxy_class, "function_property?", function_property_p, 1);
  rb_define_private_method(proxy_class, "call_function_property", call_function_property, -1);
}
