#include "ruby_land_proxy.h"
#include "conversions.h"
#include "error.h"

DECLARE_RUBY_WRAPPER(rb_call_super, int argc; const VALUE* argv)
DEFINE_RUBY_WRAPPER(rb_call_super, rb_call_super, ARGLIST2(argc, argv))

DECLARE_RUBY_WRAPPER(rb_yield, VALUE v)
DEFINE_RUBY_WRAPPER(rb_yield, rb_yield, ARGLIST1(v))

static VALUE proxy_class = Qnil;

static jsval get_jsval_for_proxy(RubyLandProxy* proxy)
{
  // FIXME: this is totally lame
  char global_key[10];
  sprintf(global_key, "%x", (int)proxy->context->global);
  
  if (0 == strcmp(global_key, proxy->key))
    return OBJECT_TO_JSVAL(proxy->context->global);
  
  jsval proxy_value;
  assert(JS_GetProperty(proxy->context->js, proxy->context->gcthings, proxy->key, &proxy_value));
  return proxy_value;
}

static VALUE call_js_function_value(OurContext* context, jsval target, jsval function, int argc, VALUE* argv)
{
  PREPARE_RUBY_JROOTS(context, argc + 2);

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

  JRETURN_RUBY(CONVERT_TO_RUBY(context, result));
}

/*
 * call-seq:
 *   [](name)
 *
 * Returns the property with +name+.
 */
static VALUE
get(VALUE self, VALUE name)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, 1);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  jsval js_value;  

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_GetElement(proxy->context->js,
          JSVAL_TO_OBJECT(proxy_value), NUM2INT(name), &js_value));
      break;
    default:
      Check_Type(name, T_STRING);
      JCHECK(JS_GetProperty(proxy->context->js,
          JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(CONVERT_TO_RUBY(proxy->context, js_value));
}

/*
 * call-seq:
 *   []=(name,value)
 *
 * Sets the property with +name+ to +value+.
 */
static VALUE
set(VALUE self, VALUE name, VALUE value)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, 2);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  
  JROOT(proxy_value);

  jsval js_value;
  JCHECK(convert_to_js(proxy->context, value, &js_value));
  
  JROOT(js_value);

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_SetElement(proxy->context->js,
              JSVAL_TO_OBJECT(proxy_value), NUM2INT(name), &js_value));
      break;
    default:
      Check_Type(name, T_STRING);
      JCHECK(JS_SetProperty(proxy->context->js,
            JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(value);
}

/*
 * call-seq:
 *   function?
 *
 * Returns <code>true</code> if this is a function.
 */
static VALUE
function_p(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  return JS_TypeOfValue(proxy->context->js, get_jsval_for_proxy(proxy)) == JSTYPE_FUNCTION ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *   respond_to?(symbol)
 *
 * Returns <code>true</code> if _obj_ responds to given method.
 */
static VALUE
respond_to_p(VALUE self, VALUE sym)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, 2);
  
  char* name = rb_id2name(SYM2ID(sym));
  
  // assignment is always okay
  if (name[strlen(name) - 1] == '=')
    JRETURN_RUBY(Qtrue);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  JSObject *obj;
  JSBool found;
  
  JCHECK(JS_ValueToObject(proxy->context->js, proxy_value, &obj));
  JROOT(obj);

  JCHECK(JS_HasProperty(proxy->context->js, obj, name, &found));

  JRETURN_RUBY(found ? Qtrue : CALL_RUBY_WRAPPER(rb_call_super, 1, &sym));
}

/*
 * call-seq:
 *   native_call(global, *args)
 *
 * Call as a function with given +global+ using *args.
 */
static VALUE
native_call(int argc, VALUE* argv, VALUE self)
{
  if (!function_p(self))
    Johnson_Error_raise("This Johnson::SpiderMonkey::RubyLandProxy isn't a function.");

  if (argc < 1)
    rb_raise(rb_eArgError, "Target object required");

  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, 1);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  jsval global;
  JCHECK(convert_to_js(proxy->context, argv[0], &global));

  JRETURN_RUBY(call_js_function_value(proxy->context, global, proxy_value, argc - 1, &(argv[1])));
}

static void
destroy_id_array(OurContext* context, void* data)
{
  JS_DestroyIdArray(context->js, (JSIdArray*)data);
}

/*
 * call-seq:
 *   each { |obj| block }
 *
 * Calls <em>block</em> with each item in the collection.
 */
static VALUE
each(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  
  PREPARE_RUBY_JROOTS(proxy->context, 5);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  JSObject* value = JSVAL_TO_OBJECT(proxy_value);
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
      CALL_RUBY_WRAPPER(rb_yield, convert_to_ruby(proxy->context, element));
    }
  }
  else
  {
    // not an array? behave like each on Hash; yield [key, value]
    JSIdArray* ids = JS_Enumerate(proxy->context->js, value);
    JCHECK(ids);

    JCLEANUP(destroy_id_array, ids);

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

      VALUE key = CONVERT_TO_RUBY(proxy->context, js_key);
      VALUE value = CONVERT_TO_RUBY(proxy->context, js_value);

      CALL_RUBY_WRAPPER(rb_yield, rb_ary_new3(2, key, value));

      JUNROOT(js_value);
      JUNROOT(js_key);
    }
  }

  JRETURN_RUBY(self);
}

/*
 * call-seq:
 *   length
 *
 * Returns the length of the collection.
 */
static VALUE
length(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, 2);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  JSObject* value = JSVAL_TO_OBJECT(proxy_value);
  JROOT(value);
  
  if (JS_IsArrayObject(proxy->context->js, value))
  {
    jsuint length;
    JCHECK(JS_GetArrayLength(proxy->context->js, value, &length));

    JRETURN_RUBY(INT2FIX(length));
  }
  else
  {
    JSIdArray* ids = JS_Enumerate(proxy->context->js, value);
    JCHECK(ids);
    VALUE length = INT2FIX(ids->length);
    
    JS_DestroyIdArray(proxy->context->js, ids);

    JRETURN_RUBY(length);
  }
}

/*
 * call-seq:
 *   context
 *
 * Returns context.
 */
static VALUE
context(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  return (VALUE)JS_GetContextPrivate(proxy->context->js);
}

/*
 * call-seq:
 *   function_property?(name)
 *
 * Returns <code>true</code> if +name+ is a function property.
 */
static VALUE
function_property_p(VALUE self, VALUE name)
{
  Check_Type(name, T_STRING);
  
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, 2);

  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  jsval js_value;  

  JCHECK(JS_GetProperty(proxy->context->js,
      JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));

  JROOT(js_value);

  JSType type = JS_TypeOfValue(proxy->context->js, js_value);

  JRETURN_RUBY(type == JSTYPE_FUNCTION ? Qtrue : Qfalse);
}

/*
 * call-seq:
 *   call_function_property(name, arguments)
 *
 * Calls function +name+ with +arguments+.
 */
static VALUE
call_function_property(int argc, VALUE* argv, VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  if (argc < 1)
    rb_raise(rb_eArgError, "Function name required");

  PREPARE_RUBY_JROOTS(proxy->context, 2);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);

  jsval function;
  
  JCHECK(JS_GetProperty(proxy->context->js,
    JSVAL_TO_OBJECT(proxy_value), StringValueCStr(argv[0]), &function));

  JROOT(function);

  JSType funtype = JS_TypeOfValue(proxy->context->js, function);
  
  // should never be anything but a function
  if (funtype != JSTYPE_FUNCTION)
    JERROR("Specified property \"%s\" isn't a function.", StringValueCStr(argv[0]));

  JRETURN_RUBY(call_js_function_value(proxy->context, proxy_value, function, argc - 1, &(argv[1])));
}

/*
 * call-seq:
 *   to_s
 *
 * Converts object to a string.
 */
static VALUE to_s(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  PREPARE_RUBY_JROOTS(proxy->context, 1);
  
  jsval proxy_value = get_jsval_for_proxy(proxy);
  JROOT(proxy_value);
  
  JSString* str = JS_ValueToString(proxy->context->js, proxy_value);
  JRETURN_RUBY(convert_jsstring_to_ruby(proxy->context, str));
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void finalize(RubyLandProxy* proxy)
{
  jsval proxy_value = get_jsval_for_proxy(proxy);
  
  // could get finalized after the context has been freed
  if (proxy->context && proxy->context->jsids)
  {
    // remove this proxy from the OID map
    JS_HashTableRemove(proxy->context->jsids, (void *)proxy_value);
  
    // remove our GC handle on the JS value
    JS_DeleteProperty(proxy->context->js, proxy->context->gcthings, proxy->key);
    
    proxy->context = 0;
  }
  
  proxy->key = 0;
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
  
  *retval = get_jsval_for_proxy(proxy);
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

    PREPARE_RUBY_JROOTS(context, 1);
    JROOT(value);

    // root the value for JS GC and lookups
    our_proxy->key = malloc(sizeof(char[10]));
    sprintf(our_proxy->key, "%x", (int)value);
    
    JCHECK(JS_SetProperty(context->js, context->gcthings, our_proxy->key, &value));

    our_proxy->context = context;

    // put the proxy OID in the id map
    JCHECK(JS_HashTableAdd(context->jsids, (void *)value, (void *)rb_obj_id(proxy)));
    
    JRETURN_RUBY(proxy);
  }
}

void init_Johnson_SpiderMonkey_Proxy(VALUE spidermonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  */

  /* RubyLandProxy class. */
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
