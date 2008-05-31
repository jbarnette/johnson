#include "debugger.h"
#include "context.h"
#include "conversions.h"
#include "immutable_node.h"

static JSTrapStatus interrupt_handler(JSContext *js, JSScript *UNUSED(script),
                                      jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_bytecode = jsop_to_symbol(*pc);
  VALUE rb_rval = convert_to_ruby(OUR_RUNTIME(js), *rval);
  return NUM2INT(rb_funcall(self, rb_intern("interrupt_handler"), 2, rb_bytecode, rb_rval));
}

static void new_script_hook(JSContext *UNUSED(js),
                            const char *filename,
                            uintN lineno,
                            JSScript *UNUSED(script),
                            JSFunction *UNUSED(fun),
                            void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_filename = rb_str_new2(filename);
  VALUE rb_linenum  = UINT2NUM(lineno);

  /* FIXME: Pass the rest of this crap to the debugger? */
  rb_funcall(self, rb_intern("new_script_hook"), 2, rb_filename, rb_linenum);
}

static void destroy_script_hook(JSContext *UNUSED(js),
                                JSScript *UNUSED(script),
                                void *rb)
{
  VALUE self = (VALUE)rb;
  rb_funcall(self, rb_intern("destroy_script_hook"), 0);
}

static JSTrapStatus debugger_handler(JSContext *js, JSScript *UNUSED(script),
                                     jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_bytecode = jsop_to_symbol(*pc);
  VALUE rb_rval = convert_to_ruby(OUR_RUNTIME(js), *rval);
  return NUM2INT(rb_funcall(self, rb_intern("debugger_handler"), 2, rb_bytecode, rb_rval));
}

static void source_handler(const char *filename, uintN lineno,
                           jschar *str, size_t length,
                           void **UNUSED(listenerTSData), void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_filename = rb_str_new2(filename);
  VALUE rb_lineno   = UINT2NUM(lineno);
  VALUE rb_str      = rb_str_new((char *)str, (signed)(length * sizeof(jschar)));

  rb_funcall(self, rb_intern("source_handler"), 3, rb_filename, rb_lineno, rb_str);
}

static void * execute_hook(JSContext *UNUSED(js), JSStackFrame *UNUSED(fp), JSBool before,
                           JSBool *ok, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_before = JS_TRUE == before ? Qtrue : Qfalse;
  VALUE rb_ok     = ok ? Qtrue : Qfalse;

  rb_funcall(self, rb_intern("execute_hook"), 2, rb_before, rb_ok);
  return rb;
}

static void * call_hook(JSContext *UNUSED(js), JSStackFrame *UNUSED(fp), JSBool before,
                           JSBool *ok, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_before = before ? Qtrue : Qfalse;
  VALUE rb_ok     = ok ? Qtrue : Qfalse;

  rb_funcall(self, rb_intern("call_hook"), 2, rb_before, rb_ok);
  return rb;
}

static void object_hook(JSContext *js, JSObject *obj, JSBool isNew, void *rb)
{
  VALUE self = (VALUE)rb;

  VALUE rb_obj = convert_to_ruby(OUR_RUNTIME(js), OBJECT_TO_JSVAL(obj));
  VALUE rb_is_new = isNew ? Qtrue : Qfalse;

  rb_funcall(self, rb_intern("object_hook"), 2, rb_obj, rb_is_new);
}

static JSTrapStatus throw_hook(JSContext *js, JSScript *UNUSED(script),
                               jsbytecode *pc, jsval *rval, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_bytecode = jsop_to_symbol(*pc);
  VALUE rb_rval = convert_to_ruby(OUR_RUNTIME(js), *rval);
  return NUM2INT(rb_funcall(self, rb_intern("throw_hook"), 2, rb_bytecode, rb_rval));
}

static JSBool debug_error_hook(JSContext *UNUSED(js), const char *message,
                                JSErrorReport *UNUSED(report), void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_message = rb_str_new2(message);
  rb_funcall(self, rb_intern("debug_error_hook"), 1, rb_message);
  return JS_TRUE;
}

static VALUE allocate(VALUE klass)
{
  JSDebugHooks* debug = calloc(1, sizeof(JSDebugHooks));
  VALUE self = Data_Wrap_Struct(klass, 0, 0, debug);

  debug->interruptHandler = interrupt_handler;
  debug->interruptHandlerData = (void *)self;
  debug->newScriptHook = new_script_hook;
  debug->newScriptHookData = (void *)self;
  debug->destroyScriptHook = destroy_script_hook;
  debug->destroyScriptHookData = (void *)self;
  debug->debuggerHandler = debugger_handler;
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
