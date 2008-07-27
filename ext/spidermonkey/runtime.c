#include "runtime.h"
#include "global.h"
#include "idhash.h"
#include "conversions.h"
#include "jsdbgapi.h"
#include "jroot.h"
#include "ruby_land_proxy.h"

/*
 * call-seq:
 *   global
 *
 * Returns the global object used for this context.
 */
static VALUE global(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  return convert_to_ruby(runtime, OBJECT_TO_JSVAL(runtime->global));
}

static JSTrapStatus trap_handler( JSContext *UNUSED(context),
                                  JSScript *UNUSED(script),
                                  jsbytecode *UNUSED(pc),
                                  jsval *UNUSED(rval),
                                  void *block_closure )
{
  VALUE block = (VALUE)block_closure;
  rb_funcall(block, rb_intern("call"), 0);
  return JSTRAP_CONTINUE;
}

/*
 * call-seq:
 *   set_trap(script, parsecode, block)
 *
 * Set the trap at +script+ and +parsecode+ to +block+
 */
static VALUE set_trap(VALUE self, VALUE script, VALUE linenum, VALUE block)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext * context = johnson_get_current_context(runtime);
  jsval compiled_js;
  if(!convert_to_js(runtime, script, &compiled_js))
    rb_raise(rb_eRuntimeError, "Couldn't get compiled script.");
  JSScript * js_script = (JSScript *)JS_GetPrivate(context, JSVAL_TO_OBJECT(compiled_js));

  jsbytecode * pc = JS_LineNumberToPC(context, js_script, (uintN)NUM2INT(linenum));
  return JS_SetTrap(context, js_script, pc, trap_handler, (void*)block) ? Qtrue : Qfalse;
}

/*
 * call-seq:
 *   native_compile(script, filename, linenum)
 *
 * Compile +script+ with +filename+ using +linenum+
 */
static VALUE native_compile(VALUE self, VALUE script, VALUE filename, VALUE linenum)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext * context = johnson_get_current_context(runtime);
  JohnsonContext * johnson_context = OUR_CONTEXT(context);

  JSScript * compiled_js = JS_CompileScript(
      context,
      runtime->global,
      StringValuePtr(script),
      (size_t)StringValueLen(script),
      StringValueCStr(filename),
      (unsigned)NUM2INT(linenum)
  );
  if(compiled_js == NULL) {
    if (JS_IsExceptionPending(context))
    {
      // If there's an exception pending here, it's a syntax error.
      JS_GetPendingException(context, &johnson_context->ex);
      JS_ClearPendingException(context);
    }

    if (johnson_context->ex) {
      RAISE_JS_ERROR(self, johnson_context->ex);
      return Qnil;
    }
  }

  JSObject * script_object = JS_NewScriptObject(context, compiled_js);

  PREPARE_RUBY_JROOTS(context, 1);
  JROOT(script_object);
  JRETURN_RUBY(make_ruby_land_proxy(runtime, OBJECT_TO_JSVAL(script_object), "JSScriptProxy"));
}

/*
 * call-seq:
 *   evaluate_compiled_script(script)
 *
 * Evaluate +script+
 */
static VALUE evaluate_compiled_script(VALUE self, VALUE compiled_script)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext * context = johnson_get_current_context(runtime);
  JohnsonContext * johnson_context = OUR_CONTEXT(context);

  // clean things up first
  johnson_context->ex = 0;
  memset(johnson_context->msg, 0, MAX_EXCEPTION_MESSAGE_SIZE);

  jsval compiled_js;
  if(!convert_to_js(runtime, compiled_script, &compiled_js))
    rb_raise(rb_eRuntimeError, "Script compilation failed");

  JSScript * js_script = (JSScript *)JS_GetPrivate(context, JSVAL_TO_OBJECT(compiled_js));

  jsval js;
  JSBool ok = JS_ExecuteScript(context, runtime->global, js_script, &js);

  if (!ok)
  {
    if (JS_IsExceptionPending(context))
    {
      // If there's an exception pending here, it's a syntax error.
      JS_GetPendingException(context, &johnson_context->ex);
      JS_ClearPendingException(context);
    }

    if (johnson_context->ex) {
      RAISE_JS_ERROR(self, johnson_context->ex);
      return Qnil;
    }
  }

  return convert_to_ruby(runtime, js);
}

/*
 * call-seq:
 *   gc_zeal=(level)
 *
 * Sets the GC zeal.
 * 0 = normal, 1 = Very Frequent, 2 = Extremely Frequent
 */
static VALUE
set_gc_zeal(VALUE self, VALUE zeal)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext* context = johnson_get_current_context(runtime);

  JS_SetGCZeal(context, NUM2INT(zeal));

  return zeal;
}

/*
 * call-seq:
 *   debugger=(debugger)
 *
 * Sets a debugger object
 */
static VALUE
set_debugger(VALUE self, VALUE debugger)
{
  JohnsonRuntime* runtime;
  JSDebugHooks* debug_hooks;

  rb_iv_set(self, "@debugger", debugger);
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  Data_Get_Struct(debugger, JSDebugHooks, debug_hooks);

  JSContext * context = johnson_get_current_context(runtime);

  JS_SetInterrupt(          runtime->js,
                            debug_hooks->interruptHandler,
                            debug_hooks->interruptHandlerData);
  JS_SetNewScriptHook(      runtime->js,
                            debug_hooks->newScriptHook,
                            debug_hooks->newScriptHookData);
  JS_SetDestroyScriptHook(  runtime->js,
                            debug_hooks->destroyScriptHook,
                            debug_hooks->destroyScriptHookData);
  JS_SetDebuggerHandler(    runtime->js,
                            debug_hooks->debuggerHandler,
                            debug_hooks->debuggerHandlerData);
  JS_SetSourceHandler(      runtime->js,
                            debug_hooks->sourceHandler,
                            debug_hooks->sourceHandlerData);
  JS_SetExecuteHook(        runtime->js,
                            debug_hooks->executeHook,
                            debug_hooks->executeHookData);
  JS_SetCallHook(           runtime->js,
                            debug_hooks->callHook,
                            debug_hooks->callHookData);
  JS_SetObjectHook(         runtime->js,
                            debug_hooks->objectHook,
                            debug_hooks->objectHookData);
  JS_SetThrowHook(          runtime->js,
                            debug_hooks->throwHook,
                            debug_hooks->throwHookData);
  JS_SetDebugErrorHook(     runtime->js,
                            debug_hooks->debugErrorHook,
                            debug_hooks->debugErrorHookData);

  JS_SetContextDebugHooks(context, debug_hooks);

  return debugger;
}

JSBool gc_callback(JSContext *context, JSGCStatus status)
{
  if(status == JSGC_BEGIN) {
    VALUE ruby_runtime = (VALUE)JS_GetRuntimePrivate(JS_GetRuntime(context));
    if(rb_funcall(ruby_runtime, rb_intern("should_sm_gc?"), 0) == Qtrue)
      return JS_TRUE;
  }
  return JS_FALSE;
}

static VALUE
initialize_native(VALUE self, VALUE UNUSED(options))
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  
  if ((runtime->js = JS_NewRuntime(0x100000))
    && (runtime->jsids = create_id_hash())
    && (runtime->rbids = create_id_hash())
  )
  {
    JS_SetRuntimePrivate(runtime->js, (void *)self);
    JS_SetGCCallbackRT(runtime->js, gc_callback);

    JSContext* context = johnson_get_current_context(runtime);
    if(
        (runtime->global = JS_GetGlobalObject(context))
        && (JS_AddNamedRoot(context, &(runtime->global), "runtime->global"))
    ) {
      return self;
    }
  }


  if (runtime->rbids)
    JS_HashTableDestroy(runtime->rbids);

  if (runtime->jsids)
    JS_HashTableDestroy(runtime->jsids);

  if (runtime->js)
    JS_DestroyRuntime(runtime->js);
    
  rb_raise(rb_eRuntimeError, "Couldn't initialize the runtime!");
  return Qnil;
}

JSContext* johnson_get_current_context(JohnsonRuntime * runtime)
{
  JohnsonContext * context = NULL;
  VALUE self = (VALUE)JS_GetRuntimePrivate(runtime->js);
  Data_Get_Struct(rb_funcall(self, rb_intern("current_context"), 0), JohnsonContext, context);
  return context->js;
}

static void deallocate(JohnsonRuntime* runtime)
{
  JS_RemoveRoot(johnson_get_current_context(runtime), &(runtime->global));
  
  JSContext *context;
  JSContext *iterator = NULL;

  while ((context = JS_ContextIterator(runtime->js, &iterator)) != NULL)
    JS_DestroyContext(context);
  
  JS_DestroyRuntime(runtime->js);
  free(runtime);
}

static VALUE allocate(VALUE klass)
{
  JohnsonRuntime* runtime = calloc(1L, sizeof(JohnsonRuntime));
  return Data_Wrap_Struct(klass, 0, deallocate, runtime);
}

void init_Johnson_SpiderMonkey_Runtime(VALUE spidermonkey)
{
  VALUE klass = rb_define_class_under(spidermonkey, "Runtime", rb_cObject);

  rb_define_alloc_func(klass, allocate);
  rb_define_private_method(klass, "initialize_native", initialize_native, 1);

  rb_define_method(klass, "global", global, 0);
  rb_define_method(klass, "debugger=", set_debugger, 1);
  rb_define_method(klass, "gc_zeal=", set_gc_zeal, 1);
  rb_define_method(klass, "evaluate_compiled_script", evaluate_compiled_script, 1);
  rb_define_private_method(klass, "native_compile", native_compile, 3);
  rb_define_private_method(klass, "set_trap", set_trap, 3);
}
