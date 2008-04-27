#ifndef JOHNSON_JROOT_H
#define JOHNSON_JROOT_H

#define _JROOT_NAMESIZE 200
#define _JROOT_ERRSIZE 500

#define OUR_CONTEXT(js_context) \
  ({ \
    OurContext* context; \
    VALUE ruby_context = (VALUE)JS_GetContextPrivate(js_context); \
    Data_Get_Struct(ruby_context, OurContext, context); \
    context; \
  })

#define _PREPARE_JROOTS(rb, context, name, maxcount) \
  const bool __jroot_ruby = rb; \
  const char* const MAYBE_UNUSED(__jroot_basename) = name; \
  char MAYBE_UNUSED(__jroot_tmpname[_JROOT_NAMESIZE]); \
  int MAYBE_UNUSED(__jroot_max) = maxcount - 1; \
  void* __jroot_map[maxcount]; \
  OurContext* __jroot_context = context; \
  int __jroot_idx = 0

#define PREPARE_JROOTS(context, name, maxcount) \
  _PREPARE_JROOTS(false, context, name, maxcount)

#define PREPARE_RUBY_JROOTS(context, name, maxcount) \
  _PREPARE_JROOTS(true, context, name, maxcount)

#define _JROOT(ptr, name) \
  do \
  { \
    assert(__jroot_idx <= __jroot_max); \
    __jroot_map[__jroot_idx] = ptr; \
    snprintf(__jroot_tmpname, _JROOT_NAMESIZE, "%s[%d]:%s: %s", __FILE__, __LINE__, __jroot_basename, name); \
    JCHECK(JS_AddNamedRoot(__jroot_context->js, __jroot_map[__jroot_idx], __jroot_tmpname)); \
    __jroot_idx++; \
    JS_GC(__jroot_context->js); \
  } while(0)

#define JROOT(var) _JROOT(&(var), #var)
#define JROOT_PTR(ptr) _JROOT(ptr, #ptr)

#define JUNROOT(var) \
  do \
  { \
    void* __jroot_match = &(var); \
    int __jroot_i; \
    for (__jroot_i = __jroot_idx - 1; __jroot_i >= 0; __jroot_i--) \
      if (__jroot_map[__jroot_i] == __jroot_match) \
      { \
        JS_RemoveRoot(__jroot_context->js, __jroot_map[__jroot_i]); \
        if (__jroot_i == __jroot_idx - 1) __jroot_idx--; \
        __jroot_map[__jroot_i] = NULL; \
      } \
  } while (0)

#define REMOVE_JROOTS \
  do \
  { \
    int __jroot_i; \
    for (__jroot_i = __jroot_idx - 1; __jroot_i >= 0; __jroot_i--) \
      if (__jroot_map[__jroot_i]) \
        JS_RemoveRoot(__jroot_context->js, __jroot_map[__jroot_i]); \
  } while (0)

#define JCHECK(cond) \
  do \
  { \
    if (!(cond)) \
    { \
      REMOVE_JROOTS; \
      if (__jroot_ruby) \
        raise_js_error_in_ruby(__jroot_context); \
      else \
        return JS_FALSE; \
    } \
  } while (0)

#define JRETURN \
  do \
  { \
    REMOVE_JROOTS; \
    return JS_TRUE; \
  } while(0)

#define JRETURN_RUBY(value) \
  do \
  { \
    typeof(value) __jroot_result = value; \
    REMOVE_JROOTS; \
    return __jroot_result; \
  } while(0)

#define JERROR(format, args...) \
  do \
  { \
    REMOVE_JROOTS; \
    char msg[_JROOT_ERRSIZE]; \
    snprintf(msg, _JROOT_ERRSIZE, format , ## args); \
    if (__jroot_ruby) \
      Johnson_Error_raise(msg); \
    else \
    { \
      JSString* str = JS_NewStringCopyZ(__jroot_context->js, msg); \
      if (str) JS_SetPendingException(__jroot_context->js, STRING_TO_JSVAL(str)); \
      return JS_FALSE; \
    } \
  } while(0)


#endif
