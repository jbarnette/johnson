#include "debugger.h"
#include "context.h"
#include "conversions.h"
#include "immutable_node.h"

static VALUE debugger_class = Qnil;

bool ruby_value_is_debugger(VALUE maybe_debugger)
{
  VALUE klass = CLASS_OF(maybe_debugger);
  return (klass == debugger_class);
}

/*
 * call-seq:
 *   frame_pc(context, frame)
 *
 * Get the frame parse context
 */
static VALUE frame_pc(VALUE UNUSED(self), VALUE context, VALUE frame)
{
  JSContext * js = NULL;
  JSStackFrame * fp = NULL;
  Data_Get_Struct(context, JSContext, js);
  Data_Get_Struct(frame, JSStackFrame, fp);
  return Data_Wrap_Struct(rb_cObject, NULL, NULL, JS_GetFramePC(js, fp));
}

/*
 * call-seq:
 *   line_number(context, script, bytecode)
 *
 * Get the line number of the +bytecode+ given +context+ and +script+
 */
static VALUE line_number(VALUE UNUSED(self), VALUE context, VALUE script, VALUE bytecode)
{
  JSContext * js        = NULL;
  JSScript * js_script     = NULL;
  jsbytecode * js_bytecode = NULL;

  Data_Get_Struct(context, JSContext, js);
  Data_Get_Struct(script, JSScript, js_script);
  Data_Get_Struct(bytecode, jsbytecode, js_bytecode);

  return INT2NUM((long)JS_PCToLineNumber(js, js_script, js_bytecode));
}

/*
 * call-seq:
 *   file_name(context, script)
 *
 * Get the file name of the +script+ given +context+
 */
static VALUE file_name(VALUE UNUSED(self), VALUE context, VALUE script)
{
  JSContext * js        = NULL;
  JSScript * js_script     = NULL;

  Data_Get_Struct(context, JSContext, js);
  Data_Get_Struct(script, JSScript, js_script);

  return rb_str_new2(JS_GetScriptFilename(js, js_script));
}

static JSTrapStatus interrupt_handler(JSContext *js, JSScript *script,
                                      jsbytecode *pc, jsval *UNUSED(rval), void *rb)
{
  assert(js);
  assert(rb);
  assert(pc);

  VALUE self = (VALUE)rb;
  VALUE rb_cx     = Data_Wrap_Struct(rb_cObject, NULL, NULL, js);
  VALUE rb_script = Data_Wrap_Struct(rb_cObject, NULL, NULL, script);
  VALUE rb_pc     = Data_Wrap_Struct(rb_cObject, NULL, NULL, pc);

  return (JSTrapStatus)NUM2INT(rb_funcall(self, rb_intern("interrupt_handler"), 3,
        rb_cx,
        rb_script,
        rb_pc
        ));
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
  VALUE rb_linenum  = UINT2NUM((unsigned long)lineno);

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

static JSTrapStatus debugger_handler(JSContext *js, JSScript *script,
                                     jsbytecode *pc, jsval *UNUSED(rval), void *rb)
{
  assert(js);
  assert(rb);
  assert(pc);

  VALUE self = (VALUE)rb;
  VALUE rb_cx     = Data_Wrap_Struct(rb_cObject, NULL, NULL, js);
  VALUE rb_script = Data_Wrap_Struct(rb_cObject, NULL, NULL, script);
  VALUE rb_pc     = Data_Wrap_Struct(rb_cObject, NULL, NULL, pc);

  return (JSTrapStatus)NUM2INT(rb_funcall(self, rb_intern("debugger_handler"), 3,
        rb_cx,
        rb_script,
        rb_pc
        ));
}

static void source_handler(const char *filename, uintN lineno,
                           jschar *str, size_t length,
                           void **UNUSED(listenerTSData), void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_filename = rb_str_new2(filename);
  VALUE rb_lineno   = ULONG2NUM((unsigned long)lineno);
  VALUE rb_str      = rb_str_new((char *)str, (signed long)(length * sizeof(jschar)));

  rb_funcall(self, rb_intern("source_handler"), 3, rb_filename, rb_lineno, rb_str);
}

static void * execute_hook(JSContext *js, JSStackFrame *fp, JSBool before,
                           JSBool *ok, void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_before = JS_TRUE == before ? Qtrue : Qfalse;
  VALUE rb_ok     = ok ? Qtrue : Qfalse;
  VALUE rb_js     = Data_Wrap_Struct(rb_cObject, NULL, NULL, (void *)js);
  VALUE rb_fp     = Data_Wrap_Struct(rb_cObject, NULL, NULL, (void *)fp);

  rb_funcall(self, rb_intern("execute_hook"), 4, rb_js,rb_fp,rb_before,rb_ok);
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
  assert(rb);
  assert(js);
  assert(obj);
  VALUE self = (VALUE)rb;

  VALUE rb_is_new = isNew ? Qtrue : Qfalse;

  rb_funcall(self, rb_intern("object_hook"), 1, rb_is_new);
}

static JSTrapStatus throw_hook(JSContext *UNUSED(js), JSScript *UNUSED(script),
                               jsbytecode *pc, jsval *UNUSED(rval), void *rb)
{
  VALUE self = (VALUE)rb;
  VALUE rb_bytecode = jsop_to_symbol(*pc);
  return (JSTrapStatus)NUM2INT(rb_funcall(self, rb_intern("throw_hook"), 1, rb_bytecode));
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
  JSDebugHooks* debug = (JSDebugHooks*)calloc(1L, sizeof(JSDebugHooks));
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

void init_Johnson_TraceMonkey_Debugger(VALUE tracemonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE tracemonkey = rb_define_module_under(johnson, "TraceMonkey");
  */

  /* This is the debugging hooks used with TraceMonkey. */
  debugger_class = rb_define_class_under(tracemonkey, "Debugger", rb_cObject);
  rb_define_private_method(debugger_class, "frame_pc", (ruby_callback)frame_pc, 2);
  rb_define_private_method(debugger_class, "line_number", (ruby_callback)line_number, 3);
  rb_define_private_method(debugger_class, "file_name", (ruby_callback)file_name, 2);

  rb_define_alloc_func(debugger_class, allocate);
}
