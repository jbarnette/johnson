#include "global.h"

static JSBool enumerate(JSContext *js_context, JSObject *obj)
{
  return JS_EnumerateStandardClasses(js_context, obj);
}

static JSBool resolve(JSContext *js_context, JSObject *obj, jsval id, uintN flags, JSObject **objp)
{
  if ((flags & JSRESOLVE_ASSIGNING) == 0)
  {
    JSBool resolved_p;

    if (!JS_ResolveStandardClass(js_context, obj, id, &resolved_p))
      return JS_FALSE;
    
    if (resolved_p)
      *objp = obj;
  }

  return JS_TRUE;
}

static JSClass OurGlobalClass = {
  "global", JSCLASS_NEW_RESOLVE | JSCLASS_GLOBAL_FLAGS,
  JS_PropertyStub, // addProperty
  JS_PropertyStub, // delProperty
  JS_PropertyStub, // getProperty
  JS_PropertyStub, // setProperty
  enumerate,
  (JSResolveOp) resolve,
  JS_ConvertStub,
  JS_FinalizeStub,
  JSCLASS_NO_OPTIONAL_MEMBERS
};

JSObject* johnson_create_global_object(JSContext* context)
{
  JSObject* obj = JS_NewObject(context, &OurGlobalClass, NULL, NULL);
  JS_SetParent(context, obj, NULL);
  JS_SetPrototype(context, obj, NULL);
  return obj;
}
