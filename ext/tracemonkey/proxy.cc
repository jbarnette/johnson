#include "proxy.h"

static int print = 0;

static JSBool addProperty_p( JSContext* cx, JSObject* proxy, jsval idval, jsval *vp ) { 
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy ); 
    JSClass* cobj = JS_GET_CLASS(cx, target);
    if(print)fprintf(stderr,"addProperty_p\n");
    return cobj->addProperty( cx, target, idval, vp ); 
}

static JSBool delProperty_p( JSContext* cx, JSObject* proxy, jsval idval, jsval *vp ) { 
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy ); 
    JSClass* cobj = JS_GET_CLASS(cx, target);
    if(print)fprintf(stderr,"delProperty_p\n");
    return cobj->delProperty( cx, target, idval, vp ); 
}

static JSBool getProperty_p( JSContext* cx, JSObject* proxy, jsval idval, jsval *vp ) { 
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy ); 
    JSClass* cobj = JS_GET_CLASS(cx, target);
    if(print)fprintf(stderr,"getProperty_p\n");
    return cobj->getProperty( cx, target, idval, vp ); 
}

static JSBool setProperty_p( JSContext* cx, JSObject* proxy, jsval idval, jsval *vp ) { 
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy ); 
    JSClass* cobj = JS_GET_CLASS(cx, target);
    if(print)fprintf(stderr,"setProperty_p\n");
    return cobj->setProperty( cx, target, idval, vp ); 
}

static void mark(JSTracer* trc, JSObject* proxy) {
  JSObject* target = (JSObject*)JS_GetPrivate( trc->context, proxy );
  jsval val = OBJECT_TO_JSVAL(target);
  if(print)fprintf(stderr,"mark\n");
  JS_CallTracer( trc, target, JSVAL_TRACE_KIND(val) );
}

static JSObject* wrappedObject(JSContext* cx, JSObject* proxy) {
    if(print)fprintf(stderr,"wrapped\n");
    return (JSObject*)JS_GetPrivate( cx, proxy );
}

static JSBool enumerate_cb( JSContext* cx, JSObject* proxy ) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  JSClass* cobj = JS_GET_CLASS(cx, target);
  if(print)fprintf(stderr,"enumerate\n");
  return (cobj->enumerate)(cx,target);
}

static JSBool resolve_cb(JSContext* cx, JSObject* proxy, jsval id, uintN flags, JSObject** objp) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  JSClass* cobj = JS_GET_CLASS(cx, target);
  JSBool result = ((JSNewResolveOp)(cobj->resolve))(cx,target,id,flags,objp);
  if(print)fprintf(stderr,"resolve %d returned %d\n", id, result);
  return result;
}

static JSBool _resolve_cb(JSContext* cx, JSObject* proxy, jsval id) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  JSClass* cobj = JS_GET_CLASS(cx, target);
  if(print)fprintf( stderr, "resolve\n" );
  return (cobj->resolve)(cx,target,id);
}

static JSBool convert_cb(JSContext* cx, JSObject* proxy, JSType type, jsval *vp) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  JSClass* cobj = JS_GET_CLASS(cx, target);
  if(print)fprintf(stderr,"convert\n");
  return cobj->convert(cx,target,type,vp);
}

static JSBool lookupProperty(JSContext* cx, 
                             JSObject* proxy,
                             jsid id,
                             JSObject** objp, 
                             JSProperty **propp) {
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
    if(print)fprintf(stderr,"lookup\n");
    return OBJ_LOOKUP_PROPERTY(cx,target,id,objp,propp);
}

static JSBool defineProperty( JSContext* cx,
                                JSObject* proxy,
                                jsid id,
                                jsval value,
                               JSPropertyOp getter,
                               JSPropertyOp setter,
                               uintN attrs,
                               JSProperty** propp ) {
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
    if(print)fprintf(stderr,"define\n");
    return OBJ_DEFINE_PROPERTY(cx, target, id, value, getter, setter, attrs, propp );
}

static JSBool getProperty( JSContext* cx, JSObject* proxy, jsid id, jsval* vp ) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  if(print)fprintf(stderr,"get\n");
  return OBJ_GET_PROPERTY(cx,target,id,vp);
}

static JSBool setProperty( JSContext* cx, JSObject* proxy, jsid id, jsval* vp ) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  if(print)fprintf(stderr,"set\n");
  return OBJ_SET_PROPERTY(cx,target,id,vp);
}

static JSAttributesOp getAttributes;
static JSAttributesOp setAttributes;

static JSBool deleteProperty( JSContext* cx, JSObject* proxy, jsid id, jsval* vp ) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  if(print)fprintf(stderr,"del\n");
  return OBJ_DELETE_PROPERTY(cx,target,id,vp);
}

static JSBool defaultValue( JSContext* cx, JSObject* proxy, JSType type, jsval *vp ) {
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
    if(print)fprintf(stderr,"def\n");
    return OBJ_DEFAULT_VALUE(cx,target,type,vp);
}

static JSBool enumerate( JSContext* cx, JSObject* proxy, JSIterateOp enum_op, jsval* statep, jsid* idp ) {
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
    if(print)fprintf(stderr,"enum\n");
    return OBJ_ENUMERATE(cx,target,enum_op,statep, idp);
}

JSBool checkAccess(JSContext* cx, JSObject* proxy, jsid id, JSAccessMode mode, jsval *vp, uintN *attrsp) {
    JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
    if(print)fprintf(stderr,"check\n");
    return OBJ_CHECK_ACCESS(cx, target, id, mode, vp, attrsp);
}

static JSObjectOp thisObject;
// static JSObject* thisObject( JSContext* cx, JSObject* obj ) {
//   abort();
// }

// Static JSPropertyRefOp dropProperty;
static void dropProperty(JSContext *cx, JSObject *proxy, JSProperty *prop) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  return OBJ_DROP_PROPERTY(cx, target, prop);
}

static JSBool call( JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
  abort();
}

static JSBool construct( JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
  abort();
}

static JSBool hasInstance(JSContext *cx, JSObject *obj, jsval v, JSBool *bp) {
  abort();
}

static void trace(JSTracer *trc, JSObject *proxy) {
  JSObject* target = (JSObject*)JS_GetPrivate( trc->context, proxy );
  js_TraceObject(trc, target);
}

// static JSFinalizeOp clear;
static void clear(JSContext *cx, JSObject *obj) {
  abort();
}

// static JSGetRequiredSlotOp getRequiredSlot;
static jsval getRequiredSlot(JSContext *cx, JSObject *proxy, uint32 slot) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  jsval v = OBJ_GET_REQUIRED_SLOT(cx, target, slot);
  // fprintf(stderr,"get %08x %d %08x\n",target,slot,v);
  return v;
}

// static JSSetRequiredSlotOp setRequiredSlot;
static JSBool setRequiredSlot(JSContext *cx, JSObject *proxy, uint32 slot, jsval v) {
  JSObject* target = (JSObject*)JS_GetPrivate( cx, proxy );
  // fprintf(stderr,"set %08x %d %08x\n",target,slot,v);
  return OBJ_SET_REQUIRED_SLOT(cx, target, slot, v);
}

static JSObjectOps objectOps = {
    NULL,
    lookupProperty,
    defineProperty,
    getProperty,
    setProperty,
    getAttributes,
    setAttributes,
    deleteProperty,
    defaultValue,
    enumerate,
    checkAccess,
    thisObject,
    dropProperty,
    call,
    construct,
    hasInstance,
    trace,
    clear,
    getRequiredSlot,
    setRequiredSlot
};

static JSObjectOps* getObjectOps( JSContext* cx, JSClass* cls ) {
    return &objectOps;
}

static JSExtendedClass OurProxyClass = {
  {
    "proxy",
    JSCLASS_HAS_PRIVATE |
    // JSCLASS_NEW_ENUMERATE |
    JSCLASS_NEW_RESOLVE |
    // JSCLASS_IS_EXTENDED |
    JSCLASS_GLOBAL_FLAGS |
    JSCLASS_MARK_IS_TRACE,
    JS_PropertyStub, // addProperty_p,
    JS_PropertyStub, // delProperty_p,
    JS_PropertyStub, // getProperty_p,
    JS_PropertyStub, // setProperty_p,
    JS_EnumerateStub, // /* (JSEnumerateOp) */ enumerate_cb,
    (JSResolveOp)resolve_cb,
    JS_ConvertStub, // convert_cb,
    JS_FinalizeStub,
    getObjectOps,
    NULL, /* checkAccess */
    NULL, /* call */
    NULL, /* construct */
    NULL, /* xdrObject */
    NULL, /* hasInstance */
    JS_CLASS_TRACE(mark),
    NULL /* reserveSlots */
  },
  NULL, /* equality */
  NULL, /* outerObject */
  NULL, /* innerObject */
  NULL, /* iteratorObject */
  wrappedObject,
  JSCLASS_NO_RESERVED_MEMBERS
};

JSObject* johnson_create_proxy_object(JSContext* cx, JSObject* target)
{
  JSObject* proxy = JS_NewObjectWithGivenProto( cx, &OurProxyClass.base, NULL, NULL );
  JS_SetPrivate( cx, proxy, target );
  if ( JS_GetParent( cx, proxy ) != NULL ) {
    abort();
  }
  JS_SetPrototype(cx, proxy, target);
  JSObject* global = JS_GetGlobalObject(cx);
  JS_SetGlobalObject(cx, proxy);
  JS_InitStandardClasses(cx, proxy);
  JS_SetGlobalObject(cx, global);
  return proxy;
}

void johnson_set_proxy_target(JSContext* cx, JSObject* proxy, JSObject* target ) {
    JS_SetPrivate( cx, proxy, target );
    // JS_SetPrototype(cx, proxy, target);
    JS_SetPrototype(cx, proxy, target);
    JSObject* global = JS_GetGlobalObject(cx);
    JS_SetGlobalObject(cx, proxy);
    JS_InitStandardClasses(cx, proxy);
    JS_SetGlobalObject(cx, global);
}
