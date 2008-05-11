#include "context.h"
#include "conversions.h"
#include "global.h"
#include "error.h"
#include "extensions.h"
#include "idhash.h"

/*
 * call-seq:
 *   global
 *
 * Returns the global object used for this context.
 */
static VALUE global(VALUE self)
{
  OurContext* context;
  Data_Get_Struct(self, OurContext, context);
  return convert_to_ruby(context, OBJECT_TO_JSVAL(context->global));
}

/*
 * call-seq:
 *   evaluate(script, filename=nil, linenum=nil)
 *
 * Evaluate +script+ with +filename+ using +linenum+
 */
static VALUE evaluate(int argc, VALUE* argv, VALUE self)
{
  VALUE script, filename, linenum;

  OurContext* context;
  Data_Get_Struct(self, OurContext, context);

  rb_scan_args( argc, argv, "12", &script, &filename, &linenum );

  // clean things up first
  context->ex = 0;
  memset(context->msg, 0, MAX_EXCEPTION_MESSAGE_SIZE);

  char* filenamez = RTEST(filename) ? StringValueCStr(filename) : NULL;
  int linenumi = RTEST(linenum) ? NUM2INT(linenum) : 1;

  jsval js;

  // FIXME: should be able to pass in the 'file' name
  JSBool ok = JS_EvaluateScript(context->js, context->global,
    StringValuePtr(script), (unsigned)StringValueLen(script), filenamez, (unsigned)linenumi, &js);

  if (!ok)
  {
    if (JS_IsExceptionPending(context->js))
    {
      // If there's an exception pending here, it's a syntax error.
      JS_GetPendingException(context->js, &context->ex);
      JS_ClearPendingException(context->js);
    }

    if (context->ex)
    {
      return rb_funcall(self, rb_intern("handle_js_exception"),
        1, convert_to_ruby(context, context->ex));
      
      // VALUE message, file, line, stack;
      // 
      // jsval js_message;
      // assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(context->ex), "message", &js_message));
      // message = convert_to_ruby(context, js_message);
      // 
      // jsval js_file;
      // assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(context->ex), "fileName", &js_file));
      // file = convert_to_ruby(context, js_file);
      // 
      // jsval js_line;
      // assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(context->ex), "lineNumber", &js_line));
      // line = convert_to_ruby(context, js_line);
      // 
      // jsval js_stack;
      // assert(JS_GetProperty(context->js, JSVAL_TO_OBJECT(context->ex), "stack", &js_stack));
      // stack = convert_to_ruby(context, js_stack);
      // 
      // return rb_funcall(self, rb_intern("handle_js_exception"),
      //   4, message, file, line, stack);
    }
    
    char* msg = context->msg;

    // toString() whatever the exception object is (if we have one)
    if (context->ex) msg = JS_GetStringBytes(JS_ValueToString(context->js, context->ex));

    return Johnson_Error_raise(msg);
  }

  return convert_to_ruby(context, js);
}

// callback for JS_SetErrorReporter
static void report_js_error(JSContext* js, const char* message, JSErrorReport* UNUSED(report))
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

// callback for JS_SetBranchCallback
static JSBool branch_callback(JSContext* js, JSScript* UNUSED(script))
{
  static unsigned long branch_counter = 0;
  if( ++branch_counter % 0x1000 == 0 )
    JS_MaybeGC( js );
  return JS_TRUE;
}

/*
 * call-seq:
 *   native_initialize(options={})
 *
 * Initializes the native spidermonkey values.
 */
static VALUE
initialize_native(VALUE self, VALUE UNUSED(options))
{
  OurContext* context;
  bool gthings_rooted_p = false;

  Data_Get_Struct(self, OurContext, context);

  if ((context->runtime = JS_NewRuntime(0x100000))
    && (context->js = JS_NewContext(context->runtime, 8192))
    && (context->jsids = create_id_hash())
    && (context->rbids = create_id_hash())
    && (context->gcthings = JS_NewObject(context->js, NULL, 0, 0))
    && (gthings_rooted_p = JS_AddNamedRoot(context->js, &(context->gcthings), "context->gcthings"))
    && (context->global = create_global_object(context))
    && (JS_AddNamedRoot(context->js, &(context->global), "context->global")))
  {
    JS_SetErrorReporter(context->js, report_js_error);
    JS_SetBranchCallback(context->js, branch_callback);
    JS_SetContextPrivate(context->js, (void *)self);

    JS_SetOptions(context->js, JS_GetOptions(context->js)
#ifdef JSOPTION_DONT_REPORT_UNCAUGHT
      | JSOPTION_DONT_REPORT_UNCAUGHT
#endif
#ifdef JSOPTION_VAROBJFIX
      | JSOPTION_VAROBJFIX
#endif
#ifdef JSOPTION_XML
      | JSOPTION_XML
#endif
    );

    return init_spidermonkey_extensions(context, self);
  }

  if (gthings_rooted_p)
    JS_RemoveRoot(context->js, &(context->gcthings));

  if (context->rbids)
    JS_HashTableDestroy(context->rbids);

  if (context->jsids)
    JS_HashTableDestroy(context->jsids);

  if (context->js)
    JS_DestroyContext(context->js);

  if (context->runtime)
    JS_DestroyRuntime(context->runtime);

  rb_raise(rb_eRuntimeError, "Failed to initialize SpiderMonkey context");
}

///////////////////////////////////////////////////////////////////////////
//// INFRASTRUCTURE BELOW HERE ////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

static void deallocate(OurContext* context)
{
  JS_SetContextPrivate(context->js, 0);

  JS_RemoveRoot(context->js, &(context->global));
  JS_RemoveRoot(context->js, &(context->gcthings));
  JS_HashTableDestroy(context->rbids);
  JS_HashTableDestroy(context->jsids);

  context->jsids = 0;
  context->rbids = 0;

  JS_DestroyContext(context->js);
  JS_DestroyRuntime(context->runtime);

  free(context);
}

static VALUE allocate(VALUE klass)
{
  OurContext* context = calloc(1, sizeof(OurContext));
  return Data_Wrap_Struct(klass, 0, deallocate, context);
}

void init_Johnson_SpiderMonkey_Context(VALUE spidermonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  */

  /* This is the private context used for SpiderMonkey. */
  VALUE context = rb_define_class_under(spidermonkey, "Context", rb_cObject);

  rb_define_alloc_func(context, allocate);
  rb_define_private_method(context, "initialize_native", initialize_native, 1);

  rb_define_method(context, "global", global, 0);
  rb_define_method(context, "evaluate", evaluate, -1);
}

VALUE Johnson_SpiderMonkey_JSLandProxy()
{
  return rb_eval_string("Johnson::SpiderMonkey::JSLandProxy");
}
