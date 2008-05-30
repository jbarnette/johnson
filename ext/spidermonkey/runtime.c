#include "runtime.h"
#include "error.h"
#include "global.h"
#include "idhash.h"

JSContext* johnson_get_current_context(JohnsonRuntime* runtime)
{
  // First, see if we already have a context for the current thread.
  JSContext* context = (JSContext*)JS_HashTableLookup(runtime->contexts, (void*)rb_thread_current());
  
  // If not,
  if (!context)
  {
    // try and create one.
    if ((context = JS_NewContext(runtime->js, 8192)))
    {
      // See if the runtime already has a shared global object.
      JSObject* global = runtime->global;
      
      // If it does, use it. If not,
      if (!global)
        // create one of our global objects.
        global = johnson_create_global_object(context);

      // Manually set the context's global object.
      JS_SetGlobalObject(context, global);
      
      // Register this context (thread -> context) for lookup next time.
      JS_HashTableAdd(runtime->contexts, (void*)rb_thread_current(), (void*) context);
      
      // Success.
      return context;
    }

    // Something went wrong! If a context was created,
    if (context)
      // destroy it safely.
      JS_DestroyContext(context);
    
    // Scream for help.
    Johnson_Error_raise("Unable to create Johnson::SpiderMonkey::Runtime!");
  }
  
  // Success. Already had a context for the current thread.
  return context;
}

static VALUE
initialize_native(VALUE self, VALUE UNUSED(options))
{
  JohnsonRuntime* runtime;
  Data_Get_Struct(self, JohnsonRuntime, runtime);
  
  if ((runtime->js = JS_NewRuntime(0x100000))
    && (runtime->contexts = create_id_hash()))
  {
    JSContext* context = johnson_get_current_context(runtime);
    runtime->global = JS_GetGlobalObject(context);    
    JS_AddNamedRoot(context, &(runtime->global), "runtime->global");
    
    return self;
  }
  
  if (runtime->contexts)
    JS_HashTableDestroy(runtime->contexts);
  
  if (runtime->js)
    JS_DestroyRuntime(runtime->js);
    
  return Johnson_Error_raise("Couldn't initialize the runtime!");
}

static void deallocate(JohnsonRuntime* runtime)
{
  JS_RemoveRoot(johnson_get_current_context(runtime), &(runtime->global));
  
  JS_HashTableDestroy(runtime->contexts);
  runtime->contexts = 0;
  
  JSContext *context;
  JSContext *iterator = NULL;

  while ((context = JS_ContextIterator(runtime->js, &iterator)) != NULL)
    JS_DestroyContext(context);
  
  JS_DestroyRuntime(runtime->js);
  free(runtime);
}

static VALUE allocate(VALUE klass)
{
  JohnsonRuntime* runtime = calloc(1, sizeof(JohnsonRuntime));
  return Data_Wrap_Struct(klass, 0, deallocate, runtime);
}

void init_Johnson_SpiderMonkey_Runtime(VALUE spidermonkey)
{
  VALUE klass = rb_define_class_under(spidermonkey, "Runtime", rb_cObject);

  rb_define_alloc_func(klass, allocate);
  rb_define_private_method(klass, "initialize_native", initialize_native, 1);
}
