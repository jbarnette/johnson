#include "context.h"
#include "conversions.h"
#include "error.h"
#include "idhash.h"

static VALUE evaluate(VALUE self, VALUE script)
{
  Check_Type(script, T_STRING);
  
  OurContext* context;
  Data_Get_Struct(self, OurContext, context);
    
  // clean things up first
  context->ex = 0;
  memset(context->msg, 0, MAX_EXCEPTION_MESSAGE_SIZE);  
  
  char* scriptz = StringValuePtr(script);
  jsval js;
    
  JSBool ok = JS_EvaluateScript(context->js, context->global,
    scriptz, strlen(scriptz), NULL, 1, &js);

  if (!ok)
  {
    if (JS_IsExceptionPending(context->js))
    {
      // If there's an exception pending here, it's a syntax error.
      JS_GetPendingException(context->js, &context->ex);
      JS_ClearPendingException(context->js);
    }

    char* msg = context->msg;
        
    // toString() whatever the exception object is (if we have one)
    if (context->ex) msg = JS_GetStringBytes(JS_ValueToString(context->js, context->ex));
    
    return Johnson_Error_raise(msg);
  }

  return convert_to_ruby(context, js);
}

static VALUE get(VALUE self, VALUE name)
{
  Check_Type(name, T_STRING);
  
  OurContext* context;
  Data_Get_Struct(self, OurContext, context);
  
  jsval js_value;  
  assert(JS_GetProperty(context->js, context->global, StringValuePtr(name), &js_value));
  
  return convert_to_ruby(context, js_value);
}

static VALUE set(VALUE self, VALUE name, VALUE value)
{
  Check_Type(name, T_STRING);
  
  OurContext* context;
  Data_Get_Struct(self, OurContext, context);
  
  jsval js_value = convert_to_js(context, value);
  assert(JS_SetProperty(context->js, context->global, StringValuePtr(name), &js_value));
  
  return value;
}

static void error(JSContext* js, const char* message, JSErrorReport* report)
{
  // first we find ourselves
  VALUE self = (VALUE)JS_GetContextPrivate(js);
  
  // then we find our bridge
  OurContext* context;
  Data_Get_Struct(self, OurContext, context);
  
  // NOTE: SpiderMonkey REALLY doesn't like being interrupted. If we
  // jump over to Ruby and raise here, segfaults and such ensue.
  // Instead, we store the exception (if any) and the error message
  // on the context. They're dealt with in the if (!ok) block of evaluate().
  
  strncpy(context->msg, message, MAX_EXCEPTION_MESSAGE_SIZE);
  JS_GetPendingException(context->js, &context->ex);
}

static void deallocate(OurContext* context)
{
  JS_SetContextPrivate(context->js, 0);
  
  assert(JS_RemoveRoot(context->js, &(context->gcthings)));
  JS_HashTableDestroy(context->jsids);
  
  JS_DestroyContext(context->js);
  JS_DestroyRuntime(context->runtime);
  
  free(context);
}

static VALUE allocate(VALUE klass)
{
  OurContext* context = calloc(1, sizeof(OurContext));
  
  assert(context->runtime  = JS_NewRuntime(0x100000));
  assert(context->js = JS_NewContext(context->runtime, 8192));

  assert(context->jsids = create_jsids_hash());  
  assert(context->gcthings = JS_NewObject(context->js, NULL, 0, 0));
  assert(context->global = JS_NewObject(context->js, &OurGlobalClass, NULL, NULL));
  
  assert(JS_InitStandardClasses(context->js, context->global));
  assert(JS_AddRoot(context->js, &(context->gcthings)));
    
  VALUE self = Data_Wrap_Struct(klass, 0, deallocate, context);

  JS_SetErrorReporter(context->js, error);
  JS_SetContextPrivate(context->js, (void *)self);

  return self;
}

void init_Johnson_SpiderMonkey_Context(VALUE spidermonkey)
{
  VALUE context = rb_define_class_under(spidermonkey, "Context", rb_cObject);

  rb_define_alloc_func(context, allocate);
  rb_define_method(context, "evaluate", evaluate, 1);
  rb_define_method(context, "[]", get, 1);
  rb_define_method(context, "[]=", set, 2);  
}
