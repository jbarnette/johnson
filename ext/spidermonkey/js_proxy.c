#include "js_proxy.h"

static void finalize(JSContext* context, JSObject* obj)
{
  
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

static JSBool get(JSContext* context, JSObject* obj, jsval id, jsval* retval)
{
  return JS_FALSE;
}


// JSBool Johnson_RubyProxy_get( JSContext * js_context,
//                                           JSObject * obj,
//                                           jsval id,
//                                           jsval *vp )
// {
//   VALUE ruby_obj;
//   ID rid;
//   VALUE method, return_value;
//   char * keyname;
//   jsval foo;
//   CombinedContext* context;
//   VALUE rb_keyname;
//   VALUE hash_value;
// 
//   VALUE self = (VALUE)JS_GetContextPrivate(js_context);
//   Data_Get_Struct(self, CombinedContext, context);
// 
//   keyname = JS_GetStringBytes(JSVAL_TO_STRING(id));
//   ruby_obj = (VALUE)JS_GetInstancePrivate(js_context, obj, &gRubyProxyClass, NULL);
//   if(!ruby_obj)
//     Johnson_Error_raise("failed JS_GetInstancePrivate");
// 
//   rid = rb_intern(keyname);
//   rb_keyname = rb_str_new2(keyname);
// 
//   if(rb_funcall(ruby_obj, rb_intern("respond_to?"), 1, ID2SYM(rid))) {
//     VALUE method = rb_funcall(ruby_obj, rb_intern("method"), 1,ID2SYM(rid));
//     int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
//     if(arity == 0)
//       *vp = convert_ruby_to_jsval(context, rb_funcall(ruby_obj, rid, 0));
//   } else if(
//     rb_funcall(ruby_obj, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]"))) &&
//     rb_funcall(ruby_obj, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("key?")))
//   )
//   {
//     *vp = convert_ruby_to_jsval(context,
//       rb_funcall(ruby_obj, rb_intern("[]"), 1, rb_keyname)
//     );
//   }
// 
//   return JS_TRUE;
// }
// 

static JSBool set(JSContext* context, JSObject* obj, jsval id, jsval* retval)
{
  return JS_FALSE;
}

// JSBool Johnson_RubyProxy_set( JSContext * js_context,
//                                           JSObject * obj,
//                                           jsval id,
//                                           jsval *vp )
// {
//   char * keyname;
//   VALUE ruby_obj;
//   VALUE rb_keyname;
//   VALUE setter;
//   CombinedContext* context;
//   ID rid;
// 
//   VALUE self = (VALUE)JS_GetContextPrivate(js_context);
//   Data_Get_Struct(self, CombinedContext, context);
// 
//   keyname = JS_GetStringBytes(JSVAL_TO_STRING(id));
//   ruby_obj = (VALUE)JS_GetPrivate(js_context, obj);
//   rb_keyname = rb_str_new2(keyname);
// 
//   setter = rb_str_append(rb_str_new3(rb_keyname), rb_str_new2("="));
//   rid = rb_intern(StringValuePtr(setter));
// 
//   if(rb_funcall(ruby_obj, rb_intern("respond_to?"), 1, ID2SYM(rid))) {
//     VALUE method = rb_funcall(ruby_obj, rb_intern("method"), 1,ID2SYM(rid));
//     int arity = NUM2INT(rb_funcall(method, rb_intern("arity"), 0));
//     if(arity == 1)
//       convert_ruby_to_jsval(context,
//         rb_funcall(ruby_obj, rid, 1, convert_jsval_to_ruby(context, *vp))
//       );
//   } else if(
//     rb_funcall(ruby_obj, rb_intern("respond_to?"), 1, ID2SYM(rb_intern("[]=")))
//   )
//   {
//     rb_funcall(ruby_obj, rb_intern("[]="), 2, rb_keyname,
//         convert_jsval_to_ruby(context, *vp)
//     );
//   }
//   return JS_TRUE;
// }
// 

static JSBool method_missing(JSContext* context, JSObject* obj, uintN argc, jsval* argv, jsval* retval)
{
  return JS_FALSE;
}
// JSBool Johnson_RubyProxy_method_missing( JSContext *js_context,
//                                       JSObject *jsobj,
//                                       uintN argc,
//                                       jsval *argv,
//                                       jsval *rval )
// {
//   char *keyname;
//   VALUE ruby_obj, ruby_argv, return_value;
//   ID rid;
//   CombinedContext* context;
//   JSObject * args;
//   int arg_length;
// 
//   VALUE self = (VALUE)JS_GetContextPrivate(js_context);
//   Data_Get_Struct(self, CombinedContext, context);
// 
//   args = JSVAL_TO_OBJECT(argv[1]);
// 
//   ruby_obj = (VALUE)JS_GetInstancePrivate(js_context, jsobj, &gRubyProxyClass, NULL);
//   if(!ruby_obj)
//     Johnson_Error_raise("failed JS_GetInstancePrivate");
// 
//   keyname = JS_GetStringBytes(JSVAL_TO_STRING(argv[0]));
//   rid = rb_intern(keyname);
// 
//   ruby_argv = convert_jsval_to_ruby(context, argv[1]);
// 
//   if(RARRAY_LEN(ruby_argv) == 0) {
//     return_value = rb_funcall(ruby_obj, rid, 0);
//     *rval = convert_ruby_to_jsval(context, return_value);
//   } else {
//     return_value = 
//       rb_funcall2(ruby_obj, rid, RARRAY_LEN(ruby_argv),RARRAY_PTR(ruby_argv));
//     *rval = convert_ruby_to_jsval(context, return_value);
//   }
// 
//   return JS_TRUE;
// }

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

JSBool js_value_is_proxy(jsval maybe_proxy)
{
  return JS_FALSE;
}

VALUE unwrap_js_proxy(OurContext* context, jsval proxy)
{
  return Qnil;
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
  return JSVAL_NULL;
}
