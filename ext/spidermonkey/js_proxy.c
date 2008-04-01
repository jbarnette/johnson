#include "js_proxy.h"

static JSBool get(JSContext* js_context, JSObject* obj, jsval id, jsval* retval);
static void finalize(JSContext* context, JSObject* obj);
static JSBool set(JSContext* context, JSObject* obj, jsval id, jsval* retval);

static JSClass JSProxyClass = {
  "JSProxy", JSCLASS_HAS_PRIVATE,
  JS_PropertyStub,
  JS_PropertyStub,
  get,
  set,
  JS_EnumerateStub,
  JS_ResolveStub,
  JS_ConvertStub,
  finalize
};

static void finalize(JSContext* context, JSObject* obj)
{
  // FIXME
}
// void Johnson_RubyProxy_finalize(JSContext *js_context, JSObject *obj)
// {
//   VALUE ruby;
//   VALUE self = (VALUE)JS_GetContextPrivate(js_context);
// 
//   ruby = (VALUE)JS_GetInstancePrivate(js_context, obj, &gRubyProxyClass, NULL);
//   VALUE c_name = rb_funcall(
//           rb_funcall(self, rb_intern("class"), 0),
//           rb_intern("to_s"), 0);
// 
//   if(rb_ivar_defined(self, rb_intern("@converted_objects"))) {
//     rb_hash_delete( rb_iv_get(self, "@converted_objects"),
//                     rb_funcall(ruby, rb_intern("object_id"), 0));
//   }
// }
// 

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
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, &JSProxyClass, NULL));
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_id = rb_intern(key);
  
  VALUE is_method = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(ruby_id));
  
  if (is_method)
  {
    VALUE method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(ruby_id));
    int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
    
    // if the Ruby object has a 0-arity method named the same as the property
    // we're trying to get, call it and return the converted result
    
    if (arity == 0)
      *retval = convert_to_js(context, rb_funcall(self, ruby_id, 0));
  }
  else
  {
    // otherwise, if the Ruby object quacks sorta like a hash (it responds to
    // "[]" and "key?"), index it by key and return the converted result
    
    VALUE is_indexable = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]")));
    VALUE has_key_p = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?")));
    
    if (is_indexable && has_key_p)
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
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, &JSProxyClass, NULL));
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(id));
  VALUE ruby_key = rb_str_new2(key);
  
  VALUE setter = rb_str_append(rb_str_new3(ruby_key), rb_str_new2("="));
  VALUE setter_id = rb_intern(StringValuePtr(setter));
  
  VALUE has_setter = rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(setter_id));
  
  if (has_setter)
  {
    VALUE method = rb_funcall(self, rb_intern("method"), 1, ID2SYM(setter_id));
    int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
    
    // if the Ruby object has a 1-arity method named "property=",
    // call it with the converted value
    
    if (arity == 1)
      rb_funcall(self, setter_id, 1, convert_to_ruby(context, *value));
  }
  else
  {
    // otherwise, if the Ruby object quacks sorta like a hash for assignment
    // (it responds to "[]="), assign it by key
    
    VALUE is_index_assignable =
      rb_funcall(self, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]=")));
    
    if (is_index_assignable)
      rb_funcall(self, rb_intern("[]="), 2, ruby_key, convert_to_ruby(context, *value));
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
  assert(self = (VALUE)JS_GetInstancePrivate(context->js, obj, &JSProxyClass, NULL));
  
  char* key = JS_GetStringBytes(JSVAL_TO_STRING(argv[0]));
  
  VALUE ruby_id = rb_intern(key);
  
  // FIXME: this could probably be a lot faster, to_a comes from enumerable on proxy
  VALUE args = rb_funcall(convert_to_ruby(context, argv[1]), rb_intern("to_a"), 0);
  
  // Context#jsend: if the last arg is a function, it'll get passed along as a &block
  
  *retval = convert_to_js(context,
    rb_funcall(ruby_context, rb_intern("jsend"), 3, self, ID2SYM(ruby_id), args));
  
  return JS_TRUE;
}

JSBool js_value_is_proxy(OurContext* context, jsval maybe_proxy)
{
  return JS_InstanceOf(context->js, JSVAL_TO_OBJECT(maybe_proxy), &JSProxyClass, NULL);
}

VALUE unwrap_js_proxy(OurContext* context, jsval proxy)
{
  VALUE value;
  assert(value = (VALUE)JS_GetInstancePrivate(context->js, proxy, &JSProxyClass, NULL));
  return value;
}

// static jsval convert_ruby_object_to_jsval(CombinedContext* context, VALUE ruby)
// {
//   VALUE self = (VALUE)JS_GetContextPrivate(context->js);
//   JSObject * js = JS_NewObject(context->js, &gRubyProxyClass, NULL, NULL);
//   if(!js) Johnson_Error_raise("failed JS_NewObject");
// 
//   rb_hash_aset( rb_iv_get(self, "@converted_objects"),
//                 rb_funcall(ruby, rb_intern("object_id"), 0),
//                 ruby );
// 
//   if(JS_SetPrivate(context->js, js, (void*)ruby) == JS_FALSE)
//     Johnson_Error_raise("failed JS_SetPrivate");
//   
//   JS_DefineFunction(context->js, js, "__noSuchMethod__",
//     Johnson_RubyProxy_method_missing, 2, 0);
//   
//   return OBJECT_TO_JSVAL(js);
// }

jsval make_js_proxy(OurContext* context, VALUE value)
{
  JSObject *js;
  
  assert(js = JS_NewObject(context->js, &JSProxyClass, NULL, NULL));
  assert(JS_SetPrivate(context->js, js, (void*)value));
  assert(JS_DefineFunction(context->js, js, "__noSuchMethod__", method_missing, 2, 0));
  
  return OBJECT_TO_JSVAL(js);
}
