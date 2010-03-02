#include "js_land_proxy.h"
#include "conversions.h"

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval);
static JSBool set(JSContext* context, JSObject* obj, jsval id, jsval* retval);
static JSBool construct(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval);
static JSBool resolve(JSContext *js_context, JSObject *obj, jsval id, uintN flags, JSObject **objp);
static JSBool call(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval);
static void finalize(JSContext* context, JSObject* obj);

static JSClass JSLandProxyClass = {
  "JSLandProxy", JSCLASS_HAS_PRIVATE | JSCLASS_NEW_RESOLVE,
  JS_PropertyStub,
  JS_PropertyStub,
  get,
  set,
  JS_EnumerateStub,
  (JSResolveOp) resolve,
  JS_ConvertStub,
  finalize
};

static JSClass JSLandClassProxyClass = {
  "JSLandClassProxy", JSCLASS_HAS_PRIVATE,
  JS_PropertyStub,
  JS_PropertyStub,
  get,
  set,
  JS_EnumerateStub,
  JS_ResolveStub,
  JS_ConvertStub,
  finalize,
  NULL,
  NULL,
  NULL,
  construct
};

static JSClass JSLandCallableProxyClass = {
  "JSLandCallableProxy", JSCLASS_HAS_PRIVATE,
  JS_PropertyStub,
  JS_PropertyStub,
  get,
  set,
  JS_EnumerateStub,
  JS_ResolveStub,
  JS_ConvertStub,
  finalize,
  NULL,
  NULL,
  call
};

static VALUE call_ruby_from_js_invoke(VALUE args)
{
  VALUE self = rb_ary_pop(args);
  VALUE id = rb_ary_pop(args);
  return rb_apply(self, SYM2ID(id), args);
}

JSBool call_ruby_from_js_va(JohnsonRuntime* runtime, VALUE* result, VALUE self, ID id, int argc, va_list va)
{
  VALUE old_errinfo = ruby_errinfo;
  VALUE args = rb_ary_new2((long)argc + 2);

  long i;
  for(i = 0; i < argc; i++)
    rb_ary_store(args, i, va_arg(va, VALUE));

  rb_ary_store(args, (long)argc, ID2SYM(id));
  rb_ary_store(args, (long)argc + 1, self);

  int state;
  *result = rb_protect(call_ruby_from_js_invoke, args, &state);

  if (state)
    return report_ruby_error_in_js(runtime, state, old_errinfo);

  return JS_TRUE;
}

JSBool call_ruby_from_js(JohnsonRuntime* runtime, jsval* retval, VALUE self, ID id, int argc, ...)
{
  VALUE result;
  va_list va;
  va_start(va, argc);
  JSBool okay = call_ruby_from_js_va(runtime, &result, self, id, argc, va);
  va_end(va);
  if (!okay) return JS_FALSE;
  return retval ? convert_to_js(runtime, result, retval) : JS_TRUE;
}

JSBool call_ruby_from_js2(JohnsonRuntime* runtime, VALUE* retval, VALUE self, ID id, int argc, ...)
{
  va_list va;
  va_start(va, argc);
  JSBool okay = call_ruby_from_js_va(runtime, retval, self, id, argc, va);
  va_end(va);
  return okay;
}

static VALUE autovivified_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(autovivified_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(autovivified_p, autovivified_p, ARGLIST3(self, name, id));

static VALUE autovivified_p(VALUE self, VALUE name, ID UNUSED(id))
{
  return RTEST(rb_funcall(Johnson_TraceMonkey_JSLandProxy(), rb_intern("autovivified?"), 2,
    self, name)) ? Qtrue : Qfalse;
}

static VALUE const_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(const_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(const_p, const_p, ARGLIST3(self, name, id));

static VALUE const_p(VALUE self, VALUE UNUSED(name), VALUE id)
{
  
  return (rb_obj_is_kind_of(self, rb_cModule)
    && rb_is_const_id(id)
    && RTEST( rb_funcall(self, rb_intern("const_defined?"), 1, ID2SYM(id) )))  ? Qtrue : Qfalse;
}

static VALUE global_p(VALUE name);

DECLARE_RUBY_WRAPPER(global_p, VALUE name);
DEFINE_RUBY_WRAPPER(global_p, global_p, ARGLIST1(name));

static VALUE global_p(VALUE name)
{
  return (*StringValuePtr(name) == '$' && rb_ary_includes(rb_f_global_variables(), name)) ? Qtrue : Qfalse;
}

static VALUE method_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(method_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(method_p, method_p, ARGLIST3(self, name, id));

static VALUE method_p(VALUE self, VALUE UNUSED(name), ID id)
{
  return (RTEST( rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(id) ) )) ? Qtrue : Qfalse;
}

static VALUE attribute_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(attribute_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(attribute_p, attribute_p, ARGLIST3(self, name, id));

static VALUE attribute_p(VALUE self, VALUE name, ID id)
{
  if (!method_p(self, name, id))
    return Qfalse;

  VALUE rb_id = id;
  VALUE rb_method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(rb_id));

  if (TYPE(rb_method) == T_DATA)
  {
    VALUE klass = CLASS_OF(rb_method);
    if (klass == rb_cMethod)
    {
      METHOD* method;
      Data_Get_Struct(rb_method, METHOD, method);

      if (method && nd_type(method->body) == NODE_IVAR)
        return Qtrue;
    }
  }

  return (RTEST(rb_funcall(Johnson_TraceMonkey_JSLandProxy(),
    rb_intern("js_property?"), 2, self, ID2SYM(rb_id)))) ? Qtrue : Qfalse;
}

static VALUE indexable_p(VALUE self);

DECLARE_RUBY_WRAPPER(indexable_p, VALUE self);
DEFINE_RUBY_WRAPPER(indexable_p, indexable_p, ARGLIST1(self));

static VALUE indexable_p(VALUE self)
{
  return (RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]"))))) ? Qtrue : Qfalse;
}

static VALUE has_key_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(has_key_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(has_key_p, has_key_p, ARGLIST3(self, name, id));

static VALUE has_key_p(VALUE self, VALUE name, ID UNUSED(id))
{
  return (RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]"))))
    && RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?"))))
    && RTEST(rb_funcall(self, rb_intern("key?"), 1, name))) ? Qtrue : Qfalse;
}

static VALUE respond_to_p(VALUE self, VALUE name, ID id);

DECLARE_RUBY_WRAPPER(respond_to_p, VALUE self; VALUE name; ID id);
DEFINE_RUBY_WRAPPER(respond_to_p, respond_to_p, ARGLIST3(self, name, id));

static VALUE respond_to_p(VALUE self, VALUE name, ID id)
{
  return (autovivified_p(self, name, id)
    || const_p(self, name, id)
    || global_p(name)
    || attribute_p(self, name, id)
    || method_p(self, name, id)
    || has_key_p(self, name, id)) ? Qtrue : Qfalse;
}

static jsval evaluate_js_property_expression(JohnsonRuntime * runtime,
                                                   JSContext * js_context,
                                                   const char * property, jsval* retval) {
  assert(strlen(property) < INT_MAX);
  return JS_EvaluateScript(js_context, runtime->global,
      property, (unsigned int)strlen(property), "johnson:evaluate_js_property_expression", 1,
      retval);
}

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  // pull out our Ruby context, which is embedded in js_context
  
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  // get our struct, which is embedded in ruby_context
  
  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 1);
  JROOT(id);
    
  // get the Ruby object that backs this proxy
  
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);
  
  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (CALL_RUBY_WRAPPER(indexable_p, self))
    {
      VALUE idx = INT2FIX(JSVAL_TO_INT(id));
      JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("[]"), 1, idx));
    }
    
    JRETURN;
  }
  
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE name_value = rb_str_new2(name);
  VALUE ruby_id = rb_to_id(name_value);

  // FIXME: we should probably just JS_DefineProperty this, and it shouldn't be enumerable
  
  if (!strcasecmp("__iterator__", name)) {
    JCHECK(evaluate_js_property_expression(runtime, js_context, "Johnson.Generator.create", retval));
  }
  
  // if the Ruby object has a dynamic js property with a key
  // matching the property we're looking for, pull the value out of
  // that map.
  
  else if (CALL_RUBY_WRAPPER(autovivified_p, self, name_value, ruby_id))
  {
    JCHECK(call_ruby_from_js(runtime, retval, Johnson_TraceMonkey_JSLandProxy(),
      rb_intern("autovivified"), 2, self, rb_str_new2(name)));
  }

  // if the Ruby object is a Module or Class and has a matching
  // const defined, return the converted result of const_get
  
  else if (CALL_RUBY_WRAPPER(const_p, self, name_value, ruby_id))
  {
    JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("const_get"),
      1, ID2SYM(ruby_id)));
  }  

  // otherwise, if it's a global, return the global
  else if (CALL_RUBY_WRAPPER(global_p, name_value))
  {
    JCHECK(convert_to_js(runtime, rb_gv_get(name), retval));
  }
  
  // otherwise, if the Ruby object has a an attribute method matching
  // the property we're trying to get, call it and return the converted result
  
  else if (CALL_RUBY_WRAPPER(attribute_p, self, name_value, ruby_id))
  {
    JCHECK(call_ruby_from_js(runtime, retval, self, ruby_id, 0));
  }

  // otherwise, if the Ruby object quacks sorta like a hash (it responds to
  // "[]" and "key?"), index it by key and return the converted result
  
  else if (CALL_RUBY_WRAPPER(has_key_p, self, name_value, ruby_id))
  {
    JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("[]"), 1, rb_str_new2(name)));
  }
  
  // otherwise, it's a method being accessed as a property, which means
  // we need to return a lambda
  
  // FIXME: this should really wrap the Method  for 'name' in a JS class
  // rather than generating a wrapper Proc
  
  else if (CALL_RUBY_WRAPPER(method_p, self, name_value, ruby_id))
  {
    JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("method"), 1, rb_str_new2(name)));
  }

  // else it's undefined (JS_VOID) by default
  JRETURN;
}

// called for lazily resolved properties, which should go away
static JSBool get_and_destroy_resolved_property(
  JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  PREPARE_JROOTS(js_context, 1);
  JROOT(id);
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  JCHECK(JS_DeleteProperty(js_context, obj, name));
  JCHECK(get(js_context, obj, id, retval));
  JRETURN;
}

static JSBool set(JSContext* js_context, JSObject* obj, jsval id, jsval* value)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 2);
  JROOT(id);
  JROOT_PTR(value);
    
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (CALL_RUBY_WRAPPER(indexable_p, self))
    {
      VALUE idx = INT2FIX(JSVAL_TO_INT(id));
      VALUE val = CONVERT_TO_RUBY(runtime, *value);

      JCHECK(call_ruby_from_js(runtime, NULL, self, rb_intern("[]="), 2, idx, val));
    }

    JRETURN;
  }
  
  VALUE ruby_key = CONVERT_TO_RUBY(runtime, id);
  VALUE ruby_value = CONVERT_TO_RUBY(runtime, *value);

  VALUE setter = rb_str_append(rb_str_new3(ruby_key), rb_str_new2("="));
  VALUE setter_id = rb_intern(StringValueCStr(setter));
  
  VALUE settable_p, indexable_p;
  JCHECK(call_ruby_from_js2(runtime, &settable_p, self, rb_intern("respond_to?"), 1, ID2SYM(setter_id)));
  JCHECK(call_ruby_from_js2(runtime, &indexable_p, self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]="))));
  
  if (settable_p)
  {
    VALUE method, arity;
    JCHECK(call_ruby_from_js2(runtime, &method, self, rb_intern("method"), 1, ID2SYM(setter_id)));
    JCHECK(call_ruby_from_js2(runtime, &arity, method, rb_intern("arity"), 0));

    // if the Ruby object has a 1-arity method named "property=",
    // call it with the converted value
    
    if (NUM2INT(arity) == 1)
      JCHECK(call_ruby_from_js(runtime, NULL, self, setter_id, 1, ruby_value));
  }
  else if(indexable_p)
  {
    // otherwise, if the Ruby object quacks sorta like a hash for assignment
    // (it responds to "[]="), assign it by key
    
    JCHECK(call_ruby_from_js(runtime, NULL, self, rb_intern("[]="), 2, ruby_key, ruby_value));
  }
  else
  {
    JCHECK(call_ruby_from_js(runtime, NULL, Johnson_TraceMonkey_JSLandProxy(), rb_intern("autovivify"), 
      3, self, ruby_key, ruby_value));
  }

  JRETURN;
}

static JSBool construct(JSContext* js_context, JSObject* UNUSED(obj), uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 0);

  VALUE klass = CONVERT_TO_RUBY(runtime, JS_ARGV_CALLEE(argv));
  VALUE args = rb_ary_new();

  uintN i;
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, CONVERT_TO_RUBY(runtime, argv[i]));
    
  JCHECK(call_ruby_from_js(runtime, retval, Johnson_TraceMonkey_JSLandProxy(),
    rb_intern("send_with_possible_block"), 3, klass, ID2SYM(rb_intern("new")), args));
  JRETURN;
}

static JSBool resolve(JSContext *js_context, JSObject *obj, jsval id, uintN UNUSED(flags), JSObject **objp)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  JohnsonContext* context;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  PREPARE_JROOTS(js_context, 1);
  JROOT(id);
  
  VALUE self =
    (VALUE)JS_GetInstancePrivate(js_context, obj, JS_GET_CLASS(js_context, obj), NULL);

  char* cname = JS_GetStringBytes(JS_ValueToString(js_context, id));

  VALUE name = rb_str_new2(cname);
  ID ruby_id = rb_intern(cname);

  if (CALL_RUBY_WRAPPER(respond_to_p, self, name, ruby_id))
  {
    JCHECK(JS_DefineProperty(js_context, obj, cname, JSVAL_VOID,
        get_and_destroy_resolved_property, set, JSPROP_ENUMERATE));

    *objp = obj;
  }

  JRETURN;
}

static JSBool to_string(JSContext* js_context, JSObject* obj, uintN UNUSED(argc), jsval* UNUSED(argv), jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);

  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 0);

  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("to_s"), 0));
  JRETURN;
}

static JSBool to_array(JSContext* js_context, JSObject* obj, uintN UNUSED(argc), jsval* UNUSED(argv), jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);

  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 0);

  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  JCHECK(call_ruby_from_js(runtime, retval, self, rb_intern("to_a"), 0));
  JRETURN;
}

static JSBool method_missing(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 0);
    
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);
  
  assert(argc >= 2);

  char* key = JS_GetStringBytes(JSVAL_TO_STRING(argv[0]));
  VALUE ruby_id = rb_intern(key);
  
  // FIXME: this is horrible and lazy, to_a comes from enumerable on proxy (argv[1] is a JSArray)
  VALUE args;
  JCHECK(call_ruby_from_js2(runtime, &args, CONVERT_TO_RUBY(runtime, argv[1]), rb_intern("to_a"), 0));

  JCHECK(call_ruby_from_js(runtime, retval, Johnson_TraceMonkey_JSLandProxy(),
    rb_intern("send_with_possible_block"), 3, self, ID2SYM(ruby_id), args));

  JRETURN;
}

static JSBool call(JSContext* js_context, JSObject* UNUSED(obj), uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  JohnsonContext* context;
  JohnsonRuntime* runtime;
  Data_Get_Struct(ruby_context, JohnsonContext, context);

  VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
  Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);

  PREPARE_JROOTS(js_context, 0);
  
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, JSVAL_TO_OBJECT(JS_ARGV_CALLEE(argv)), &JSLandCallableProxyClass, NULL);
  
  VALUE args = rb_ary_new();  

  uintN i;
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, CONVERT_TO_RUBY(runtime, argv[i]));
  
  JCHECK(call_ruby_from_js(runtime, retval, Johnson_TraceMonkey_JSLandProxy(),
    rb_intern("send_with_possible_block"), 3, self, ID2SYM(rb_intern("call")), args));
  JRETURN;
}

bool js_value_is_proxy(JohnsonRuntime* MAYBE_UNUSED(runtime), jsval maybe_proxy)
{
  JSContext* js_context = johnson_get_current_context(runtime);
  JSClass* klass = JS_GET_CLASS(
      js_context,
      JSVAL_TO_OBJECT(maybe_proxy));  
  
  return &JSLandProxyClass == klass
    || &JSLandClassProxyClass == klass
    || &JSLandCallableProxyClass == klass;
}

VALUE unwrap_js_land_proxy(JohnsonRuntime* runtime, jsval proxy)
{
  VALUE value;
  JSObject *proxy_object = JSVAL_TO_OBJECT(proxy);
  JSContext * context = johnson_get_current_context(runtime);
  
  value = (VALUE)JS_GetInstancePrivate(context, proxy_object,
          JS_GET_CLASS(context, proxy_object), NULL);
  
  return value;
}

static void finalize(JSContext* js_context, JSObject* obj)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  if (ruby_context)
  {
    JohnsonContext* context;
    JohnsonRuntime* runtime;
    Data_Get_Struct(ruby_context, JohnsonContext, context);

    VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(js_context));
    Data_Get_Struct(ruby_runtime, JohnsonRuntime, runtime);
    
    VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj,
            JS_GET_CLASS(context->js, obj), NULL);

    // remove the proxy OID from the id map
    JS_HashTableRemove(runtime->rbids, (void *)self);

    // free up the ruby value for GC
    rb_funcall(ruby_runtime, rb_intern("remove_gcthing"), 1, rb_obj_id(self));
  }
}

JSBool make_js_land_proxy(JohnsonRuntime* runtime, VALUE value, jsval* retval)
{
  jsval base_value = (jsval)JS_HashTableLookup(runtime->rbids, (void *)value);

  JSContext * context = johnson_get_current_context(runtime);
  PREPARE_JROOTS(context, 2);

  jsval johnson = JSVAL_NULL;
  JCHECK(evaluate_js_property_expression(runtime, context, "Johnson", &johnson));
  JROOT(johnson);

  if (base_value)
  {
    JCHECK(JS_CallFunctionName(context, JSVAL_TO_OBJECT(johnson), "applyConversions", 1, &base_value, retval));
    JRETURN;
  }
  else
  {
    JSObject *jsobj;
    
    JSClass *klass = &JSLandProxyClass;
    if (T_CLASS == TYPE(value)) klass = &JSLandClassProxyClass;
    
    // FIXME: hack; should happen in Rubyland
    if (T_STRUCT == TYPE(value))
      rb_funcall(Johnson_TraceMonkey_JSLandProxy(),
        rb_intern("treat_all_properties_as_methods"), 1, value);

    bool callable_p = Qtrue == rb_funcall(value,
      rb_intern("respond_to?"), 1, rb_str_new2("call"));
      
    if (callable_p)
      klass = &JSLandCallableProxyClass;
        
    JCHECK((jsobj = JS_NewObject(context, klass, NULL, NULL)));
    JROOT(jsobj);
    
    JCHECK(JS_SetPrivate(context, jsobj, (void*)value));

    JCHECK(JS_DefineFunction(context, jsobj, "__noSuchMethod__", method_missing, 2, 0));

    JCHECK(JS_DefineFunction(context, jsobj, "toArray", to_array, 0, 0));
    JCHECK(JS_DefineFunction(context, jsobj, "toString", to_string, 0, 0));

    base_value = OBJECT_TO_JSVAL(jsobj);

    // root the ruby value for GC
    VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(runtime->js);
    rb_funcall(ruby_runtime, rb_intern("add_gcthing"), 1, value);

    jsval wrapped_value = JSVAL_NULL;
    JCHECK(JS_CallFunctionName(context, JSVAL_TO_OBJECT(johnson), "applyWrappers", 1, &base_value, &wrapped_value));

    // put the proxy OID in the id map
    JCHECK(JS_HashTableAdd(runtime->rbids, (void *)value, (void *)(wrapped_value)));
    
    JCHECK(JS_CallFunctionName(context, JSVAL_TO_OBJECT(johnson), "applyConversions", 1, &wrapped_value, retval));

    JRETURN;
  }
}

// Local Variables:
// c-basic-offset:2
// tab-width:2
// End:
