#include "context.h"
#include "conversions.h"
#include "global.h"
#include "extensions.h"
#include "idhash.h"
#include "jsdbgapi.h"

// callback for JS_SetErrorReporter
static void report_js_error(JSContext* js, const char* message, JSErrorReport* UNUSED(report))
{
  // first we find ourselves
  VALUE self = (VALUE)JS_GetContextPrivate(js);

  // then we find our bridge
  JohnsonContext* context;
  Data_Get_Struct(self, JohnsonContext, context);

  // NOTE: TraceMonkey REALLY doesn't like being interrupted. If we
  // jump over to Ruby and raise here, segfaults and such ensue.
  // Instead, we store the exception (if any) and the error message
  // on the context. They're dealt with in the if (!ok) block of evaluate().

  strncpy(context->msg, message, MAX_EXCEPTION_MESSAGE_SIZE);
  JS_GetPendingException(context->js, &context->ex);
}

// callback for JS_SetOperationCallback
static JSBool operation_callback(JSContext* js)
{
  static unsigned long operation_counter = 0;
  if( ++operation_counter % 0x1000 == 0 )
    JS_MaybeGC( js );
  return JS_TRUE;
}

/*
 * call-seq:
 *   native_initialize(runtime, options)
 *
 * Create the underlying TraceMonkey context. This must be called
 * first, and only once. Called by +initialize+ by default.
 */
static VALUE
initialize_native(VALUE self, VALUE rb_runtime, VALUE UNUSED(options))
{
  JohnsonContext* context;
  JohnsonRuntime* runtime;

  Data_Get_Struct(self, JohnsonContext, context);
  Data_Get_Struct(rb_runtime, JohnsonRuntime, runtime);

  if ((context->js = JS_NewContext(runtime->js, 8192L)))
  {
    // See if the runtime already has a shared global object.
    JSObject* global = runtime->global;

    // If it does, use it. If not,
    if (!global)
      // create one of our global objects.
      global = johnson_create_global_object(context->js);

    // Manually set the context's global object.
    JS_SetGlobalObject(context->js, global);
    JS_SetErrorReporter(context->js, report_js_error);
    JS_SetOperationCallback(context->js, operation_callback);
    JS_SetContextPrivate(context->js, (void *)self);

    JS_SetOptions(context->js, JS_GetOptions(context->js)
#ifdef JSOPTION_DONT_REPORT_UNCAUGHT
        | JSOPTION_DONT_REPORT_UNCAUGHT
#endif
#ifdef JSOPTION_VAROBJFIX
        | JSOPTION_VAROBJFIX
#endif
#ifdef JSOPTION_ATLINE
        | JSOPTION_ATLINE
#endif
#ifdef JSOPTION_ATLINE
        | JSOPTION_ATLINE
#endif
#ifdef JSOPTION_JIT
        | JSOPTION_JIT
#endif
// #ifdef JSOPTION_XML
//         | JSOPTION_XML
// #endif
        );

    // Success.
    return init_tracemonkey_extensions(context, self);
  }

  if (context->js) JS_DestroyContext(context->js);

  rb_raise(rb_eRuntimeError, "Failed to initialize TraceMonkey context");
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static VALUE allocate(VALUE klass)
{
  JohnsonContext* context = (JohnsonContext*)calloc(1L, sizeof(JohnsonContext));
  return Data_Wrap_Struct(klass, 0, 0, context);
}

void init_Johnson_TraceMonkey_Context(VALUE tracemonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE tracemonkey = rb_define_module_under(johnson, "TraceMonkey");
  */

  /* This is the private context used for TraceMonkey. */
  VALUE context = rb_define_class_under(tracemonkey, "Context", rb_cObject);

  rb_define_alloc_func(context, allocate);
  rb_define_private_method(context, "initialize_native", (ruby_callback)initialize_native, 2);
}

VALUE Johnson_TraceMonkey_JSLandProxy()
{
  return rb_eval_string("Johnson::TraceMonkey::JSLandProxy");
}
