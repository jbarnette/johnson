#include "js_function_proxy.h"

static JSBool call_proc(JSContext *js_context, JSObject* this, uintN argc, jsval* argv, jsval* ret)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context);
  
  OurContext* context;
  Data_Get_Struct(ruby_context, OurContext, context);

  JSFunction* callee = JS_ValueToFunction(js_context, JS_ARGV_CALLEE(argv));
  
  jsval oid;
  
  assert(JS_GetProperty(context->js,
    JS_GetFunctionObject(callee),
    JS_FUNCTION_PROXY_PROPERTY, &oid));
    
  VALUE args = rb_ary_new3(1, INT2NUM(JSVAL_TO_INT(oid)));
  
  int i;
  
  for (i = 0; i < argc; ++i)
    rb_ary_push(args, convert_to_ruby(context, argv[i]));

  *ret = convert_to_js(context,
    rb_funcall2(ruby_context, rb_intern("call_proc_by_oid"), RARRAY_LEN(args), RARRAY_PTR(args)));

  return JS_TRUE;
}

JSBool js_value_is_function_proxy(OurContext* context, jsval maybe_function_proxy)
{
  JSBool flag;
  
  JS_HasProperty(context->js,
    JSVAL_TO_OBJECT(maybe_function_proxy),
    JS_FUNCTION_PROXY_PROPERTY, &flag);
     
  return flag;
}

VALUE unwrap_js_function_proxy(OurContext* context, jsval function_proxy)
{
  VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
  jsval oid;
  
  assert(JS_GetProperty(context->js,
    JS_GetFunctionObject(JS_ValueToFunction(context->js, function_proxy)),
    JS_FUNCTION_PROXY_PROPERTY, &oid));
  
  return rb_funcall(ruby_context, rb_intern("id2ref"), 1, INT2NUM(JSVAL_TO_INT(oid)));
}


jsval make_js_function_proxy(OurContext* context, VALUE proc)
{
  jsid id = (jsid)JS_HashTableLookup(context->rbids, (void *)rb_obj_id(proc));
  jsval js;
  
  if (id)
  {
    assert(JS_IdToValue(context->js, id, &js));
  }
  else
  {
    JSObject* function = JS_GetFunctionObject(
      JS_NewFunction(context->js, call_proc, 0, 0, NULL, ""));

    jsval oid = INT_TO_JSVAL(NUM2INT(rb_obj_id(proc)));
    assert(JS_SetProperty(context->js, function, JS_FUNCTION_PROXY_PROPERTY, &oid));

    js = OBJECT_TO_JSVAL(function);

    jsval newid;
    assert(JS_ValueToId(context->js, js, &newid));
  
    // put the proxy OID in the id map
    assert(JS_HashTableAdd(context->rbids, (void *)rb_obj_id(proc), (void *)newid));
    
    // root the ruby value for GC
    // FIXME: this is pretty much copy/paste from js_land_proxy.c
    // FIXME: no custom finalizer on JSFunction, so never freed!
    VALUE ruby_context = (VALUE)JS_GetContextPrivate(context->js);
    rb_funcall(ruby_context, rb_intern("add_gcthing"), 1, proc);
  }
  
  return js;
}
