#include "js_land_proxy.h"

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval);
static JSBool set(JSContext* context, JSObject* obj, jsval id, jsval* retval);
static JSBool construct(JSContext* js_context, JSObject* obj, uintN argc, jsval* argv, jsval* retval);
static void finalize(JSContext* context, JSObject* obj);

static JSClass JSLandProxyClass = {
  "JSLandProxy", JSCLASS_HAS_PRIVATE,
  JS_PropertyStub,
  JS_PropertyStub,
  get,
  set,
  JS_EnumerateStub,
  JS_ResolveStub,
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

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval)
{
  // pull out our Ruby object, which is embedded in js_context
  
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  // get our struct, which is embedded in ruby_context
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  // get the Ruby object that backs this proxy
  
  VALUE self;
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_id = rb_intern(key);
  
  // if the Ruby object has a dynamic js property with a key
  // matching the property we're looking for, pull the value out of
  // that map.
  
  if (rb_funcall(ruby_context, rb_intern("autovivified?"), 2, self, ID2SYM(ruby_id)))
  {
    *retval = convert_to_js(context,
        rb_funcall(ruby_context, rb_intern("autovivified"), 2, self, ID2SYM(ruby_id)));
  }

  // if the Ruby object is a Module or Class and has a matching
  // const defined, return the converted result of const_get
  
  else if (rb_obj_is_kind_of(self, rb_cModule)
    && rb_is_const_id(ruby_id)
    && rb_funcall(self, rb_intern("const_defined?"), 1, ID2SYM(ruby_id)))
  {
    *retval = convert_to_js(context,
      rb_funcall(self, rb_intern("const_get"), 1, ID2SYM(ruby_id)));
  }  
  
  // otherwise, if the Ruby object has a 0-arity method named the same as
  // the property we're trying to get, call it and return the converted result
  
  else if (rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(ruby_id)))
  {
    VALUE method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(ruby_id));
    int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
        
    if (arity == 0)
      *retval = convert_to_js(context, rb_funcall(self, ruby_id, 0));
  }
  else
  {
    // otherwise, if the Ruby object quacks sorta like a hash (it responds to
    // "[]" and "key?"), index it by key and return the converted result

    VALUE indexable_p = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]")));
    VALUE has_key_p = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?")));
    
    if (indexable_p && has_key_p)
      *retval = convert_to_js(context, rb_funcall(self, rb_intern("[]"), 1, rb_str_new2(key)));
  }
  
  return JS_TRUE;
}

static JSBool set(JSContext* js_context, JSObject* obj, jsval id, jsval* value)
{
  VALUE ruby_context;
  assert(ruby_context = (VALUE)JS_GetContextPrivate(js_context));
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);
    
  VALUE self;
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, JS_GET_CLASS(context->js, obj), NULL));
  
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
    rb_funcall(ruby_context, rb_intern("autovivify"), 3, self,
      ruby_key, convert_to_ruby(context, *value));
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
    
  // Context#jsend: if the last arg is a function, it'll get passed along as a &block
  
  *retval = convert_to_js(context,
    rb_funcall(ruby_context, rb_intern("jsend"), 3, klass, ID2SYM(rb_intern("new")), args));

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
  
  // Context#jsend: if the last arg is a function, it'll get passed along as a &block
  
  *retval = convert_to_js(context,
    rb_funcall(ruby_context, rb_intern("jsend"), 3, self, ID2SYM(ruby_id), args));
  
  return JS_TRUE;
}

JSBool js_value_is_proxy(OurContext* context, jsval maybe_proxy)
{
  JSClass* klass = JS_GET_CLASS(context->js, JSVAL_TO_OBJECT(maybe_proxy));  
  return &JSLandProxyClass == klass || &JSLandClassProxyClass == klass;
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

jsval make_js_land_proxy(OurContext* context, VALUE value)
{
  jsid id = (jsid)JS_HashTableLookup(context->rbids, (void *)rb_obj_id(value));
  jsval js;
  
  if (id)
  {
    assert(JS_IdToValue(context->js, id, &js));
  }
  else
  {
    JSObject *jsobj;
    
    JSClass *klass = &JSLandProxyClass;
    if (T_CLASS == TYPE(value)) klass = &JSLandClassProxyClass;
    
    assert(jsobj = JS_NewObject(context->js, klass, NULL, NULL));
    assert(JS_SetPrivate(context->js, jsobj, (void*)value));
    assert(JS_DefineFunction(context->js, jsobj, "__noSuchMethod__", method_missing, 2, 0));

    js = OBJECT_TO_JSVAL(jsobj);

    jsval newid;
    assert(JS_ValueToId(context->js, js, &newid));
  
    // put the proxy OID in the id map
    assert(JS_HashTableAdd(context->rbids, (void *)rb_obj_id(value), (void *)newid));
    
    // root the ruby value for GC
    VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
    rb_funcall(ruby_context, rb_intern("add_gcthing"), 1, value);
  }
  
  return js;
}
