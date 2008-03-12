#include "context.h"
#include "error.h"

static VALUE evaluate(VALUE self, VALUE script)
{
  return Qnil;
}

static VALUE get(VALUE self, VALUE name)
{
  return Qnil;
}

static VALUE set(VALUE self, VALUE name, VALUE value)
{
  return Qnil;
}

static void error(JSContext* js, const char* message, JSErrorReport* report)
{
  printf("UNHANDLED ERROR: %s\n", message);
  assert(0); // FIXME
}

static void deallocate(OurContext* context)
{
  JS_DestroyContext(context->js);
  JS_DestroyRuntime(context->runtime);
  free(context);
}

static VALUE allocate(VALUE klass)
{
  OurContext* context = calloc(1, sizeof(OurContext));
  
  // FIXME: Don't hardcode these values, possibly move to initialize
  // FIXME: why do we need a runtime for each context?

  assert(context->runtime = JS_NewRuntime(0x100000));
  assert(context->js = JS_NewContext(context->runtime, 8192));
  assert(context->global = JS_NewObject(context->js, &OurGlobalClass, NULL, NULL));
  assert(JS_InitStandardClasses(context->js, context->global));
  
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
