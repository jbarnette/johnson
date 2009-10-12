#ifndef JOHNSON_JROOT_H
#define JOHNSON_JROOT_H

#define _JROOT_NAMESIZE 200L
#define _JROOT_ERRSIZE 500L

#define _JROOT_ROOT (void(*)(JSContext*, void*))(1)

#define OUR_CONTEXT(js_context) \
  ({ \
    JohnsonContext* _context; \
    const VALUE _ruby_context = (VALUE)JS_GetContextPrivate(js_context); \
    Data_Get_Struct(_ruby_context, JohnsonContext, _context); \
    _context; \
  })

#define OUR_RUNTIME(js_context) \
  ({ \
    JohnsonRuntime* _johnson_runtime; \
    JSRuntime * _js_runtime = JS_GetRuntime(js_context);\
    const VALUE _ruby_runtime = (VALUE)JS_GetRuntimePrivate(_js_runtime); \
    Data_Get_Struct(_ruby_runtime, JohnsonRuntime, _johnson_runtime); \
    _johnson_runtime; \
   })
    

#define _PREPARE_JROOTS(rb, context, cleancount) \
  const bool _jroot_ruby = (rb); \
  const int _jroot_cleans = (cleancount); \
  void (*_jroot_cleanup[_jroot_cleans])(JSContext*, void*); \
  void* _jroot_cleanup_data[_jroot_cleans]; \
  JSContext* const _jroot_context = (context); \
  int _jroot_cleanidx = 0;

#define PREPARE_JROOTS(context, cleancount) \
  _PREPARE_JROOTS(false, context, cleancount)

#define PREPARE_RUBY_JROOTS(context, cleancount) \
  _PREPARE_JROOTS(true, context, cleancount)

#define JCLEANUP(func, data) \
  do \
  { \
    assert(_jroot_cleanidx < _jroot_cleans); \
    _jroot_cleanup[_jroot_cleanidx] = (func); \
    _jroot_cleanup_data[_jroot_cleanidx] = (data); \
    _jroot_cleanidx++; \
  } while(0)

#define _JROOT(ptr, name) \
  do \
  { \
    static char _name[_JROOT_NAMESIZE] = ""; \
    void* const _root = (ptr); \
    if (*_name == '\0') \
      snprintf(_name, _JROOT_NAMESIZE, "%s[%d]:%s: %s", __FILE__, __LINE__, __func__, (name)); \
    JCHECK(JS_AddNamedRoot(_jroot_context, _root, _name)); \
    JCLEANUP(_JROOT_ROOT, _root); \
  } while(0)

#define JROOT(var) _JROOT(&(var), #var)
#define JROOT_PTR(ptr) _JROOT(ptr, #ptr)

#define JUNROOT(var) \
  do \
  { \
    void* const _jroot_match = &(var); \
    int _jroot_i; \
    for (_jroot_i = _jroot_cleanidx - 1; _jroot_i >= 0; _jroot_i--) \
      if (_jroot_cleanup[_jroot_i] == _JROOT_ROOT && _jroot_cleanup_data[_jroot_i] == _jroot_match) \
      { \
        JS_RemoveRoot(_jroot_context, _jroot_cleanup_data[_jroot_i]); \
        if (_jroot_i == _jroot_cleanidx - 1) _jroot_cleanidx--; \
        _jroot_cleanup[_jroot_i] = NULL; \
      } \
  } while (0)

#define REMOVE_JROOTS \
  do \
  { \
    int _jroot_i; \
    for (_jroot_i = _jroot_cleanidx - 1; _jroot_i >= 0; _jroot_i--) \
    { \
      if (_jroot_cleanup[_jroot_i] == _JROOT_ROOT) \
        JS_RemoveRoot(_jroot_context, _jroot_cleanup_data[_jroot_i]); \
      else if (_jroot_cleanup[_jroot_i]) \
        (_jroot_cleanup[_jroot_i])(_jroot_context, _jroot_cleanup_data[_jroot_i]); \
    } \
  } while (0)

#define JCHECK_RUBY(cond) \
  do \
  { \
    assert(_jroot_ruby); \
    if (!(cond)) \
    { \
      REMOVE_JROOTS; \
      raise_js_error_in_ruby(OUR_RUNTIME(_jroot_context)); \
    } \
  } while (0)

#define JCHECK(cond) \
  do \
  { \
    if (!(cond)) \
    { \
      REMOVE_JROOTS; \
      if (_jroot_ruby) \
        raise_js_error_in_ruby(OUR_RUNTIME(_jroot_context)); \
      else \
        return JS_FALSE; \
    } \
  } while (0)

#define JPROTECT_T(T, func, data)                  \
  ({ \
    int _state; \
    const VALUE _old_errinfo = ruby_errinfo; \
    const VALUE _result = rb_protect((func), (data), &_state); \
    if (_state) \
    { \
      REMOVE_JROOTS; \
      if (_jroot_ruby) \
        rb_jump_tag(_state); \
      else \
        return (T)report_ruby_error_in_js(OUR_RUNTIME(_jroot_context), _state, _old_errinfo); \
    } \
    _result; \
  })

#define JPROTECT(func, data) \
  ({ \
    int _state; \
    const VALUE _old_errinfo = ruby_errinfo; \
    const VALUE _result = rb_protect((func), (data), &_state); \
    if (_state) \
    { \
      REMOVE_JROOTS; \
      if (_jroot_ruby) \
        rb_jump_tag(_state); \
      else \
        return report_ruby_error_in_js(OUR_RUNTIME(_jroot_context), _state, _old_errinfo); \
    } \
    _result; \
  })

#define JRETURN \
  do \
  { \
    assert(!_jroot_ruby); \
    REMOVE_JROOTS; \
    return JS_TRUE; \
  } while(0)

#define JRETURN_RUBY(value) \
  do \
  { \
    assert(_jroot_ruby); \
    typeof(value) _jroot_result = (value); \
    REMOVE_JROOTS; \
    return _jroot_result; \
  } while(0)

#define JERROR(format, args...) \
  do \
  { \
    char _jroot_msg[_JROOT_ERRSIZE]; \
    snprintf(_jroot_msg, _JROOT_ERRSIZE, (format) , ## args); \
    if (_jroot_ruby) \
    { \
      REMOVE_JROOTS; \
      rb_raise(rb_eRuntimeError,  _jroot_msg); \
    } \
    else \
    { \
      JSString* _jroot_err_str = JS_NewStringCopyZ(_jroot_context, _jroot_msg); \
      if (_jroot_err_str) JS_SetPendingException(_jroot_context, STRING_TO_JSVAL(_jroot_err_str)); \
      REMOVE_JROOTS; \
      return JS_FALSE; \
    } \
  } while(0)




#define ARGLIST1(a)             _data->a
#define ARGLIST1T(T,a)          ((T)_data->a)
#define ARGLIST2(a, b)          _data->a, _data->b
#define ARGLIST3(a, b, c)       _data->a, _data->b, _data->c
#define ARGLIST4(a, b, c, d)    _data->a, _data->b, _data->c, _data->d
#define ARGLIST5(a, b, c, d, e) _data->a, _data->b, _data->c, _data->d, _data->e

#define DECLARE_RUBY_WRAPPER(name, args) \
  typedef struct { args; } name ## _args; \
  VALUE name ## _invoke(VALUE magic);
#define DEFINE_RUBY_WRAPPER(name, func, arglist) \
  VALUE name ## _invoke(VALUE magic) \
  { \
    name ## _args * _data = (name ## _args *)(FIX2LONG(magic) << 2); \
    return func(arglist); \
  }
#define DEFINE_VOID_RUBY_WRAPPER(name, func, arglist) \
  VALUE name ## _invoke(VALUE magic) \
  { \
    name ## _args * _data = (name ## _args *)(FIX2LONG(magic) << 2); \
    func(arglist); \
    return Qnil; \
  }
#define RUBY_WRAPPER_ARG(name, args...) ({ name ## _args _x = { args }; LONG2FIX((long)(&_x) >> 2); })
#define RUBY_WRAPPER(name) name ## _invoke
#define CALL_RUBY_WRAPPER(name, args...) JPROTECT(RUBY_WRAPPER(name), RUBY_WRAPPER_ARG(name, args))
#define CALL_RUBY_WRAPPER_T(name, T, args...) JPROTECT_T(T, RUBY_WRAPPER(name), RUBY_WRAPPER_ARG(name, args))


#endif
