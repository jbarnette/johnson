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
  JS_PropertyStub,
  JS_PropertyStub,
  JS_EnumerateStub,
  JS_ResolveStub,
  JS_ConvertStub,
  finalize,
  NULL,
  NULL,
  call
};

#define TAG_RAISE 0x6
#define TAG_THROW 0x7

static VALUE call_ruby_from_js_invoke(VALUE args)
{
  VALUE self = rb_ary_pop(args);
  VALUE id = rb_ary_pop(args);
  return rb_apply(self, SYM2ID(id), args);
}

JSBool call_ruby_from_js_va(OurContext* context, VALUE* result, VALUE self, ID id, int argc, va_list va)
{
  VALUE old_errinfo = ruby_errinfo;
  VALUE args = rb_ary_new2(argc + 2);

  int i;
  for(i = 0; i < argc; i++)
    rb_ary_store(args, i, va_arg(va, VALUE));

  rb_ary_store(args, argc, ID2SYM(id));
  rb_ary_store(args, argc + 1, self);

  int state;
  *result = rb_protect(call_ruby_from_js_invoke, args, &state);

  switch (state)
  {
    case 0:
      return JS_TRUE;

    case TAG_RAISE:
      {
        VALUE local_error = ruby_errinfo;
        jsval js_err;
        ruby_errinfo = old_errinfo;
        if (!convert_to_js(context, local_error, &js_err))
          return JS_FALSE;
        JS_SetPendingException(context->js, js_err);
        return JS_FALSE;
      }

    case TAG_THROW:
      // FIXME: This should be propagated to JS... as an exception?

    default:
      {
        JSString* str = JS_NewStringCopyZ(context->js, "Unexpected longjmp from ruby!");
        if (str)
          JS_SetPendingException(context->js, STRING_TO_JSVAL(str));
        return JS_FALSE;
      }
  }
}

JSBool call_ruby_from_js(OurContext* context, jsval* retval, VALUE self, ID id, int argc, ...)
{
  VALUE result;
  va_list va;
  va_start(va, argc);
  JSBool okay = call_ruby_from_js_va(context, &result, self, id, argc, va);
  va_end(va);
  if (!okay) return JS_FALSE;
  return retval ? convert_to_js(context, result, retval) : JS_TRUE;
}

JSBool call_ruby_from_js2(OurContext* context, VALUE* retval, VALUE self, ID id, int argc, ...)
{
  va_list va;
  va_start(va, argc);
  JSBool okay = call_ruby_from_js_va(context, retval, self, id, argc, va);
  va_end(va);
  return okay;
}

static bool autovivified_p(VALUE UNUSED(ruby_context), VALUE self, char* name)
{
  return RTEST(rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("autovivified?"), 2,
    self, rb_str_new2(name)));
}

static bool const_p(VALUE self, char* name)
{
  return rb_obj_is_kind_of(self, rb_cModule)
    && rb_is_const_id(rb_intern(name))
    && RTEST( rb_funcall(self, rb_intern("const_defined?"), 1, ID2SYM(rb_intern(name))) );
}

static bool global_p(char* name)
{
  return rb_ary_includes(rb_f_global_variables(), rb_str_new2(name));
}

static bool method_p(VALUE self, char* name)
{
  return RTEST( rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern(name))) );
}

static bool attribute_p(VALUE self, char* name)
{
  if (!method_p(self, name))
    return false;
    
  VALUE rb_id = rb_intern(name);
  VALUE rb_method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(rb_id));

  METHOD* method;
  Data_Get_Struct(rb_method, METHOD, method);
  
  return nd_type(method->body) == NODE_IVAR
    || RTEST(rb_funcall(Johnson_SpiderMonkey_JSLandProxy(),
        rb_intern("js_property?"), 2, self, ID2SYM(rb_id)));
}

static bool indexable_p(VALUE self)
{
  return RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]"))));
}

static bool has_key_p(VALUE self, char* name)
{
  return RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]"))))
    && RTEST(rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?"))))
    && RTEST(rb_funcall(self, rb_intern("key?"), 1, rb_str_new2(name)));
}

static bool respond_to_p(JSContext* js_context, JSObject* obj, char* name)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);

  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  VALUE self = (VALUE)JS_GetInstancePrivate(
    context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  if (!self) return false;

  return autovivified_p(ruby_context, self, name)
    || const_p(self, name)
    || global_p(name)
    || attribute_p(self, name)
    || method_p(self, name)
    || has_key_p(self, name);
}

static jsval evaluate_js_property_expression(OurContext * context, const char * property, jsval* retval) {
  return JS_EvaluateScript(context->js, context->global,
      property, strlen(property), "johnson:evaluate_js_property_expression", 1,
      retval);
}

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  JS_AddNamedRoot(js_context, &id, "JSLandProxy#get");

  // pull out our Ruby context, which is embedded in js_context
  
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  // get our struct, which is embedded in ruby_context
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  // get the Ruby object that backs this proxy
  
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);
  
  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (indexable_p(self)) {
      VALUE idx = INT2FIX(JSVAL_TO_INT(id));
      JS_RemoveRoot(js_context, &id);
      return call_ruby_from_js(context, retval, self, rb_intern("[]"), 1, idx);
    }
    
    JS_RemoveRoot(js_context, &id);
    return JS_TRUE;
  }
  
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_id = rb_intern(name);

  // FIXME: we should probably just JS_DefineProperty this, and it shouldn't be enumerable
  
  if (!strcasecmp("__iterator__", name)) {
    JS_RemoveRoot(js_context, &id);
    return evaluate_js_property_expression(context, "Johnson.Generator.create", retval);
  }
  
  // if the Ruby object has a dynamic js property with a key
  // matching the property we're looking for, pull the value out of
  // that map.
  
  else if (autovivified_p(ruby_context, self, name))
  {
    JS_RemoveRoot(js_context, &id);
    return call_ruby_from_js(context, retval, Johnson_SpiderMonkey_JSLandProxy(),
      rb_intern("autovivified"), 2, self, rb_str_new2(name));
  }

  // if the Ruby object is a Module or Class and has a matching
  // const defined, return the converted result of const_get
  
  else if (const_p(self, name))
  {
    JS_RemoveRoot(js_context, &id);
    return call_ruby_from_js(context, retval, self, rb_intern("const_get"),
      1, ID2SYM(ruby_id));
  }  

  // otherwise, if it's a global, return the global
  else if (global_p(name))
  {
    JS_RemoveRoot(js_context, &id);
    return convert_to_js(context, rb_gv_get(name), retval);
  }
  
  // otherwise, if the Ruby object has a an attribute method matching
  // the property we're trying to get, call it and return the converted result
  
  else if (attribute_p(self, name))
  {
    JS_RemoveRoot(js_context, &id);
    return call_ruby_from_js(context, retval, self, ruby_id, 0);
  }

  // otherwise, if the Ruby object quacks sorta like a hash (it responds to
  // "[]" and "key?"), index it by key and return the converted result
  
  else if (has_key_p(self, name))
  {
    JS_RemoveRoot(js_context, &id);
    return call_ruby_from_js(context, retval, self, rb_intern("[]"), 1, rb_str_new2(name));
  }
  
  // otherwise, it's a method being accessed as a property, which means
  // we need to return a lambda
  
  // FIXME: this should really wrap the Method  for 'name' in a JS class
  // rather than generating a wrapper Proc
  
  else if (method_p(self, name))
  {
    JS_RemoveRoot(js_context, &id);
    return call_ruby_from_js(context, retval, self, rb_intern("method"), 1, rb_str_new2(name));
  }

  JS_RemoveRoot(js_context, &id);
  
  // else it's undefined (JS_VOID) by default
  return JS_TRUE;
}

// called for lazily resolved properties, which should go away
static JSBool get_and_destroy_resolved_property(
  JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  JS_AddNamedRoot(js_context, &id, "JSLandProxy#get_and_destroy_resolved_property");
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  JS_DeleteProperty(js_context, obj, name);
  JS_RemoveRoot(js_context, &id);
  return get(js_context, obj, id, retval);
}

static JSBool set(JSContext* js_context, JSObject* obj, jsval id, jsval* value)
{
  JS_AddNamedRoot(js_context, &id, "JSLandProxy#set");
  JS_AddNamedRoot(js_context, value, "JSLandProxy#set");

  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);
  
  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (indexable_p(self))
    {
      VALUE idx = INT2FIX(JSVAL_TO_INT(id));
      VALUE val = convert_to_ruby(context, *value);
      JS_RemoveRoot(js_context, value);
      JS_RemoveRoot(js_context, &id);

      return call_ruby_from_js(context, NULL, self, rb_intern("[]="), 2, idx, val);
    }

    JS_RemoveRoot(js_context, value);
    JS_RemoveRoot(js_context, &id);
    
    return JS_TRUE;
  }
  
  VALUE ruby_key = convert_to_ruby(context, id);
  VALUE ruby_value = convert_to_ruby(context, *value);

  JS_RemoveRoot(js_context, value);
  JS_RemoveRoot(js_context, &id);
  
  VALUE setter = rb_str_append(rb_str_new3(ruby_key), rb_str_new2("="));
  VALUE setter_id = rb_intern(StringValueCStr(setter));
  
  VALUE settable_p, indexable_p;
  if (!call_ruby_from_js2(context, &settable_p, self, rb_intern("respond_to?"), 1, ID2SYM(setter_id)))
    return JS_FALSE;
  if (!call_ruby_from_js2(context, &indexable_p, self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]="))))
    return JS_FALSE;
  
  if (settable_p)
  {
    VALUE method, arity;
    if (!call_ruby_from_js2(context, &method, self, rb_intern("method"), 1, ID2SYM(setter_id)))
      return JS_FALSE;
    if (!call_ruby_from_js2(context, &arity, method, rb_intern("arity"), 0))
      return JS_FALSE;

    // if the Ruby object has a 1-arity method named "property=",
    // call it with the converted value
    
    if (NUM2INT(arity) == 1)
      return call_ruby_from_js(context, NULL, self, setter_id, 1, ruby_value);
  }
  else if(indexable_p)
  {
    // otherwise, if the Ruby object quacks sorta like a hash for assignment
    // (it responds to "[]="), assign it by key
    
    return call_ruby_from_js(context, NULL, self, rb_intern("[]="), 2, ruby_key, ruby_value);
  }
  else
  {
    return call_ruby_from_js(context, NULL, Johnson_SpiderMonkey_JSLandProxy(), rb_intern("autovivify"), 
      3, self, ruby_key, ruby_value);
  }

  return JS_TRUE;
}

static JSBool construct(JSContext* js_context, JSObject* UNUSED(obj), uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  VALUE klass = convert_to_ruby(context, JS_ARGV_CALLEE(argv));
  VALUE args = rb_ary_new();

  uintN i;
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, convert_to_ruby(context, argv[i]));
    
  return call_ruby_from_js(context, retval, Johnson_SpiderMonkey_JSLandProxy(), 
    rb_intern("send_with_possible_block"), 3, klass, ID2SYM(rb_intern("new")), args);
}

static JSBool resolve(JSContext *js_context, JSObject *obj, jsval id, uintN UNUSED(flags), JSObject **objp)
{
  JS_AddNamedRoot(js_context, &id, "JSLandProxy#resolve");

  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
  
  char* name = JS_GetStringBytes(JS_ValueToString(js_context, id));

  if (respond_to_p(js_context, obj, name))
  {
    if(!(JS_DefineProperty(js_context, obj, name, JSVAL_VOID,
        get_and_destroy_resolved_property, set, JSPROP_ENUMERATE))) {
      JS_RemoveRoot(js_context, &id);
      return JS_FALSE;
    }

    *objp = obj;
  }

  JS_RemoveRoot(js_context, &id);

  return JS_TRUE;
}

static JSBool to_string(JSContext* js_context, JSObject* obj, uintN UNUSED(argc), jsval* UNUSED(argv), jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);

  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  return call_ruby_from_js(context, retval, self, rb_intern("to_s"), 0);
}

static JSBool to_array(JSContext* js_context, JSObject* obj, uintN UNUSED(argc), jsval* UNUSED(argv), jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);

  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);

  return call_ruby_from_js(context, retval, self, rb_intern("to_a"), 0);
}

static JSBool method_missing(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL);
  
  assert(argc >= 2);

  char* key = JS_GetStringBytes(JSVAL_TO_STRING(argv[0]));
  VALUE ruby_id = rb_intern(key);
  
  // FIXME: this is horrible and lazy, to_a comes from enumerable on proxy (argv[1] is a JSArray)
  VALUE args;
  if (!call_ruby_from_js2(context, &args, convert_to_ruby(context, argv[1]), rb_intern("to_a"), 0))
    return JS_FALSE;

  return call_ruby_from_js(context, retval, Johnson_SpiderMonkey_JSLandProxy(),
    rb_intern("send_with_possible_block"), 3, self, ID2SYM(ruby_id), args);
}

static JSBool call(JSContext* js_context, JSObject* UNUSED(obj), uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
  
  VALUE self = (VALUE)JS_GetInstancePrivate(context->js, JSVAL_TO_OBJECT(JS_ARGV_CALLEE(argv)), &JSLandCallableProxyClass, NULL);
  
  VALUE args = rb_ary_new();  

  uintN i;
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, convert_to_ruby(context, argv[i]));
  
  return call_ruby_from_js(context, retval, Johnson_SpiderMonkey_JSLandProxy(),
    rb_intern("send_with_possible_block"), 3, self, ID2SYM(rb_intern("call")), args);
}

bool js_value_is_proxy(OurContext* MAYBE_UNUSED(context), jsval maybe_proxy)
{
  JSClass* klass = JS_GET_CLASS(context->js, JSVAL_TO_OBJECT(maybe_proxy));  
  
  return &JSLandProxyClass == klass
    || &JSLandClassProxyClass == klass
    || &JSLandCallableProxyClass == klass;
}

VALUE unwrap_js_land_proxy(OurContext* context, jsval proxy)
{
  VALUE value;
  JSObject *proxy_object = JSVAL_TO_OBJECT(proxy);
  
  value = (VALUE)JS_GetInstancePrivate(context->js, proxy_object,
          JS_GET_CLASS(context->js, proxy_object), NULL);
  
  return value;
}

static void finalize(JSContext* js_context, JSObject* obj)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  if (ruby_context)
  {
    OurContext* context;
    Data_Get_Struct(ruby_context, OurContext, context);
    
    VALUE self = (VALUE)JS_GetInstancePrivate(context->js, obj,
            JS_GET_CLASS(context->js, obj), NULL);
    
    // remove the proxy OID from the id map
    JS_HashTableRemove(context->rbids, (void *)rb_obj_id(self));
    
    // free up the ruby value for GC
    rb_funcall(ruby_context, rb_intern("remove_gcthing"), 1, self);
    call_ruby_from_js(context, NULL, ruby_context, rb_intern("remove_gcthing"), 1, self);
  }  
}

JSBool make_js_land_proxy(OurContext* context, VALUE value, jsval* retval)
{
  jsid id = (jsid)JS_HashTableLookup(context->rbids, (void *)rb_obj_id(value));
  
  if (id)
  {
    return JS_IdToValue(context->js, id, retval);
  }
  else
  {
    JSObject *jsobj;
    
    JSClass *klass = &JSLandProxyClass;
    if (T_CLASS == TYPE(value)) klass = &JSLandClassProxyClass;
    
    // FIXME: hack; should happen in Rubyland
    if (T_STRUCT == TYPE(value))
      rb_funcall(Johnson_SpiderMonkey_JSLandProxy(),
        rb_intern("treat_all_properties_as_methods"), 1, value);

    bool callable_p = rb_class_of(value) == rb_cMethod
      || rb_class_of(value) == rb_cProc;
      
    if (callable_p)
      klass = &JSLandCallableProxyClass;
        
    if(!(jsobj = JS_NewObject(context->js, klass, NULL, NULL)))
      return JS_FALSE;
    if(!(JS_SetPrivate(context->js, jsobj, (void*)value)))
      return JS_FALSE;

    if (!callable_p) {
      if(!(JS_DefineFunction(context->js, jsobj,
          "__noSuchMethod__", method_missing, 2, 0)))
        return JS_FALSE;
    }

    if(!(JS_DefineFunction(context->js, jsobj, "toArray", to_array, 0, 0)))
      return JS_FALSE;

    if(!(JS_DefineFunction(context->js, jsobj, "toString", to_string, 0, 0)))
      return JS_FALSE;

    *retval = OBJECT_TO_JSVAL(jsobj);

    jsval newid;
    if(!(JS_ValueToId(context->js, *retval, &newid)))
      return JS_FALSE;
  
    // put the proxy OID in the id map
    if(!(JS_HashTableAdd(context->rbids, (void *)rb_obj_id(value), (void *)newid)))
      return JS_FALSE;
    
    // root the ruby value for GC
    VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
    rb_funcall(ruby_context, rb_intern("add_gcthing"), 1, value);

    return JS_TRUE;
  }
}
