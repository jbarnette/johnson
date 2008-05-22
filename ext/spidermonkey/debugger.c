#include "debugger.h"

static JSTrapStatus interrupt_handler(JSContext *js, JSScript *script,
                                      jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("interrupt_handler"), 1, context);
  return JSTRAP_CONTINUE;
}

static void new_script_hook(JSContext *js,
                            const char *filename,
                            uintN lineno,
                            JSScript *script,
                            JSFunction *fun,
                            void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("new_script_hook"), 1, context);
}

static void destroy_script_hook(JSContext *js,
                                JSScript *script,
                                void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("destroy_script_hook"), 1, context);
}

static JSTrapStatus debugger_handler(JSContext *js, JSScript *script,
                                     jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("debugger_handler"), 1, context);
  return JSTRAP_CONTINUE;
}

static void source_handler(const char *filename, uintN lineno,
                           jschar *str, size_t length,
                           void **listenerTSData, void *rb)
{
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("source_handler"), 0);
}

static void * execute_hook(JSContext *js, JSStackFrame *fp, JSBool before,
                           JSBool *ok, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("execute_hook"), 1, context);
  return rb;
}

static void * call_hook(JSContext *js, JSStackFrame *fp, JSBool before,
                        JSBool *ok, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("call_hook"), 1, context);
  return rb;
}

static void object_hook(JSContext *js, JSObject *obj, JSBool isNew, void *rb)
{
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("object_hook"), 0);
}

static JSTrapStatus throw_hook(JSContext *js, JSScript *script,
                               jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("throw_hook"), 1, context);
  return JSTRAP_CONTINUE;
}

static JSBool debug_error_hook(JSContext *js, const char *message,
                                JSErrorReport *report, void *rb)
{
  VALUE context = (VALUE)JS_GetContextPrivate(js);
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("debug_error_hook"), 1, context);
  return JS_TRUE;
}

static void deallocate(JSDebugHooks * hooks)
{
  //free(hooks);
}

static VALUE allocate(VALUE klass)
{
  JSDebugHooks* debug = calloc(1, sizeof(JSDebugHooks));
  VALUE self = Data_Wrap_Struct(klass, 0, deallocate, debug);

  debug->interruptHandler = interrupt_handler;
  debug->interruptHandlerData = (void *)self;
  debug->newScriptHook = new_script_hook;
  debug->newScriptHookData = (void *)self;
  debug->destroyScriptHook = destroy_script_hook;
  debug->destroyScriptHookData = (void *)self;
  debug->debuggerHandler = interrupt_handler;
  debug->debuggerHandlerData = (void *)self;
  debug->sourceHandler = source_handler;
  debug->sourceHandlerData = (void *)self;
  debug->executeHook = execute_hook;
  debug->executeHookData = (void *)self;
  debug->callHook = call_hook;
  debug->callHookData = (void *)self;
  debug->objectHook = object_hook;
  debug->objectHookData = (void *)self;
  debug->throwHook = throw_hook;
  debug->throwHookData = (void *)self;
  debug->debugErrorHook = debug_error_hook;
  debug->debugErrorHookData = (void *)self;

  return self;
}

void init_Johnson_SpiderMonkey_Debugger(VALUE spidermonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  */

  /* This is the debugging hooks used with SpiderMonkey. */
  VALUE context = rb_define_class_under(spidermonkey, "Debugger", rb_cObject);

  rb_define_alloc_func(context, allocate);
}
