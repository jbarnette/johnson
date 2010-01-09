#include "ruby_land_proxy.h"
#include "conversions.h"

DECLARE_RUBY_WRAPPER(rb_call_super, int argc; const VALUE* argv)
DEFINE_RUBY_WRAPPER(rb_call_super, rb_call_super, ARGLIST2(argc, argv))

DECLARE_RUBY_WRAPPER(rb_yield, VALUE v)
DEFINE_RUBY_WRAPPER(rb_yield, rb_yield, ARGLIST1(v))

DECLARE_RUBY_WRAPPER(rb_check_type, VALUE o; int t)
DEFINE_VOID_RUBY_WRAPPER(rb_check_type, rb_check_type, ARGLIST2(o, t))

DEFINE_RUBY_WRAPPER(rb_string_value, rb_string_value, ARGLIST1T(volatile VALUE*,v))
DEFINE_VOID_RUBY_WRAPPER(rb_string_value_cstr, rb_string_value_cstr, ARGLIST1T(volatile VALUE*,v))

DEFINE_RUBY_WRAPPER(make_ruby_land_proxy, make_ruby_land_proxy, ARGLIST3(runtime, value, root_name))

static VALUE proxy_class = Qnil;
static VALUE script_class = Qnil;

static inline JSBool get_jsval_for_proxy(RubyLandProxy* proxy, jsval* jv)
{
  *jv = (jsval)(proxy->key);
  return JS_TRUE;
}

static VALUE call_js_function_value(JohnsonRuntime* runtime, jsval target, jsval function, int argc, VALUE* argv)
{
  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_RUBY_JROOTS(context, argc + 2);

  JROOT(target);
  JROOT(function);

  assert(JSVAL_IS_OBJECT(target));

  jsval args[argc];
  jsval result;

  int i;
  for(i = 0; i < argc; ++i)
  {
    JCHECK(convert_to_js(runtime, argv[i], &(args[i])));
    JROOT(args[i]);
  }

  JCHECK(JS_CallFunctionValue(context,
    JSVAL_TO_OBJECT(target), function, (unsigned) argc, args, &result));

  JRETURN_RUBY(CONVERT_TO_RUBY(runtime, result));
}

/*
 * call-seq:
 *   [](name)
 *
 * Retrieves the current value of the +name+ property of this JavaScript
 * object.
 */
static VALUE
get(VALUE self, VALUE name)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  JSContext * context = johnson_get_current_context(proxy->runtime);
  PREPARE_RUBY_JROOTS(context, 1);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  jsval js_value;  

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_GetElement(context,
          JSVAL_TO_OBJECT(proxy_value), (jsint)(NUM2INT(name)), &js_value));
      break;
    case T_SYMBOL:
      name = RB_FUNCALL_0(name, RB_INTERN("to_s"));
    default:
      CALL_RUBY_WRAPPER(rb_string_value_cstr, (VALUE)&name);
      JCHECK(JS_GetProperty(context,
          JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(CONVERT_TO_RUBY(proxy->runtime, js_value));
}

/*
 * call-seq:
 *   []=(name, value)
 *
 * Sets this JavaScript object's +name+ property to +value+.
 */
static VALUE
set(VALUE self, VALUE name, VALUE value)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);
  
  PREPARE_RUBY_JROOTS(context, 2);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  jsval js_value;
  JCHECK(convert_to_js(proxy->runtime, value, &js_value));
  
  JROOT(js_value);

  switch(TYPE(name)) {
    case T_FIXNUM:
      JCHECK(JS_SetElement(context,
              JSVAL_TO_OBJECT(proxy_value), (jsint)(NUM2INT(name)), &js_value));
      break;
    case T_SYMBOL:
      name = RB_FUNCALL_0(name, RB_INTERN("to_s"));
    default:
      CALL_RUBY_WRAPPER(rb_string_value_cstr, (VALUE)&name);
      JCHECK(JS_SetProperty(context,
            JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));
      break;
  }

  JRETURN_RUBY(value);
}

/*
 * call-seq:
 *   function?()
 *
 * Returns <code>true</code> if this JavaScript object is a function.
 */
static VALUE
function_p(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);
  PREPARE_RUBY_JROOTS(context, 1);
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);
  JRETURN_RUBY(JS_TypeOfValue(context, proxy_value) == JSTYPE_FUNCTION ? Qtrue : Qfalse);
}

static VALUE
callable_test_p(VALUE /* self */, VALUE proxy)
{
  return function_p(proxy);
}

/*
 * call-seq:
 *   respond_to?(symbol)
 *
 * Returns <code>true</code> if this JavaScript object responds to the
 * named method.
 */
static VALUE
respond_to_p(int argc, const VALUE* argv, VALUE self)
{
  VALUE sym, priv;

  rb_scan_args(argc, argv, "11", &sym, &priv);

  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  JSContext * context = johnson_get_current_context(proxy->runtime);
  PREPARE_RUBY_JROOTS(context, 2);
  
  VALUE stringval = rb_funcall(sym, rb_intern("to_s"), 0);
  char* name = StringValuePtr(stringval);
  
  // assignment is always okay
  if (name[strlen(name) - 1] == '=')
    JRETURN_RUBY(Qtrue);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  JSObject *obj;
  JSBool found;
  
  JCHECK(JS_ValueToObject(context, proxy_value, &obj));
  JROOT(obj);

  JCHECK(JS_HasProperty(context, obj, name, &found));

  JRETURN_RUBY(found ? Qtrue : CALL_RUBY_WRAPPER(rb_call_super, argc, argv));
}

/*
 * call-seq:
 *   native_call(this, *args)
 *
 * Call this Ruby Object as a function, with the given +this+ object and
 * arguments. Equivalent to the call method in JavaScript.
 */
static VALUE
native_call(int argc, VALUE* argv, VALUE self)
{
  if (!function_p(self))
    rb_raise(rb_eRuntimeError,
      "This Johnson::TraceMonkey::RubyLandProxy isn't a function.");

  if (argc < 1)
    rb_raise(rb_eArgError, "Target object required");

  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);

  jsval proxy_value;

  if (!get_jsval_for_proxy(proxy, &proxy_value))
    raise_js_error_in_ruby(proxy->runtime);

  jsval global;

  if (!convert_to_js(proxy->runtime, argv[0], &global))
    raise_js_error_in_ruby(proxy->runtime);

  return call_js_function_value(proxy->runtime, global, proxy_value,
    argc - 1, &(argv[1]));
}

static void
destroy_id_array(JSContext* context, void* data)
{
  JS_DestroyIdArray(context, (JSIdArray*)data);
}

/*
 * call-seq:
 *   each {| element | block }
 *   each {| name, value | block }
 *
 * Calls <em>block</em> with each item in this JavaScript array, or with
 * each +name+/+value+ pair (like a Hash) for any other JavaScript
 * object.
 */
static VALUE
each(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);
  
  PREPARE_RUBY_JROOTS(context, 5);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  JSObject* value = JSVAL_TO_OBJECT(proxy_value);
  JROOT(value);
  
  // arrays behave like you'd expect, indexes in order
  if (JS_IsArrayObject(context, value))
  {
    jsuint length;
    JCHECK(JS_GetArrayLength(context, value, &length));
    
    jsuint i = 0;
    for (i = 0; i < length; ++i)
    {
      jsval element;
      JCHECK(JS_GetElement(context, value, (signed) i, &element));
      CALL_RUBY_WRAPPER(rb_yield, CONVERT_TO_RUBY(proxy->runtime, element));
    }
  }
  else
  {
    // not an array? behave like each on Hash; yield [key, value]
    JSIdArray* ids = JS_Enumerate(context, value);
    JCHECK(ids);

    JCLEANUP(destroy_id_array, ids);

    int i;
    for (i = 0; i < ids->length; ++i)
    {
      jsval js_key, js_value;

      JCHECK(JS_IdToValue(context, ids->vector[i], &js_key));
      JROOT(js_key);

      if (JSVAL_IS_STRING(js_key))
      {
        // regular properties have string keys
        JCHECK(JS_GetProperty(context, value,
          JS_GetStringBytes(JSVAL_TO_STRING(js_key)), &js_value));
      }
      else
      {
        // it's a numeric property, use array access
        JCHECK(JS_GetElement(context, value,
          JSVAL_TO_INT(js_key), &js_value));
      }
      JROOT(js_value);

      VALUE key = CONVERT_TO_RUBY(proxy->runtime, js_key);
      VALUE value = CONVERT_TO_RUBY(proxy->runtime, js_value);

      CALL_RUBY_WRAPPER(rb_yield, rb_ary_new3(2L, key, value));

      JUNROOT(js_value);
      JUNROOT(js_key);
    }
  }

  JRETURN_RUBY(self);
}

/*
 * call-seq:
 *   length()
 *
 * Returns the number of entries in the JavaScript array, or the number
 * of properties on the JavaScript object.
 */
static VALUE
length(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);

  PREPARE_RUBY_JROOTS(context, 2);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  JSObject* value = JSVAL_TO_OBJECT(proxy_value);
  JROOT(value);
  
  if (JS_IsArrayObject(context, value))
  {
    jsuint length;
    JCHECK(JS_GetArrayLength(context, value, &length));

    JRETURN_RUBY(INT2FIX(length));
  }
  else
  {
    JSIdArray* ids = JS_Enumerate(context, value);
    JCHECK(ids);
    VALUE length = INT2FIX(ids->length);
    
    JS_DestroyIdArray(context, ids);

    JRETURN_RUBY(length);
  }
}

/*
 * call-seq:
 *   runtime()
 *
 * Returns the Johnson::TraceMonkey::Runtime against which this object
 * is registered.
 */
static VALUE
runtime(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  return (VALUE)JS_GetRuntimePrivate(proxy->runtime->js);
}

/*
 * call-seq:
 *   function_property?(name)
 *
 * Returns <code>true</code> if this JavaScript object's +name+ property
 * is a function.
 */
static VALUE
function_property_p(VALUE self, VALUE name)
{
  if (TYPE(name) == T_SYMBOL)
    name = rb_funcall(name, rb_intern("to_s"), 0);

  rb_string_value_cstr(&name);

  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);

  PREPARE_RUBY_JROOTS(context, 2);

  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  jsval js_value;  

  JCHECK(JS_GetProperty(context,
      JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &js_value));

  JROOT(js_value);

  JSType type = JS_TypeOfValue(context, js_value);

  JRETURN_RUBY(type == JSTYPE_FUNCTION ? Qtrue : Qfalse);
}

/*
 * call-seq:
 *   call_function_property(name, arguments)
 *
 * Calls this JavaScript object's +name+ method, passing the given
 * arguments.
 *
 * Equivalent to:
 *    proxy[name].native_call(proxy, *arguments)
 */
static VALUE
call_function_property(int argc, VALUE* argv, VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);

  if (argc < 1)
    rb_raise(rb_eArgError, "Function name required");

  PREPARE_RUBY_JROOTS(context, 2);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);

  jsval function;

  VALUE name = argv[0];
  CALL_RUBY_WRAPPER(rb_string_value_cstr, (VALUE)&name);
  
  JCHECK(JS_GetProperty(context,
    JSVAL_TO_OBJECT(proxy_value), StringValueCStr(name), &function));

  JROOT(function);

  // should never be anything but a function
  if (!JS_ObjectIsFunction(context, JSVAL_TO_OBJECT(function)))
    JERROR("Specified property \"%s\" isn't a function.", StringValueCStr(name));

  REMOVE_JROOTS;

  return call_js_function_value(proxy->runtime, proxy_value, function, argc - 1, &(argv[1]));
}

/*
 * call-seq:
 *   to_s()
 *
 * Converts the JavaScript object to a string, using its toString method
 * if available.
 */
static VALUE to_s(VALUE self)
{
  RubyLandProxy* proxy;
  Data_Get_Struct(self, RubyLandProxy, proxy);
  JSContext * context = johnson_get_current_context(proxy->runtime);

  PREPARE_RUBY_JROOTS(context, 1);
  
  jsval proxy_value;
  JCHECK(get_jsval_for_proxy(proxy, &proxy_value));
  JROOT(proxy_value);
  
  JSString* str = JS_ValueToString(context, proxy_value);
  JRETURN_RUBY(CONVERT_JS_STRING_TO_RUBY(proxy->runtime, str));
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void finalize(RubyLandProxy* proxy)
{
  // could get finalized after the context has been freed
  if (proxy->runtime && proxy->runtime->jsids)
  {
    // remove this proxy from the OID map
    jsval proxy_value;
    get_jsval_for_proxy(proxy, &proxy_value);
    JS_HashTableRemove(proxy->runtime->jsids, (void *)proxy_value);
  }

  if (proxy->runtime)
  {
    // remove our GC handle on the JS value
    JS_RemoveRootRT(proxy->runtime->js, &(proxy->key));
  }

  free(proxy);
}

bool ruby_value_is_proxy(VALUE maybe_proxy)
{
  return rb_obj_is_kind_of(maybe_proxy, proxy_class);
}

bool ruby_value_is_script_proxy(VALUE maybe_proxy)
{
  return rb_obj_is_kind_of(maybe_proxy, script_class);
}

VALUE apply_wrappers(VALUE proxy)
{
  VALUE johnson = rb_const_get(rb_mKernel, rb_intern("Johnson"));
  VALUE johnson_proxy = rb_const_get(johnson, rb_intern("RubyLandProxy"));
  return rb_funcall(johnson_proxy, rb_intern("apply_wrappers"), 1, proxy);
}

VALUE apply_conversions(VALUE proxy)
{
  VALUE johnson = rb_const_get(rb_mKernel, rb_intern("Johnson"));
  VALUE johnson_proxy = rb_const_get(johnson, rb_intern("RubyLandProxy"));
  return rb_funcall(johnson_proxy, rb_intern("apply_conversions"), 1, proxy);
}

JSBool unwrap_ruby_land_proxy(JohnsonRuntime* runtime, VALUE wrapped, jsval* retval)
{
  JSContext * context = johnson_get_current_context(runtime);
  assert(ruby_value_is_proxy(wrapped));
  
  PREPARE_JROOTS(context, 0);

  RubyLandProxy* proxy;
  Data_Get_Struct(wrapped, RubyLandProxy, proxy);
  
  JCHECK(get_jsval_for_proxy(proxy, retval));
  JRETURN;
}

VALUE make_ruby_land_proxy(JohnsonRuntime* runtime, jsval value, const char* root_name)
{
  RubyLandProxy * our_proxy = (RubyLandProxy *)JS_HashTableLookup(runtime->jsids, (void *)value);
  
  if (our_proxy)
  {
    // if we already have a proxy, return it
    return apply_conversions(our_proxy->self);
  }
  else
  {    
    // otherwise make one and cache it
    VALUE proxy = Data_Make_Struct((strncmp(root_name, "JSScriptProxy", strlen("JSScriptProxy")) ? proxy_class : script_class), RubyLandProxy, 0, finalize, our_proxy);

    JSContext * context = johnson_get_current_context(runtime);

    PREPARE_RUBY_JROOTS(context, 1);
    JROOT(value);

    VALUE rb_runtime = (VALUE)JS_GetRuntimePrivate(runtime->js);
    rb_iv_set(proxy, "@runtime", rb_runtime);

    our_proxy->runtime = runtime;
    our_proxy->key = (void *)value;
    our_proxy->self = proxy;

    // root the value for JS GC and lookups
    JCHECK(JS_AddNamedRootRT(runtime->js, &(our_proxy->key), root_name));

    // put the proxy OID in the id map
    JCHECK(JS_HashTableAdd(runtime->jsids, (void *)value, (void *)our_proxy));

    VALUE final_proxy = JPROTECT(apply_wrappers, proxy);

    our_proxy->self = final_proxy;

    JRETURN_RUBY(JPROTECT(apply_conversions, final_proxy));
  }
}

void init_Johnson_TraceMonkey_Proxy(VALUE tracemonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE tracemonkey = rb_define_module_under(johnson, "TraceMonkey");
  */

  VALUE johnson = rb_const_get(rb_mKernel, rb_intern("Johnson"));
  VALUE johnson_proxy = rb_const_get(johnson, rb_intern("RubyLandProxy"));

  /* RubyLandProxy class. */
  proxy_class = rb_define_class_under(tracemonkey, "RubyLandProxy", johnson_proxy);

  rb_define_method(proxy_class, "[]", (ruby_callback)get, 1);
  rb_define_method(proxy_class, "[]=", (ruby_callback)set, 2);
  rb_define_method(proxy_class, "function?", (ruby_callback)function_p, 0);
  rb_define_method(proxy_class, "respond_to?", (ruby_callback)respond_to_p, -1);
  rb_define_method(proxy_class, "each", (ruby_callback)each, 0);
  rb_define_method(proxy_class, "length", (ruby_callback)length, 0);
  rb_define_method(proxy_class, "to_s", (ruby_callback)to_s, 0);

  rb_define_private_method(proxy_class, "runtime", (ruby_callback)runtime, 0);
  rb_define_private_method(proxy_class, "function_property?", (ruby_callback)function_property_p, 1);
  rb_define_private_method(proxy_class, "call_function_property", (ruby_callback)call_function_property, -1);

  VALUE callable = rb_define_module_under(proxy_class, "Callable");
  rb_define_singleton_method(callable, "test?", (ruby_callback)callable_test_p, 1);
  rb_define_private_method(callable, "native_call", (ruby_callback)native_call, -1);

  rb_funcall(johnson_proxy, rb_intern("insert_wrapper"), 1, callable);

  script_class = rb_define_class_under(tracemonkey, "RubyLandScript", proxy_class);
}
