#include "runtime.h"
#include "global.h"
#include "split_global.h"
#include "idhash.h"
#include "conversions.h"
#include "debugger.h"
#include "jroot.h"
#include "ruby_land_proxy.h"

#include "split_global.h"

/*
 * call-seq:
 *   global()
 *
 * Returns the global object used for this context.
 */
static VALUE global(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  JSContext * context = johnson_get_current_context(runtime);
  return convert_to_ruby(runtime, OBJECT_TO_JSVAL(runtime->global));
}

static VALUE new_global(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  JSContext * context = johnson_get_current_context(runtime);
  JSObject* obj = johnson_create_global_object(context);
  return convert_to_ruby(runtime, OBJECT_TO_JSVAL(obj));
}

static VALUE new_split_global_outer(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  JSContext * context = johnson_get_current_context(runtime);
  JSObject* new_split_global_outer_object = johnson_create_split_global_outer_object(context);
  return convert_to_ruby(runtime, OBJECT_TO_JSVAL(new_split_global_outer_object));
}

static VALUE new_split_global_inner(VALUE self, VALUE ruby_outer)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  JSContext * context = johnson_get_current_context(runtime);
  jsval outer;
  convert_to_js(runtime,ruby_outer,&outer);
  JSObject* new_inner_object = johnson_create_split_global_inner_object(context,JSVAL_TO_OBJECT(outer));
  return convert_to_ruby(runtime, OBJECT_TO_JSVAL(new_inner_object));
}

static VALUE seal(VALUE self, VALUE ruby_object, VALUE deep)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  JSContext * context = johnson_get_current_context(runtime);

  PREPARE_RUBY_JROOTS(context, 1);

  jsval object;

  JCHECK(convert_to_js(runtime,ruby_object,&object));

  JROOT(object);

  JCHECK(JS_SealObject(context, JSVAL_TO_OBJECT(object), RTEST(deep) ? JS_TRUE : JS_FALSE));
  JRETURN_RUBY(Qtrue);
}

static JSTrapStatus trap_handler( JSContext *context,
                                  JSScript *UNUSED(script),
                                  jsbytecode *UNUSED(pc),
                                  jsval *UNUSED(rval),
                                  void *block_closure )
{
  PREPARE_JROOTS(context, 0);
  VALUE block = (VALUE)block_closure;
  RB_FUNCALL_0T(block, rb_intern("call"), JSTrapStatus);
  return JSTRAP_CONTINUE;
}

/*
 * call-seq:
 *   clear_trap(script, line_num)
 *
 * Clear the trap previously set at +line_num+ of +script+.
 */
static VALUE clear_trap(VALUE self, VALUE script, VALUE linenum)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext * context = johnson_get_current_context(runtime);
  jsval compiled_js;
  if(!convert_to_js(runtime, script, &compiled_js))
    rb_raise(rb_eRuntimeError, "Couldn't get compiled script.");

  JSScript * js_script = (JSScript *)JS_GetPrivate(context, JSVAL_TO_OBJECT(compiled_js));

  jsbytecode * pc = JS_LineNumberToPC(context, js_script, (uintN)NUM2INT(linenum));
  JS_ClearTrap(context, js_script, pc, NULL, NULL);

  return self;
}

/*
 * call-seq:
 *   set_trap(script, line_num, block)
 *
 * Set a trap to invoke +block+ when execution of +script+ reaches
 * +line_num+.
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
 *   native_compile(script_string, filename, linenum)
 *
 * Compile the JavaScript code in +script_string+, marked as originating
 * from +filename+ starting at +linenum+.
 */

static VALUE native_compile(VALUE self, VALUE script, VALUE filename, VALUE linenum, VALUE ruby_global)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext * context = johnson_get_current_context(runtime);
  JohnsonContext * johnson_context = OUR_CONTEXT(context);

  JSObject* global = runtime->global;

  if ( ruby_global != Qnil ) {
    jsval js_global;
    convert_to_js(runtime, ruby_global, &js_global);
    global = JSVAL_TO_OBJECT(js_global);
  }

  JSScript * compiled_js = JS_CompileScript(
      context,
      global,
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

    // TM returns NULL with no exception on OOM: see the disccusion near JS_ReportOutOfMemory in
    // https://developer.mozilla.org/En/SpiderMonkey/JSAPI_User_Guide
    
    rb_raise(rb_eRuntimeError, "Tracemonkey reported out of memory.");
  }

  JSObject * script_object = JS_NewScriptObject(context, compiled_js);

  return make_ruby_land_proxy(runtime, OBJECT_TO_JSVAL(script_object), LEAKY_ROOT_NAME("JSScriptProxy", RTEST(filename) ? RSTRING(rb_inspect(filename))->ptr : "(?)"));
}

/*
 * call-seq:
 *   evaluate_compiled_script(script_proxy)
 *
 * Evaluate previously compiled +script_proxy+, returning the final
 * result from that script.
 */
static VALUE evaluate_compiled_script(VALUE self, VALUE compiled_script, VALUE ruby_scope)
{
  JohnsonRuntime* runtime;

  if (!ruby_value_is_script_proxy(compiled_script))
    rb_raise(rb_eArgError, "Compiled JS Script expected");

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

  JSObject* scope = runtime->global;

  if ( ruby_scope != Qnil ) {
    jsval js_scope;
    convert_to_js(runtime, ruby_scope, &js_scope);
    scope = JSVAL_TO_OBJECT(js_scope);
  }

  jsval js;
  JSBool ok = JS_ExecuteScript(context, scope, js_script, &js);

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
    } else {
      rb_raise(rb_eNoMemError,"spidermonkey ran out of memory");
    }
    return Qnil;
  }

  PREPARE_RUBY_JROOTS(context, 0);
  JRETURN_RUBY(CONVERT_TO_RUBY(runtime, js));
}

#ifdef JS_GC_ZEAL
/*
 * call-seq:
 *   gc_zeal=(level)
 *
 * Sets the GC zeal.
 *
 * 0:: Normal
 * 1:: Very Frequent
 * 2:: Extremely Frequent
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
#endif

#ifdef DEBUG
void* from = 0;
void* thing = 0;
unsigned depth = 0;
#endif DEBUG

/*
 * call-seq:
 *   gc()
 *
 * Manually initiates a TraceMonkey Garbage Collection run.
 */
static VALUE
gc(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  JSContext* context = johnson_get_current_context(runtime);

  JS_GC(context);

#ifdef DEBUG
  if(depth){
    fprintf(stderr,"dumping\n");
    JS_DumpHeap(context, stderr, from, 0, thing, depth, 0);
    fprintf(stderr,"done\n");
  }
#endif

  return Qnil;
}

/*
 * call-seq:
 *   debugger=(debugger)
 *
 * Directs the runtime to install a full set of debug hooks, using the
 * given +debugger+, which must be a Johnson::TraceMonkey::Debugger.
 */
static VALUE
set_debugger(VALUE self, VALUE debugger)
{
  JohnsonRuntime* runtime;
  JSDebugHooks* debug_hooks;

  if (!ruby_value_is_debugger(debugger))
    rb_raise(rb_eTypeError, "Expected Johnson::TraceMonkey::Debugger instance");

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

/**
 * call-seq:
 *   initialize_native(size, options)
 *
 * Create the underlying TraceMonkey runtime. This must be called
 * first, and only once. Called by +initialize+ by default.
 */
static VALUE
initialize_native(VALUE self, VALUE size, VALUE UNUSED(options))
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  size_t s = NUM2INT(size);
  if (s == 0) {
    s = 0x2000000;
  }

  if ((runtime->js = JS_NewRuntime(s))
    && (runtime->jsids = create_id_hash())
    && (runtime->rbids = create_id_hash()))
  {
    JS_SetRuntimePrivate(runtime->js, (void *)self);
    JS_SetGCCallbackRT(runtime->js, gc_callback);

    JSContext* context = johnson_get_current_context(runtime);

    if ((runtime->global = JS_GetGlobalObject(context)))
      return self;
  }

  // clean up after an initialization failure

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

static int proxy_cleanup_enumerator(JSHashEntry *entry, int /* i */, void* arg)
{
  JohnsonRuntime *runtime = (JohnsonRuntime*)(arg);
  // entry->key is jsval; entry->value is RubyLandProxy*
  RubyLandProxy * proxy = (RubyLandProxy *)(entry->value);
  JS_RemoveRootRT(runtime->js, &(proxy->key));
  proxy->runtime = NULL;
  return 0;
}

/*
static VALUE destroy(VALUE self)
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);

  fprintf(stderr,"destroy SM RT\n");

  // our gc callback can create ruby objects, so disable it
  JS_SetGCCallbackRT(runtime->js, NULL);

  JSContext *context  = NULL;
  JSContext *iterator = NULL;

  while ((context = JS_ContextIterator(runtime->js, &iterator)) != NULL) {
    JS_SetContextPrivate(iterator, NULL);
    JS_DestroyContext(iterator);
    iterator = NULL;
  }

  JSContext* cleanup = JS_NewContext(runtime->js, 8192L);
  JS_HashTableEnumerateEntries(runtime->jsids, proxy_cleanup_enumerator, runtime);
  JS_DestroyContext(cleanup);

  JS_DestroyRuntime(runtime->js);

  runtime->js = 0;

  return Qnil;
}
*/

static void deallocate(JohnsonRuntime* runtime)
{
  if (runtime->js) {
    // our gc callback can create ruby objects, so disable it
    JS_SetGCCallbackRT(runtime->js, NULL);

    JSContext *context  = NULL;
    JSContext *iterator = NULL;

    while ((context = JS_ContextIterator(runtime->js, &iterator)) != NULL) {
      JS_SetContextPrivate(iterator, NULL);
      JS_DestroyContext(iterator);
      iterator = NULL;
    }

    JSContext* cleanup = JS_NewContext(runtime->js, 8192L);
    JS_HashTableEnumerateEntries(runtime->jsids, proxy_cleanup_enumerator, runtime);
    JS_DestroyContext(cleanup);

    JS_DestroyRuntime(runtime->js);
  }

  free(runtime);
}

static VALUE allocate(VALUE klass)
{
  JohnsonRuntime* runtime = (JohnsonRuntime*)calloc(1L, sizeof(JohnsonRuntime));
  return Data_Wrap_Struct(klass, 0, deallocate, runtime);
}

void init_Johnson_TraceMonkey_Runtime(VALUE tracemonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE tracemonkey = rb_define_module_under(johnson, "TraceMonkey");
  */

  VALUE johnson = rb_const_get(rb_mKernel, rb_intern("Johnson"));
  VALUE johnson_runtime = rb_const_get(johnson, rb_intern("Runtime"));

  VALUE klass = rb_define_class_under(tracemonkey, "Runtime", johnson_runtime);

  rb_define_alloc_func(klass, allocate);
  rb_define_private_method(klass, "initialize_native", (ruby_callback)initialize_native, 2);

  rb_define_method(klass, "global", (ruby_callback)global, 0);
  rb_define_method(klass, "new_global", (ruby_callback)new_global, 0);

  rb_define_method(klass, "new_split_global_outer", (ruby_callback)new_split_global_outer, 0);
  rb_define_method(klass, "new_split_global_inner", (ruby_callback)new_split_global_inner, 1);

  rb_define_method(klass, "seal", (ruby_callback)seal, 2);

  rb_define_method(klass, "debugger=", (ruby_callback)set_debugger, 1);
  rb_define_method(klass, "gc", (ruby_callback)gc, 0);
#ifdef JS_GC_ZEAL
  rb_define_method(klass, "gc_zeal=", (ruby_callback)set_gc_zeal, 1);
#endif
  rb_define_method(klass, "evaluate_compiled_script", (ruby_callback)evaluate_compiled_script, 2);
  rb_define_private_method(klass, "native_compile", (ruby_callback)native_compile, 4);
  rb_define_method(klass, "set_trap", (ruby_callback)set_trap, 3);
  rb_define_private_method(klass, "clear_trap", (ruby_callback)clear_trap, 2);

  // rb_define_private_method(klass, "_destroy", (ruby_callback)destroy, 0);
}
