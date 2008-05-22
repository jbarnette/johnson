#include "debugger.h"

static JSTrapStatus interrupt_handler(JSContext *cx, JSScript *script,
                                      jsbytecode *pc, jsval *rval, void *rb)
{
}

static void new_script_hook(JSContext *cx,
                            const char *filename,
                            uintN lineno,
                            JSScript *script,
                            JSFunction *fun,
                            void *rb)
{
}

static void destroy_script_hook(JSContext *cx,
                                JSScript *script,
                                void *rb)
{
}

static JSTrapStatus debugger_handler(JSContext *cx, JSScript *script,
                                     jsbytecode *pc, jsval *rval, void *rb)
{
}

static void source_handler(const char *filename, uintN lineno,
                           jschar *str, size_t length,
                           void **listenerTSData, void *rb)
{
}

static void * execute_hook(JSContext *cx, JSStackFrame *fp, JSBool before,
                           JSBool *ok, void *rb)
{
}

static void * call_hook(JSContext *cx, JSStackFrame *fp, JSBool before,
                        JSBool *ok, void *rb)
{
}

static void object_hook(JSContext *cx, JSObject *obj, JSBool isNew, void *rb)
{
}

static JSTrapStatus throw_hook(JSContext *cx, JSScript *script,
                               jsbytecode *pc, jsval *rval, void *rb)
{
}

static JSBool debug_error_hook(JSContext *cx, const char *message,
                                JSErrorReport *report, void *rb)
{
}

static void deallocate(JSDebugHooks * hooks)
{
  free(hooks);
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
