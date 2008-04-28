#ifndef JOHNSON_JROOT_H
#define JOHNSON_JROOT_H

#define _JROOT_NAMESIZE 200
#define _JROOT_ERRSIZE 500

#define OUR_CONTEXT(js_context) \
  ({ \
    OurContext* _context; \
    VALUE _ruby_context = (VALUE)JS_GetContextPrivate(js_context); \
    Data_Get_Struct(_ruby_context, OurContext, _context); \
    _context; \
  })

#define _PREPARE_JROOTS(rb, context, rootcount, cleancount) \
  const bool _jroot_ruby = (rb); \
  int _jroot_roots = (rootcount); \
  void* _jroot_map[_jroot_roots]; \
  int _jroot_cleans = (cleancount); \
  void (*_jroot_cleanup[_jroot_cleans])(); \
  OurContext* _jroot_context = (context); \
  int _jroot_cleanidx = 0; \
  int _jroot_rootidx = 0

#define PREPARE_JROOTS(context, rootcount, cleancount) \
  _PREPARE_JROOTS(false, context, rootcount, cleancount)

#define PREPARE_RUBY_JROOTS(context, rootcount, cleancount) \
  _PREPARE_JROOTS(true, context, rootcount, cleancount)

#define _JROOT(ptr, name) \
  do \
  { \
    char _jroot_tmpname[_JROOT_NAMESIZE]; \
    assert(_jroot_rootidx < _jroot_roots); \
    _jroot_map[_jroot_rootidx] = (ptr); \
    snprintf(_jroot_tmpname, _JROOT_NAMESIZE, "%s[%d]:%s: %s", __FILE__, __LINE__, __func__, (name)); \
    JCHECK(JS_AddNamedRoot(_jroot_context->js, _jroot_map[_jroot_rootidx], _jroot_tmpname)); \
    _jroot_rootidx++; \
  } while(0)

#define JROOT(var) _JROOT(&(var), #var)
#define JROOT_PTR(ptr) _JROOT(ptr, #ptr)

#define JCLEANUP(code) \
  do \
  { \
    assert(_jroot_cleanidx < _jroot_cleans); \
    void _jroot_cleanup_func () { code; }; \
    _jroot_cleanup[_jroot_cleanidx] = _jroot_cleanup_func; \
    _jroot_cleanidx++; \
  } while(0)

#define JUNROOT(var) \
  do \
  { \
    void* _jroot_match = &(var); \
    int _jroot_i; \
    for (_jroot_i = _jroot_rootidx - 1; _jroot_i >= 0; _jroot_i--) \
      if (_jroot_map[_jroot_i] == _jroot_match) \
      { \
        JS_RemoveRoot(_jroot_context->js, _jroot_map[_jroot_i]); \
        if (_jroot_i == _jroot_rootidx - 1) _jroot_rootidx--; \
        _jroot_map[_jroot_i] = NULL; \
      } \
  } while (0)

#define REMOVE_JROOTS \
  do \
  { \
    int _jroot_i; \
    for (_jroot_i = _jroot_rootidx - 1; _jroot_i >= 0; _jroot_i--) \
      if (_jroot_map[_jroot_i]) \
        JS_RemoveRoot(_jroot_context->js, _jroot_map[_jroot_i]); \
    for (_jroot_i = _jroot_cleanidx - 1; _jroot_i >= 0; _jroot_i--) \
      if (_jroot_cleanup[_jroot_i]) \
        (_jroot_cleanup[_jroot_i])(); \
  } while (0)

#define JCHECK(cond) \
  do \
  { \
    if (!(cond)) \
    { \
      REMOVE_JROOTS; \
      if (_jroot_ruby) \
        raise_js_error_in_ruby(_jroot_context); \
      else \
        return JS_FALSE; \
    } \
  } while (0)

#define JPROTECT2(func, data) \
  ({ \
    int _state; \
    VALUE _old_errinfo = ruby_errinfo; \
    VALUE _result = rb_protect((func), (data), &_state); \
    if (_state) \
    { \
      REMOVE_JROOTS; \
      if (_jroot_ruby) \
        rb_jump_tag(_state); \
      else \
        return report_ruby_error_in_js(_jroot_context, _state, _old_errinfo); \
    } \
    _result; \
  })

#define JPROTECT(code) \
  ({ \
    VALUE _callback(VALUE UNUSED(_void)) { return (code); } \
    JPROTECT2(_callback, Qnil); \
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
    REMOVE_JROOTS; \
    char _jroot_msg[_JROOT_ERRSIZE]; \
    snprintf(_jroot_msg, _JROOT_ERRSIZE, (format) , ## args); \
    if (_jroot_ruby) \
      Johnson_Error_raise(_jroot_msg); \
    else \
    { \
      JSString* _jroot_err_str = JS_NewStringCopyZ(_jroot_context->js, _jroot_msg); \
      if (_jroot_err_str) JS_SetPendingException(_jroot_context->js, STRING_TO_JSVAL(_jroot_err_str)); \
      return JS_FALSE; \
    } \
  } while(0)


#endif
