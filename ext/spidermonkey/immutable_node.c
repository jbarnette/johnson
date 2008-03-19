#include "immutable_node.h"
#include "context.h"

static VALUE cNode;

static void error(JSContext* js, const char* message, JSErrorReport* report)
{
  // first we find ourselves
  VALUE self = (VALUE)JS_GetContextPrivate(js);
  
  // then we find our bridge
  ImmutableNodeContext* context;
  Data_Get_Struct(self, ImmutableNodeContext, context);
  
  // NOTE: SpiderMonkey REALLY doesn't like being interrupted. If we
  // jump over to Ruby and raise here, segfaults and such ensue.
  // Instead, we store the exception (if any) and the error message
  // on the context. They're dealt with in the if (!ok) block of evaluate().
  
  strncpy(context->msg, message, MAX_EXCEPTION_MESSAGE_SIZE);
  JS_GetPendingException(context->js, &context->ex);
}

static void deallocate(ImmutableNodeContext* context)
{
  if (context->pc)
  {
    js_FinishParseContext(context->js, context->pc);
    free(context->pc);
  }

  JS_DestroyContext(context->js);
  JS_DestroyRuntime(context->runtime);
  free(context);
}

static VALUE allocate(VALUE klass)
{
  ImmutableNodeContext * context = calloc(1, sizeof(ImmutableNodeContext));

  VALUE self = Data_Wrap_Struct(klass, 0, deallocate, context);

  assert(context->runtime = JS_NewRuntime(0x100000));
  assert(context->js = JS_NewContext(context->runtime, 8192));

  JS_SetErrorReporter(context->js, error);
  JS_SetContextPrivate(context->js, (void *)self);

  return self;
}

static VALUE parse_io(VALUE klass, VALUE stream) {
  VALUE self = allocate(klass);

  ImmutableNodeContext* context;
  Data_Get_Struct(self, ImmutableNodeContext, context);

  assert(context->pc = calloc(1, sizeof(JSParseContext)));
  
  VALUE file_contents = rb_funcall(stream, rb_intern("read"), 0);
  size_t length = NUM2INT(rb_funcall(file_contents, rb_intern("length"), 0));

  jschar* chars;
  assert(chars = js_InflateString(context->js, StringValuePtr(file_contents), &length));

  // FIXME: Ask +stream+ for its path as the filename
  assert(js_InitParseContext(context->js, context->pc, 
      NULL,
      chars,
      length,
      NULL, "boner", 0));

  context->node = js_ParseScript(context->js, 
      JS_NewObject(context->js, &OurGlobalClass, NULL, NULL),
      context->pc);

  return self;
}

static VALUE /* line */
line(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return INT2NUM(ctx->node->pn_pos.begin.lineno);
}

static VALUE /* index */
begin_index(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return INT2NUM(ctx->node->pn_pos.begin.index);
}

void init_Johnson_SpiderMonkey_Immutable_Node(VALUE spidermonkey)
{
  cNode = rb_define_class_under(spidermonkey, "ImmutableNode", rb_cObject);

  rb_define_alloc_func(cNode, allocate);
  rb_define_singleton_method(cNode, "parse_io", parse_io, 1);
  rb_define_method(cNode, "line", line, 0);
  rb_define_method(cNode, "index", begin_index, 0);
}
