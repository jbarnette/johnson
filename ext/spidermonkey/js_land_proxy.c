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
  (JSResolveOp)resolve,
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

static JSBool autovivified_p(VALUE ruby_context, VALUE self, char* name)
{
  return rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("autovivified?"), 2,
    self, rb_str_new2(name));
}

static JSBool const_p(VALUE self, char* name)
{
  return rb_obj_is_kind_of(self, rb_cModule)
    && rb_is_const_id(rb_intern(name))
    && rb_funcall(self, rb_intern("const_defined?"), 1, ID2SYM(rb_intern(name)));
}

static JSBool global_p(char* name)
{
  return rb_ary_includes(rb_f_global_variables(), rb_str_new2(name));
}

static JSBool method_p(VALUE self, char* name)
{
  return rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern(name)));
}

static JSBool attribute_p(VALUE self, char* name)
{
  if (!method_p(self, name))
    return JS_FALSE;
    
  VALUE rb_id = rb_intern(name);
  VALUE rb_method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(rb_id));

  METHOD* method;
  Data_Get_Struct(rb_method, METHOD, method);
  
  return nd_type(method->body) == NODE_IVAR
    || rb_funcall(Johnson_SpiderMonkey_JSLandProxy(),
        rb_intern("js_property?"), 2, self, ID2SYM(rb_id));
}

static JSBool indexable_p(VALUE self)
{
  VALUE v = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]")));
  return RTEST(v) ? JS_TRUE : JS_FALSE;
}

static JSBool has_key_p(VALUE self, char* name)
{
  return rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]")))
    && rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?")))
    && rb_funcall(self, rb_intern("key?"), 1, rb_str_new2(name));
}

static JSBool respond_to_p(JSContext* js_context, JSObject* obj, char* name)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
  
  VALUE self;
  
  assert(self = (VALUE)JS_GetInstancePrivate(
    context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
  return autovivified_p(ruby_context, self, name)
    || const_p(self, name)
    || global_p(name)
    || attribute_p(self, name)
    || method_p(self, name)
    || has_key_p(self, name);
}

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  // pull out our Ruby context, which is embedded in js_context
  
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  // get our struct, which is embedded in ruby_context
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  // get the Ruby object that backs this proxy
  
  VALUE self;
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (indexable_p(self))
      return convert_to_js(context,
        rb_funcall(self, rb_intern("[]"), 1, INT2FIX(JSVAL_TO_INT(id))), retval);
    
    return JS_TRUE;
  }
  
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_id = rb_intern(name);
  
  // FIXME: this is necessarily ugly. Maybe we should write something like
  // jsval foo = property_expression(context->js, context->global, "Johnson.Generator.create")
  // this would make the code where we look up Johnson.Symbol cleaner too (in conversions.c)
  
  // FIXME: we should probably just JS_DefineProperty this, and it shouldn't be enumerable
  
  if (!strcasecmp("__iterator__", name)) {
    jsval nsJohnson;
    assert(JS_GetProperty(context->js, context->global, "Johnson", &nsJohnson) || JSVAL_VOID == nsJohnson);

    jsval nsGenerator;
    assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(nsJohnson), "Generator", &nsGenerator) || JSVAL_VOID == nsGenerator);

    jsval create;
    assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(nsGenerator), "create", &create) || JSVAL_VOID == create);
    *retval = create;
    return JS_TRUE;
  }
  
  // if the Ruby object has a dynamic js property with a key
  // matching the property we're looking for, pull the value out of
  // that map.
  
  else if (autovivified_p(ruby_context, self, name))
  {
    return convert_to_js(context,
      rb_funcall(Johnson_SpiderMonkey_JSLandProxy(),
        rb_intern("autovivified"), 2, self, rb_str_new2(name)), retval);
  }

  // if the Ruby object is a Module or Class and has a matching
  // const defined, return the converted result of const_get
  
  else if (const_p(self, name))
  {
    return convert_to_js(context,
      rb_funcall(self, rb_intern("const_get"), 1, ID2SYM(ruby_id)), retval);
  }  

  // otherwise, if it's a global, return the global
  else if (global_p(name))
  {
    return convert_to_js(context, rb_gv_get(name), retval);
  }
  
  // otherwise, if the Ruby object has a an attribute method matching
  // the property we're trying to get, call it and return the converted result
  
  else if (attribute_p(self, name))
  {
    return convert_to_js(context, rb_funcall(self, ruby_id, 0), retval);
  }

  // otherwise, if the Ruby object quacks sorta like a hash (it responds to
  // "[]" and "key?"), index it by key and return the converted result
  
  else if (has_key_p(self, name))
  {
    return convert_to_js(context, rb_funcall(self, rb_intern("[]"), 1, rb_str_new2(name)), retval);
  }
  
  // otherwise, it's a method being accessed as a property, which means
  // we need to return a lambda
  
  // FIXME: this should really wrap the Method  for 'name' in a JS class
  // rather than generating a wrapper Proc
  
  else if (method_p(self, name))
  {
    convert_to_js(context,
      rb_funcall(self, rb_intern("method"), 1, rb_str_new2(name)), retval);
  }
  
  // else it's undefined (JS_VOID) by default
  return JS_TRUE;
}

// called for lazily resolved properties, which should go away
static JSBool get_and_destroy_resolved_property(
  JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  char* name = JS_GetStringBytes(JSVAL_TO_STRING(id));
  JS_DeleteProperty(js_context, obj, name);
  return get(js_context, obj, id, retval);
}

static JSBool set(JSContext* js_context, JSObject* obj, jsval id, jsval* value)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  VALUE self;
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
  // Short-circuit for numeric indexes
  
  if (JSVAL_IS_INT(id))
  {
    if (indexable_p(self))
      rb_funcall(self, rb_intern("[]="),
        2, INT2FIX(JSVAL_TO_INT(id)), convert_to_ruby(context, *value));
    
    return JS_TRUE;
  }
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_key = rb_str_new2(key);
  
  VALUE setter = rb_str_append(rb_str_new3(ruby_key), rb_str_new2("="));
  VALUE setter_id = rb_intern(StringValuePtr(setter));
  
  VALUE settable_p = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(setter_id));
  VALUE indexable_p = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]=")));
  
  if (settable_p)
  {
    VALUE method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(setter_id));
    int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
    
    // if the Ruby object has a 1-arity method named "property=",
    // call it with the converted value
    
    if (arity == 1)
      rb_funcall(self, setter_id, 1, convert_to_ruby(context, *value));
  }
  else if(indexable_p)
  {
    // otherwise, if the Ruby object quacks sorta like a hash for assignment
    // (it responds to "[]="), assign it by key
    
    rb_funcall(self, rb_intern("[]="), 2, ruby_key, convert_to_ruby(context, *value));
  }
  else
  {
    rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("autovivify"),
      3, self, ruby_key, convert_to_ruby(context, *value));
  }
  
  return JS_TRUE;
}

static JSBool construct(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  VALUE klass = convert_to_ruby(context, JS_ARGV_CALLEE(argv));
  VALUE args = rb_ary_new();

  int i;
  
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, convert_to_ruby(context, argv[i]));
    
  return convert_to_js(context,
    rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("send_with_possible_block"),
      3, klass, ID2SYM(rb_intern("new")), args), retval);
}

static JSBool resolve(JSContext *js_context, JSObject *obj, jsval id, uintN flags, JSObject **objp)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
  
  char* name = JS_GetStringBytes(JS_ValueToString(js_context, id));
  
  if (respond_to_p(js_context, obj, name))
  {
    assert(JS_DefineProperty(js_context, obj, name, JSVAL_VOID,
      get_and_destroy_resolved_property, set, JSPROP_ENUMERATE));
    
    *objp = obj;
  }
  
  return JS_TRUE;
}

static JSBool method_missing(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  VALUE self;
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(argv[0]));
  VALUE ruby_id = rb_intern(key);
  
  // FIXME: this is horrible and lazy, to_a comes from enumerable on proxy (argv[1] is a JSArray)
  VALUE args = rb_funcall(convert_to_ruby(context, argv[1]), rb_intern("to_a"), 0);
  
  return convert_to_js(context,
    rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("send_with_possible_block"),
      3, self, ID2SYM(ruby_id), args), retval);
}

static JSBool call(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
  
  VALUE self;// = convert_to_ruby(context, JS_ARGV_CALLEE(argv));
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, JSVAL_TO_OBJECT(JS_ARGV_CALLEE(argv)), &JSLandCallableProxyClass, NULL));
  
  VALUE args = rb_ary_new();  
  int i;
  
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, convert_to_ruby(context, argv[i]));
  
  return convert_to_js(context,
    rb_funcall(Johnson_SpiderMonkey_JSLandProxy(), rb_intern("send_with_possible_block"),
      3, self, ID2SYM(rb_intern("call")), args), retval);
}

JSBool js_value_is_proxy(OurContext* context, jsval maybe_proxy)
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
  
  assert(value = (VALUE)JS_GetInstancePrivate(context->js, proxy_object,
          JS_GET_CLASS(context->js, proxy_object), NULL));
  
  return value;
}

static void finalize(JSContext* js_context, JSObject* obj)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  if (ruby_context)
  {
    OurContext* context;
    Data_Get_Struct(ruby_context, OurContext, context);
    
    VALUE self;
    assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj,
            JS_GET_CLASS(context->js, obj), NULL));
    
    // remove the proxy OID from the id map
    JS_HashTableRemove(context->rbids, (void *)rb_obj_id(self));
    
    // free up the ruby value for GC
    rb_funcall(ruby_context, rb_intern("remove_gcthing"), 1, self);
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

    JSBool callable_p = rb_class_of(value) == rb_cMethod
      || rb_class_of(value) == rb_cProc;
      
    if (callable_p)
      klass = &JSLandCallableProxyClass;
        
    assert(jsobj = JS_NewObject(context->js, klass, NULL, NULL));
    assert(JS_SetPrivate(context->js, jsobj, (void*)value));

    if (!callable_p)
      assert(JS_DefineFunction(context->js, jsobj,
        "__noSuchMethod__", method_missing, 2, 0));

    *retval = OBJECT_TO_JSVAL(jsobj);

    jsval newid;
    assert(JS_ValueToId(context->js, *retval, &newid));
  
    // put the proxy OID in the id map
    assert(JS_HashTableAdd(context->rbids, (void *)rb_obj_id(value), (void *)newid));
    
    // root the ruby value for GC
    VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
    rb_funcall(ruby_context, rb_intern("add_gcthing"), 1, value);

    return JS_TRUE;
  }
}
