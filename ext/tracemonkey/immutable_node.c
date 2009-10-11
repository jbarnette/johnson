#include "immutable_node.h"

static VALUE cNode;

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
  ImmutableNodeContext * context = calloc(1L, sizeof(ImmutableNodeContext));

  VALUE self = Data_Wrap_Struct(klass, 0, deallocate, context);

  assert(context->runtime = JS_NewRuntime(0x100000));
  assert(context->js = JS_NewContext(context->runtime, 8192L));

  return self;
}

/*
 * call-seq:
 *   parse_io(stream, filename=nil, line_number=0)
 *
 * Parses an IO object, returning a native spidermonkey parse tree.
 */
static VALUE parse_io(int argc, VALUE *argv, VALUE klass) {
  VALUE self = allocate(klass);
  VALUE stream, filename, linenum;

  ImmutableNodeContext* context;
  Data_Get_Struct(self, ImmutableNodeContext, context);

  assert(context->pc = calloc(1L, sizeof(JSParseContext)));

  rb_scan_args( argc, argv, "12", &stream, &filename, &linenum );
  
  VALUE file_contents = rb_funcall(stream, rb_intern("read"), 0);
  size_t length = NUM2INT(rb_funcall(file_contents, rb_intern("length"), 0));

  jschar* chars;
  assert(chars = js_InflateString(context->js, StringValuePtr(file_contents), &length));

  if(!filename && rb_respond_to(stream, rb_intern("path"))) {
    filename = rb_funcall(stream, rb_intern("path"), 0);
  }
  char* filenamez = RTEST(filename) ? StringValueCStr(filename) : NULL;
  int linenumi = RTEST(linenum) ? NUM2INT(linenum) : 1;

  assert(js_InitParseContext(context->js, context->pc, 
      NULL,
      chars,
      length,
      NULL, filenamez, (unsigned)linenumi));
  JS_SetVersion(context->js, JSVERSION_LATEST);

  context->node = js_ParseScript(context->js, 
      JS_NewObject(context->js, NULL, NULL, NULL),
      context->pc);
  if(JS_IsExceptionPending(context->js)) {
    jsval exception, message, file_name, line_number;
    JS_GetPendingException(context->js, &exception);
    JS_GetProperty(context->js, JSVAL_TO_OBJECT(exception), "message",&message);
    JS_GetProperty(context->js, JSVAL_TO_OBJECT(exception), "fileName",&file_name);
    JS_GetProperty(context->js, JSVAL_TO_OBJECT(exception), "lineNumber",&line_number);
    JS_ClearPendingException(context->js);

    rb_funcall( self,
                rb_intern("raise_parse_error"),
                3,
                message == JSVAL_NULL ? 
                  Qnil :
                  rb_str_new2(JS_GetStringBytes(JSVAL_TO_STRING(message))),
                rb_str_new2(JS_GetStringBytes(JSVAL_TO_STRING(file_name))),
                INT2NUM((long)JSVAL_TO_INT(line_number))
                );

  }
  return self;
}

/*
 * call-seq:
 *   line
 *
 * Returns the line number of the node.
 */
static VALUE line(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return INT2NUM((long)(ctx->node->pn_pos.begin.lineno));
}

/*
 * call-seq:
 *   index
 *
 * Returns the column number of the node.
 */
static VALUE begin_index(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return INT2NUM((long)(ctx->node->pn_pos.begin.index));
}

/*
 * call-seq:
 *   pn_arity
 *
 * Returns the arity of the node as a symbol.
 */
static VALUE pn_arity(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  switch(ctx->node->pn_arity) {
    case PN_FUNC:
      return ID2SYM(rb_intern("pn_func"));
    case PN_LIST:
      return ID2SYM(rb_intern("pn_list"));
    case PN_TERNARY:
      return ID2SYM(rb_intern("pn_ternary"));
    case PN_BINARY:
      return ID2SYM(rb_intern("pn_binary"));
    case PN_UNARY:
      return ID2SYM(rb_intern("pn_unary"));
    case PN_NAME:
      return ID2SYM(rb_intern("pn_name"));
    case PN_NULLARY:
      return ID2SYM(rb_intern("pn_nullary"));
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_type
 *
 * Returns the type of the node as a symbol.
 */
static VALUE pn_type(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  switch(ctx->node->pn_type) {
    
    case TOK_EOF: return ID2SYM(rb_intern("tok_eof"));
    
    case TOK_EOL: return ID2SYM(rb_intern("tok_eol"));
    
    case TOK_SEMI: return ID2SYM(rb_intern("tok_semi"));
    
    case TOK_COMMA: return ID2SYM(rb_intern("tok_comma"));
    
    case TOK_ASSIGN: return ID2SYM(rb_intern("tok_assign"));
    
    case TOK_HOOK: return ID2SYM(rb_intern("tok_hook"));
    
    case TOK_COLON: return ID2SYM(rb_intern("tok_colon"));
    
    case TOK_OR: return ID2SYM(rb_intern("tok_or"));
    
    case TOK_AND: return ID2SYM(rb_intern("tok_and"));
    
    case TOK_BITOR: return ID2SYM(rb_intern("tok_bitor"));
    
    case TOK_BITXOR: return ID2SYM(rb_intern("tok_bitxor"));
    
    case TOK_BITAND: return ID2SYM(rb_intern("tok_bitand"));
    
    case TOK_EQOP: return ID2SYM(rb_intern("tok_eqop"));
    
    case TOK_RELOP: return ID2SYM(rb_intern("tok_relop"));
    
    case TOK_SHOP: return ID2SYM(rb_intern("tok_shop"));
    
    case TOK_PLUS: return ID2SYM(rb_intern("tok_plus"));
    
    case TOK_MINUS: return ID2SYM(rb_intern("tok_minus"));
    
    case TOK_STAR: return ID2SYM(rb_intern("tok_star"));
    
    case TOK_DIVOP: return ID2SYM(rb_intern("tok_divop"));
    
    case TOK_UNARYOP: return ID2SYM(rb_intern("tok_unaryop"));
    
    case TOK_INC: return ID2SYM(rb_intern("tok_inc"));
    
    case TOK_DEC: return ID2SYM(rb_intern("tok_dec"));
    
    case TOK_DOT: return ID2SYM(rb_intern("tok_dot"));
    
    case TOK_LB: return ID2SYM(rb_intern("tok_lb"));
    
    case TOK_RB: return ID2SYM(rb_intern("tok_rb"));
    
    case TOK_LC: return ID2SYM(rb_intern("tok_lc"));
    
    case TOK_RC: return ID2SYM(rb_intern("tok_rc"));
    
    case TOK_LP: return ID2SYM(rb_intern("tok_lp"));
    
    case TOK_RP: return ID2SYM(rb_intern("tok_rp"));
    
    case TOK_NAME: return ID2SYM(rb_intern("tok_name"));
    
    case TOK_NUMBER: return ID2SYM(rb_intern("tok_number"));
    
    case TOK_STRING: return ID2SYM(rb_intern("tok_string"));
    
    case TOK_REGEXP: return ID2SYM(rb_intern("tok_regexp"));
    
    case TOK_PRIMARY: return ID2SYM(rb_intern("tok_primary"));
    
    case TOK_FUNCTION: return ID2SYM(rb_intern("tok_function"));
    
    case TOK_EXPORT: return ID2SYM(rb_intern("tok_export"));
    
    case TOK_IMPORT: return ID2SYM(rb_intern("tok_import"));
    
    case TOK_IF: return ID2SYM(rb_intern("tok_if"));
    
    case TOK_ELSE: return ID2SYM(rb_intern("tok_else"));
    
    case TOK_SWITCH: return ID2SYM(rb_intern("tok_switch"));
    
    case TOK_CASE: return ID2SYM(rb_intern("tok_case"));
    
    case TOK_DEFAULT: return ID2SYM(rb_intern("tok_default"));
    
    case TOK_WHILE: return ID2SYM(rb_intern("tok_while"));
    
    case TOK_DO: return ID2SYM(rb_intern("tok_do"));
    
    case TOK_FOR: return ID2SYM(rb_intern("tok_for"));
    
    case TOK_BREAK: return ID2SYM(rb_intern("tok_break"));
    
    case TOK_CONTINUE: return ID2SYM(rb_intern("tok_continue"));
    
    case TOK_IN: return ID2SYM(rb_intern("tok_in"));
    
    case TOK_VAR: return ID2SYM(rb_intern("tok_var"));
    
    case TOK_WITH: return ID2SYM(rb_intern("tok_with"));
    
    case TOK_RETURN: return ID2SYM(rb_intern("tok_return"));
    
    case TOK_NEW: return ID2SYM(rb_intern("tok_new"));
    
    case TOK_DELETE: return ID2SYM(rb_intern("tok_delete"));
    
    case TOK_DEFSHARP: return ID2SYM(rb_intern("tok_defsharp"));
    
    case TOK_USESHARP: return ID2SYM(rb_intern("tok_usesharp"));
    
    case TOK_TRY: return ID2SYM(rb_intern("tok_try"));
    
    case TOK_CATCH: return ID2SYM(rb_intern("tok_catch"));
    
    case TOK_FINALLY: return ID2SYM(rb_intern("tok_finally"));
    
    case TOK_THROW: return ID2SYM(rb_intern("tok_throw"));
    
    case TOK_INSTANCEOF: return ID2SYM(rb_intern("tok_instanceof"));
    
    case TOK_DEBUGGER: return ID2SYM(rb_intern("tok_debugger"));
    
    case TOK_XMLSTAGO: return ID2SYM(rb_intern("tok_xmlstago"));
    
    case TOK_XMLETAGO: return ID2SYM(rb_intern("tok_xmletago"));
    
    case TOK_XMLPTAGC: return ID2SYM(rb_intern("tok_xmlptagc"));
    
    case TOK_XMLTAGC: return ID2SYM(rb_intern("tok_xmltagc"));
    
    case TOK_XMLNAME: return ID2SYM(rb_intern("tok_xmlname"));
    
    case TOK_XMLATTR: return ID2SYM(rb_intern("tok_xmlattr"));
    
    case TOK_XMLSPACE: return ID2SYM(rb_intern("tok_xmlspace"));
    
    case TOK_XMLTEXT: return ID2SYM(rb_intern("tok_xmltext"));
    
    case TOK_XMLCOMMENT: return ID2SYM(rb_intern("tok_xmlcomment"));
    
    case TOK_XMLCDATA: return ID2SYM(rb_intern("tok_xmlcdata"));
    
    case TOK_XMLPI: return ID2SYM(rb_intern("tok_xmlpi"));
    
    case TOK_AT: return ID2SYM(rb_intern("tok_at"));
    
    case TOK_DBLCOLON: return ID2SYM(rb_intern("tok_dblcolon"));
    
    case TOK_ANYNAME: return ID2SYM(rb_intern("tok_anyname"));
    
    case TOK_DBLDOT: return ID2SYM(rb_intern("tok_dbldot"));
    
    case TOK_FILTER: return ID2SYM(rb_intern("tok_filter"));
    
    case TOK_XMLELEM: return ID2SYM(rb_intern("tok_xmlelem"));
    
    case TOK_XMLLIST: return ID2SYM(rb_intern("tok_xmllist"));
    
    case TOK_YIELD: return ID2SYM(rb_intern("tok_yield"));
    
    case TOK_ARRAYCOMP: return ID2SYM(rb_intern("tok_arraycomp"));
    
    case TOK_ARRAYPUSH: return ID2SYM(rb_intern("tok_arraypush"));
    
    case TOK_LEXICALSCOPE: return ID2SYM(rb_intern("tok_lexicalscope"));
    
    case TOK_LET: return ID2SYM(rb_intern("tok_let"));
    
    case TOK_BODY: return ID2SYM(rb_intern("tok_body"));
    
    case TOK_RESERVED: return ID2SYM(rb_intern("tok_reserved"));
    
    case TOK_LIMIT: return ID2SYM(rb_intern("tok_limit"));
    
  }
  return INT2NUM((long)(ctx->node->pn_type));
}

/*
 * call-seq:
 *   pn_expr
 *
 * Returns the parse node expression as an ImmutableNode.
 */
static VALUE data_pn_expr(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(ctx->node->pn_expr) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_expr;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_kid
 *
 * Returns the child ImmutableNode.
 */
static VALUE data_pn_kid(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(ctx->node->pn_kid) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_kid;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_kid1
 *
 * Returns the first child ImmutableNode.
 */
static VALUE data_pn_kid1(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(ctx->node->pn_kid1) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_kid1;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_kid2
 *
 * Returns the second child ImmutableNode.
 */
static VALUE data_pn_kid2(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(ctx->node->pn_kid2) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_kid2;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_kid3
 *
 * Returns the third child ImmutableNode.
 */
static VALUE data_pn_kid3(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(ctx->node->pn_kid3) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_kid3;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_dval
 *
 * Returns the numeric value of the node.
 */
static VALUE data_pn_dval(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  if(JSVAL_IS_NUMBER(ATOM_KEY(ctx->node->pn_atom))) {
    return rb_float_new(ctx->node->pn_dval);
  } else {
    return INT2NUM((long)(ctx->node->pn_dval));
  }
}

/*
 * call-seq:
 *   pn_op
 *
 * Returns the op code for the node as a symbol.
 */
static VALUE data_pn_op(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return jsop_to_symbol(ctx->node->pn_op);
}

/*
 * call-seq:
 *   pn_left
 *
 * Returns the left side ImmutableNode.
 */
static VALUE data_pn_left(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);

  if(ctx->node->pn_left) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_left;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_extra
 *
 * Returns extra informaton about the node as an Integer.
 */
static VALUE data_pn_extra(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);

  return UINT2NUM((unsigned long)(ctx->node->pn_extra));
}

/*
 * call-seq:
 *   name
 *
 * Returns the name of the node.
 */
static VALUE name(VALUE self) {
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  return rb_str_new2(JS_GetStringBytes(ATOM_TO_STRING(ctx->node->pn_atom)));
}

/*
 * call-seq:
 *   regexp
 *
 * Returns the regexp value as a String.
 */
static VALUE regexp(VALUE self) {
  ImmutableNodeContext * ctx;
  jsval result;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  js_regexp_toString(ctx->js, ctx->node->pn_pob->object, &result);
  return rb_str_new2(JS_GetStringBytes(JSVAL_TO_STRING(result)));
}

/*
 * call-seq:
 *   function_name
 *
 * Returns the function name as a String.
 */
static VALUE function_name(VALUE self) {
  ImmutableNodeContext * ctx;
  JSFunction * f;
  JSObject * object;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  object = ctx->node->pn_funpob->object;
  f = (JSFunction *)JS_GetPrivate(ctx->js, ctx->node->pn_funpob->object);

  if(f->atom) {
    return rb_str_new2(JS_GetStringBytes(ATOM_TO_STRING(f->atom)));
  } else {
    return Qnil;
  }
}

/*
 * call-seq:
 *   function_args
 *
 * Returns the function argument names as an Array of String.
 */
static VALUE function_args(VALUE self) {
  ImmutableNodeContext * ctx;
  JSFunction * f;
  JSObject * object;
  jsuword* names;
  VALUE func_args;
  int i;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  object = ctx->node->pn_funpob->object;
  f = (JSFunction *)JS_GetPrivate(ctx->js, ctx->node->pn_funpob->object);

  func_args = rb_ary_new2((long)f->nargs);
  if(f->nargs > 0) {
    names = js_GetLocalNameArray(ctx->js, f, &ctx->js->tempPool);
    for(i = 0; i < f->nargs; i++) {
      rb_ary_push(func_args,
          rb_str_new2(JS_GetStringBytes(ATOM_TO_STRING(names[i])))
          );
    }
  }
  return func_args;
}

/*
 * call-seq:
 *   function_body
 *
 * Returns the function body as an ImmutableNode.
 */
static VALUE function_body(VALUE self) {
  ImmutableNodeContext * ctx;
  JSFunction * f;
  JSObject * object;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  object = ctx->node->pn_funpob->object;
  f = (JSFunction *)JS_GetPrivate(ctx->js, ctx->node->pn_funpob->object);

  if(ctx->node->pn_body) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_body;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   pn_right
 *
 * Returns right side as an ImmutableNode.
 */
static VALUE data_pn_right(VALUE self)
{
  ImmutableNodeContext * ctx;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);

  if(ctx->node->pn_right) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = ctx->node->pn_right;
    return node;
  }
  return Qnil;
}

/*
 * call-seq:
 *   children
 *
 * Returns children as an Array of ImmutableNode.
 */
static VALUE children(VALUE self) {
  ImmutableNodeContext * ctx;
  JSParseNode * p;
  VALUE children;

  Data_Get_Struct(self, ImmutableNodeContext, ctx);
  children = rb_ary_new();
  for(p = ctx->node->pn_head; p != NULL; p = p->pn_next) {
    ImmutableNodeContext *roc;
    VALUE node = Data_Make_Struct(cNode, ImmutableNodeContext, NULL, NULL, roc);
    roc->js = ctx->js;
    roc->node = p;

    rb_ary_push(children, node);
  }

  return children;
}

VALUE jsop_to_symbol(JSUint32 jsop)
{
  switch(jsop) {
    
    case JSOP_NOP: return ID2SYM(rb_intern("jsop_nop"));
    
    case JSOP_PUSH: return ID2SYM(rb_intern("jsop_push"));
    
    case JSOP_POPV: return ID2SYM(rb_intern("jsop_popv"));
    
    case JSOP_ENTERWITH: return ID2SYM(rb_intern("jsop_enterwith"));
    
    case JSOP_LEAVEWITH: return ID2SYM(rb_intern("jsop_leavewith"));
    
    case JSOP_RETURN: return ID2SYM(rb_intern("jsop_return"));
    
    case JSOP_GOTO: return ID2SYM(rb_intern("jsop_goto"));
    
    case JSOP_IFEQ: return ID2SYM(rb_intern("jsop_ifeq"));
    
    case JSOP_IFNE: return ID2SYM(rb_intern("jsop_ifne"));
    
    case JSOP_ARGUMENTS: return ID2SYM(rb_intern("jsop_arguments"));
    
    case JSOP_FORARG: return ID2SYM(rb_intern("jsop_forarg"));
    
    case JSOP_FORVAR: return ID2SYM(rb_intern("jsop_forvar"));
    
    case JSOP_DUP: return ID2SYM(rb_intern("jsop_dup"));
    
    case JSOP_DUP2: return ID2SYM(rb_intern("jsop_dup2"));
    
    case JSOP_SETCONST: return ID2SYM(rb_intern("jsop_setconst"));
    
    case JSOP_BITOR: return ID2SYM(rb_intern("jsop_bitor"));
    
    case JSOP_BITXOR: return ID2SYM(rb_intern("jsop_bitxor"));
    
    case JSOP_BITAND: return ID2SYM(rb_intern("jsop_bitand"));
    
    case JSOP_EQ: return ID2SYM(rb_intern("jsop_eq"));
    
    case JSOP_NE: return ID2SYM(rb_intern("jsop_ne"));
    
    case JSOP_LT: return ID2SYM(rb_intern("jsop_lt"));
    
    case JSOP_LE: return ID2SYM(rb_intern("jsop_le"));
    
    case JSOP_GT: return ID2SYM(rb_intern("jsop_gt"));
    
    case JSOP_GE: return ID2SYM(rb_intern("jsop_ge"));
    
    case JSOP_LSH: return ID2SYM(rb_intern("jsop_lsh"));
    
    case JSOP_RSH: return ID2SYM(rb_intern("jsop_rsh"));
    
    case JSOP_URSH: return ID2SYM(rb_intern("jsop_ursh"));
    
    case JSOP_ADD: return ID2SYM(rb_intern("jsop_add"));
    
    case JSOP_SUB: return ID2SYM(rb_intern("jsop_sub"));
    
    case JSOP_MUL: return ID2SYM(rb_intern("jsop_mul"));
    
    case JSOP_DIV: return ID2SYM(rb_intern("jsop_div"));
    
    case JSOP_MOD: return ID2SYM(rb_intern("jsop_mod"));
    
    case JSOP_NOT: return ID2SYM(rb_intern("jsop_not"));
    
    case JSOP_BITNOT: return ID2SYM(rb_intern("jsop_bitnot"));
    
    case JSOP_NEG: return ID2SYM(rb_intern("jsop_neg"));
    
    case JSOP_NEW: return ID2SYM(rb_intern("jsop_new"));
    
    case JSOP_DELNAME: return ID2SYM(rb_intern("jsop_delname"));
    
    case JSOP_DELPROP: return ID2SYM(rb_intern("jsop_delprop"));
    
    case JSOP_DELELEM: return ID2SYM(rb_intern("jsop_delelem"));
    
    case JSOP_TYPEOF: return ID2SYM(rb_intern("jsop_typeof"));
    
    case JSOP_VOID: return ID2SYM(rb_intern("jsop_void"));
    
    case JSOP_INCNAME: return ID2SYM(rb_intern("jsop_incname"));
    
    case JSOP_INCPROP: return ID2SYM(rb_intern("jsop_incprop"));
    
    case JSOP_INCELEM: return ID2SYM(rb_intern("jsop_incelem"));
    
    case JSOP_DECNAME: return ID2SYM(rb_intern("jsop_decname"));
    
    case JSOP_DECPROP: return ID2SYM(rb_intern("jsop_decprop"));
    
    case JSOP_DECELEM: return ID2SYM(rb_intern("jsop_decelem"));
    
    case JSOP_NAMEINC: return ID2SYM(rb_intern("jsop_nameinc"));
    
    case JSOP_PROPINC: return ID2SYM(rb_intern("jsop_propinc"));
    
    case JSOP_ELEMINC: return ID2SYM(rb_intern("jsop_eleminc"));
    
    case JSOP_NAMEDEC: return ID2SYM(rb_intern("jsop_namedec"));
    
    case JSOP_PROPDEC: return ID2SYM(rb_intern("jsop_propdec"));
    
    case JSOP_ELEMDEC: return ID2SYM(rb_intern("jsop_elemdec"));
    
    case JSOP_GETPROP: return ID2SYM(rb_intern("jsop_getprop"));
    
    case JSOP_SETPROP: return ID2SYM(rb_intern("jsop_setprop"));
    
    case JSOP_GETELEM: return ID2SYM(rb_intern("jsop_getelem"));
    
    case JSOP_SETELEM: return ID2SYM(rb_intern("jsop_setelem"));
    
    case JSOP_CALLNAME: return ID2SYM(rb_intern("jsop_callname"));
    
    case JSOP_CALL: return ID2SYM(rb_intern("jsop_call"));
    
    case JSOP_NAME: return ID2SYM(rb_intern("jsop_name"));
    
    case JSOP_DOUBLE: return ID2SYM(rb_intern("jsop_double"));
    
    case JSOP_STRING: return ID2SYM(rb_intern("jsop_string"));
    
    case JSOP_ZERO: return ID2SYM(rb_intern("jsop_zero"));
    
    case JSOP_ONE: return ID2SYM(rb_intern("jsop_one"));
    
    case JSOP_NULL: return ID2SYM(rb_intern("jsop_null"));
    
    case JSOP_THIS: return ID2SYM(rb_intern("jsop_this"));
    
    case JSOP_FALSE: return ID2SYM(rb_intern("jsop_false"));
    
    case JSOP_TRUE: return ID2SYM(rb_intern("jsop_true"));
    
    case JSOP_OR: return ID2SYM(rb_intern("jsop_or"));
    
    case JSOP_AND: return ID2SYM(rb_intern("jsop_and"));
    
    case JSOP_TABLESWITCH: return ID2SYM(rb_intern("jsop_tableswitch"));
    
    case JSOP_LOOKUPSWITCH: return ID2SYM(rb_intern("jsop_lookupswitch"));
    
    case JSOP_STRICTEQ: return ID2SYM(rb_intern("jsop_stricteq"));
    
    case JSOP_STRICTNE: return ID2SYM(rb_intern("jsop_strictne"));
    
    case JSOP_CLOSURE: return ID2SYM(rb_intern("jsop_closure"));
    
    case JSOP_EXPORTALL: return ID2SYM(rb_intern("jsop_exportall"));
    
    case JSOP_EXPORTNAME: return ID2SYM(rb_intern("jsop_exportname"));
    
    case JSOP_IMPORTALL: return ID2SYM(rb_intern("jsop_importall"));
    
    case JSOP_IMPORTPROP: return ID2SYM(rb_intern("jsop_importprop"));
    
    case JSOP_IMPORTELEM: return ID2SYM(rb_intern("jsop_importelem"));
    
    case JSOP_OBJECT: return ID2SYM(rb_intern("jsop_object"));
    
    case JSOP_POP: return ID2SYM(rb_intern("jsop_pop"));
    
    case JSOP_POS: return ID2SYM(rb_intern("jsop_pos"));
    
    case JSOP_TRAP: return ID2SYM(rb_intern("jsop_trap"));
    
    case JSOP_GETARG: return ID2SYM(rb_intern("jsop_getarg"));
    
    case JSOP_SETARG: return ID2SYM(rb_intern("jsop_setarg"));
    
    case JSOP_GETVAR: return ID2SYM(rb_intern("jsop_getvar"));
    
    case JSOP_SETVAR: return ID2SYM(rb_intern("jsop_setvar"));
    
    case JSOP_UINT16: return ID2SYM(rb_intern("jsop_uint16"));
    
    case JSOP_NEWINIT: return ID2SYM(rb_intern("jsop_newinit"));
    
    case JSOP_ENDINIT: return ID2SYM(rb_intern("jsop_endinit"));
    
    case JSOP_INITPROP: return ID2SYM(rb_intern("jsop_initprop"));
    
    case JSOP_INITELEM: return ID2SYM(rb_intern("jsop_initelem"));
    
    case JSOP_DEFSHARP: return ID2SYM(rb_intern("jsop_defsharp"));
    
    case JSOP_USESHARP: return ID2SYM(rb_intern("jsop_usesharp"));
    
    case JSOP_INCARG: return ID2SYM(rb_intern("jsop_incarg"));
    
    case JSOP_INCVAR: return ID2SYM(rb_intern("jsop_incvar"));
    
    case JSOP_DECARG: return ID2SYM(rb_intern("jsop_decarg"));
    
    case JSOP_DECVAR: return ID2SYM(rb_intern("jsop_decvar"));
    
    case JSOP_ARGINC: return ID2SYM(rb_intern("jsop_arginc"));
    
    case JSOP_VARINC: return ID2SYM(rb_intern("jsop_varinc"));
    
    case JSOP_ARGDEC: return ID2SYM(rb_intern("jsop_argdec"));
    
    case JSOP_VARDEC: return ID2SYM(rb_intern("jsop_vardec"));
    
    case JSOP_FORIN: return ID2SYM(rb_intern("jsop_forin"));
    
    case JSOP_FORNAME: return ID2SYM(rb_intern("jsop_forname"));
    
    case JSOP_FORPROP: return ID2SYM(rb_intern("jsop_forprop"));
    
    case JSOP_FORELEM: return ID2SYM(rb_intern("jsop_forelem"));
    
    case JSOP_POPN: return ID2SYM(rb_intern("jsop_popn"));
    
    case JSOP_BINDNAME: return ID2SYM(rb_intern("jsop_bindname"));
    
    case JSOP_SETNAME: return ID2SYM(rb_intern("jsop_setname"));
    
    case JSOP_THROW: return ID2SYM(rb_intern("jsop_throw"));
    
    case JSOP_IN: return ID2SYM(rb_intern("jsop_in"));
    
    case JSOP_INSTANCEOF: return ID2SYM(rb_intern("jsop_instanceof"));
    
    case JSOP_DEBUGGER: return ID2SYM(rb_intern("jsop_debugger"));
    
    case JSOP_GOSUB: return ID2SYM(rb_intern("jsop_gosub"));
    
    case JSOP_RETSUB: return ID2SYM(rb_intern("jsop_retsub"));
    
    case JSOP_EXCEPTION: return ID2SYM(rb_intern("jsop_exception"));
    
    case JSOP_LINENO: return ID2SYM(rb_intern("jsop_lineno"));
    
    case JSOP_CONDSWITCH: return ID2SYM(rb_intern("jsop_condswitch"));
    
    case JSOP_CASE: return ID2SYM(rb_intern("jsop_case"));
    
    case JSOP_DEFAULT: return ID2SYM(rb_intern("jsop_default"));
    
    case JSOP_EVAL: return ID2SYM(rb_intern("jsop_eval"));
    
    case JSOP_ENUMELEM: return ID2SYM(rb_intern("jsop_enumelem"));
    
    case JSOP_GETTER: return ID2SYM(rb_intern("jsop_getter"));
    
    case JSOP_SETTER: return ID2SYM(rb_intern("jsop_setter"));
    
    case JSOP_DEFFUN: return ID2SYM(rb_intern("jsop_deffun"));
    
    case JSOP_DEFCONST: return ID2SYM(rb_intern("jsop_defconst"));
    
    case JSOP_DEFVAR: return ID2SYM(rb_intern("jsop_defvar"));
    
    case JSOP_ANONFUNOBJ: return ID2SYM(rb_intern("jsop_anonfunobj"));
    
    case JSOP_NAMEDFUNOBJ: return ID2SYM(rb_intern("jsop_namedfunobj"));
    
    case JSOP_SETLOCALPOP: return ID2SYM(rb_intern("jsop_setlocalpop"));
    
    case JSOP_GROUP: return ID2SYM(rb_intern("jsop_group"));
    
    case JSOP_SETCALL: return ID2SYM(rb_intern("jsop_setcall"));
    
    case JSOP_TRY: return ID2SYM(rb_intern("jsop_try"));
    
    case JSOP_FINALLY: return ID2SYM(rb_intern("jsop_finally"));
    
    case JSOP_SWAP: return ID2SYM(rb_intern("jsop_swap"));
    
    case JSOP_ARGSUB: return ID2SYM(rb_intern("jsop_argsub"));
    
    case JSOP_ARGCNT: return ID2SYM(rb_intern("jsop_argcnt"));
    
    case JSOP_DEFLOCALFUN: return ID2SYM(rb_intern("jsop_deflocalfun"));
    
    case JSOP_GOTOX: return ID2SYM(rb_intern("jsop_gotox"));
    
    case JSOP_IFEQX: return ID2SYM(rb_intern("jsop_ifeqx"));
    
    case JSOP_IFNEX: return ID2SYM(rb_intern("jsop_ifnex"));
    
    case JSOP_ORX: return ID2SYM(rb_intern("jsop_orx"));
    
    case JSOP_ANDX: return ID2SYM(rb_intern("jsop_andx"));
    
    case JSOP_GOSUBX: return ID2SYM(rb_intern("jsop_gosubx"));
    
    case JSOP_CASEX: return ID2SYM(rb_intern("jsop_casex"));
    
    case JSOP_DEFAULTX: return ID2SYM(rb_intern("jsop_defaultx"));
    
    case JSOP_TABLESWITCHX: return ID2SYM(rb_intern("jsop_tableswitchx"));
    
    case JSOP_LOOKUPSWITCHX: return ID2SYM(rb_intern("jsop_lookupswitchx"));
    
    case JSOP_BACKPATCH: return ID2SYM(rb_intern("jsop_backpatch"));
    
    case JSOP_BACKPATCH_POP: return ID2SYM(rb_intern("jsop_backpatch_pop"));
    
    case JSOP_THROWING: return ID2SYM(rb_intern("jsop_throwing"));
    
    case JSOP_SETRVAL: return ID2SYM(rb_intern("jsop_setrval"));
    
    case JSOP_RETRVAL: return ID2SYM(rb_intern("jsop_retrval"));
    
    case JSOP_GETGVAR: return ID2SYM(rb_intern("jsop_getgvar"));
    
    case JSOP_SETGVAR: return ID2SYM(rb_intern("jsop_setgvar"));
    
    case JSOP_INCGVAR: return ID2SYM(rb_intern("jsop_incgvar"));
    
    case JSOP_DECGVAR: return ID2SYM(rb_intern("jsop_decgvar"));
    
    case JSOP_GVARINC: return ID2SYM(rb_intern("jsop_gvarinc"));
    
    case JSOP_GVARDEC: return ID2SYM(rb_intern("jsop_gvardec"));
    
    case JSOP_REGEXP: return ID2SYM(rb_intern("jsop_regexp"));
    
    case JSOP_DEFXMLNS: return ID2SYM(rb_intern("jsop_defxmlns"));
    
    case JSOP_ANYNAME: return ID2SYM(rb_intern("jsop_anyname"));
    
    case JSOP_QNAMEPART: return ID2SYM(rb_intern("jsop_qnamepart"));
    
    case JSOP_QNAMECONST: return ID2SYM(rb_intern("jsop_qnameconst"));
    
    case JSOP_QNAME: return ID2SYM(rb_intern("jsop_qname"));
    
    case JSOP_TOATTRNAME: return ID2SYM(rb_intern("jsop_toattrname"));
    
    case JSOP_TOATTRVAL: return ID2SYM(rb_intern("jsop_toattrval"));
    
    case JSOP_ADDATTRNAME: return ID2SYM(rb_intern("jsop_addattrname"));
    
    case JSOP_ADDATTRVAL: return ID2SYM(rb_intern("jsop_addattrval"));
    
    case JSOP_BINDXMLNAME: return ID2SYM(rb_intern("jsop_bindxmlname"));
    
    case JSOP_SETXMLNAME: return ID2SYM(rb_intern("jsop_setxmlname"));
    
    case JSOP_XMLNAME: return ID2SYM(rb_intern("jsop_xmlname"));
    
    case JSOP_DESCENDANTS: return ID2SYM(rb_intern("jsop_descendants"));
    
    case JSOP_FILTER: return ID2SYM(rb_intern("jsop_filter"));
    
    case JSOP_ENDFILTER: return ID2SYM(rb_intern("jsop_endfilter"));
    
    case JSOP_TOXML: return ID2SYM(rb_intern("jsop_toxml"));
    
    case JSOP_TOXMLLIST: return ID2SYM(rb_intern("jsop_toxmllist"));
    
    case JSOP_XMLTAGEXPR: return ID2SYM(rb_intern("jsop_xmltagexpr"));
    
    case JSOP_XMLELTEXPR: return ID2SYM(rb_intern("jsop_xmleltexpr"));
    
    case JSOP_XMLOBJECT: return ID2SYM(rb_intern("jsop_xmlobject"));
    
    case JSOP_XMLCDATA: return ID2SYM(rb_intern("jsop_xmlcdata"));
    
    case JSOP_XMLCOMMENT: return ID2SYM(rb_intern("jsop_xmlcomment"));
    
    case JSOP_XMLPI: return ID2SYM(rb_intern("jsop_xmlpi"));
    
    case JSOP_CALLPROP: return ID2SYM(rb_intern("jsop_callprop"));
    
    case JSOP_GETFUNNS: return ID2SYM(rb_intern("jsop_getfunns"));
    
    case JSOP_FOREACH: return ID2SYM(rb_intern("jsop_foreach"));
    
    case JSOP_DELDESC: return ID2SYM(rb_intern("jsop_deldesc"));
    
    case JSOP_UINT24: return ID2SYM(rb_intern("jsop_uint24"));
    
    case JSOP_INDEXBASE: return ID2SYM(rb_intern("jsop_indexbase"));
    
    case JSOP_RESETBASE: return ID2SYM(rb_intern("jsop_resetbase"));
    
    case JSOP_RESETBASE0: return ID2SYM(rb_intern("jsop_resetbase0"));
    
    case JSOP_STARTXML: return ID2SYM(rb_intern("jsop_startxml"));
    
    case JSOP_STARTXMLEXPR: return ID2SYM(rb_intern("jsop_startxmlexpr"));
    
    case JSOP_CALLELEM: return ID2SYM(rb_intern("jsop_callelem"));
    
    case JSOP_STOP: return ID2SYM(rb_intern("jsop_stop"));
    
    case JSOP_GETXPROP: return ID2SYM(rb_intern("jsop_getxprop"));
    
    case JSOP_CALLXMLNAME: return ID2SYM(rb_intern("jsop_callxmlname"));
    
    case JSOP_TYPEOFEXPR: return ID2SYM(rb_intern("jsop_typeofexpr"));
    
    case JSOP_ENTERBLOCK: return ID2SYM(rb_intern("jsop_enterblock"));
    
    case JSOP_LEAVEBLOCK: return ID2SYM(rb_intern("jsop_leaveblock"));
    
    case JSOP_GETLOCAL: return ID2SYM(rb_intern("jsop_getlocal"));
    
    case JSOP_SETLOCAL: return ID2SYM(rb_intern("jsop_setlocal"));
    
    case JSOP_INCLOCAL: return ID2SYM(rb_intern("jsop_inclocal"));
    
    case JSOP_DECLOCAL: return ID2SYM(rb_intern("jsop_declocal"));
    
    case JSOP_LOCALINC: return ID2SYM(rb_intern("jsop_localinc"));
    
    case JSOP_LOCALDEC: return ID2SYM(rb_intern("jsop_localdec"));
    
    case JSOP_FORLOCAL: return ID2SYM(rb_intern("jsop_forlocal"));
    
    case JSOP_FORCONST: return ID2SYM(rb_intern("jsop_forconst"));
    
    case JSOP_ENDITER: return ID2SYM(rb_intern("jsop_enditer"));
    
    case JSOP_GENERATOR: return ID2SYM(rb_intern("jsop_generator"));
    
    case JSOP_YIELD: return ID2SYM(rb_intern("jsop_yield"));
    
    case JSOP_ARRAYPUSH: return ID2SYM(rb_intern("jsop_arraypush"));
    
    case JSOP_FOREACHKEYVAL: return ID2SYM(rb_intern("jsop_foreachkeyval"));
    
    case JSOP_ENUMCONSTELEM: return ID2SYM(rb_intern("jsop_enumconstelem"));
    
    case JSOP_LEAVEBLOCKEXPR: return ID2SYM(rb_intern("jsop_leaveblockexpr"));
    
    case JSOP_GETTHISPROP: return ID2SYM(rb_intern("jsop_getthisprop"));
    
    case JSOP_GETARGPROP: return ID2SYM(rb_intern("jsop_getargprop"));
    
    case JSOP_GETVARPROP: return ID2SYM(rb_intern("jsop_getvarprop"));
    
    case JSOP_GETLOCALPROP: return ID2SYM(rb_intern("jsop_getlocalprop"));
    
    case JSOP_INDEXBASE1: return ID2SYM(rb_intern("jsop_indexbase1"));
    
    case JSOP_INDEXBASE2: return ID2SYM(rb_intern("jsop_indexbase2"));
    
    case JSOP_INDEXBASE3: return ID2SYM(rb_intern("jsop_indexbase3"));
    
    case JSOP_CALLGVAR: return ID2SYM(rb_intern("jsop_callgvar"));
    
    case JSOP_CALLVAR: return ID2SYM(rb_intern("jsop_callvar"));
    
    case JSOP_CALLARG: return ID2SYM(rb_intern("jsop_callarg"));
    
    case JSOP_CALLLOCAL: return ID2SYM(rb_intern("jsop_calllocal"));
    
    case JSOP_INT8: return ID2SYM(rb_intern("jsop_int8"));
    
    case JSOP_INT32: return ID2SYM(rb_intern("jsop_int32"));
    
    case JSOP_LENGTH: return ID2SYM(rb_intern("jsop_length"));
    
  }
  return UINT2NUM((unsigned long)(jsop));
}

void init_Johnson_SpiderMonkey_Immutable_Node(VALUE spidermonkey)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  VALUE spidermonkey = rb_define_module_under(johnson, "SpiderMonkey");
  */

  /* ImmutableNode class. */
  cNode = rb_define_class_under(spidermonkey, "ImmutableNode", rb_cObject);

  rb_define_alloc_func(cNode, allocate);
  rb_define_singleton_method(cNode, "parse_io", parse_io, -1);
  rb_define_method(cNode, "line", line, 0);
  rb_define_method(cNode, "index", begin_index, 0);
  rb_define_method(cNode, "pn_arity", pn_arity, 0);
  rb_define_method(cNode, "pn_type", pn_type, 0);
  rb_define_method(cNode, "pn_expr", data_pn_expr, 0);
  rb_define_method(cNode, "pn_kid", data_pn_kid, 0);
  rb_define_method(cNode, "pn_kid1", data_pn_kid1, 0);
  rb_define_method(cNode, "pn_kid2", data_pn_kid2, 0);
  rb_define_method(cNode, "pn_kid3", data_pn_kid3, 0);
  rb_define_method(cNode, "pn_dval", data_pn_dval, 0);
  rb_define_method(cNode, "pn_op", data_pn_op, 0);
  rb_define_method(cNode, "pn_left", data_pn_left, 0);
  rb_define_method(cNode, "pn_extra", data_pn_extra, 0);
  rb_define_method(cNode, "name", name, 0);
  rb_define_method(cNode, "regexp", regexp, 0);
  rb_define_method(cNode, "function_name", function_name, 0);
  rb_define_method(cNode, "function_args", function_args, 0);
  rb_define_method(cNode, "function_body", function_body, 0);
  rb_define_method(cNode, "pn_right", data_pn_right, 0);
  rb_define_method(cNode, "children", children, 0);
}
