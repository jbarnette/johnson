/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * vim: set ts=8 sw=4 et tw=99:
 */

// liberally copied from mozilla shell source (js.cpp) (MPL 1.1/GPL 2.0/LGPL 2.1)

// Changes from js.cpp:

// The newer moz sources override thisobject. That code is commented
// out below. There's a bug (https://bugzilla.mozilla.org/show_bug.cgi?id=542864) that
// makes getters work incorrectly against split globals, which is fatal to some downstream stuff.
// Hopefully can revert to moz sources when this is fixed.

// Equality does more checking; this should === outer, but because of the patch above, it doesn't.
// Remove when this is handled correctly.

// The net of the above is that 'this' in an inner context will not be outer, which means the inner
// object might possibly escape. A corner case that hasn't affected any downstream code at this point.

/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Mozilla Communicator client code, released
 * March 31, 1998.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#define LAZY_STANDARD_CLASSES

/* A class for easily testing the inner/outer object callbacks. */
typedef struct ComplexObject {
    JSBool isInner;
    JSBool frozen;
    JSObject *inner;
    JSObject *outer;
} ComplexObject;

static JSObject *
split_create_outer(JSContext *cx);

static JSObject *
split_create_inner(JSContext *cx, JSObject *outer);

static ComplexObject *
split_get_private(JSContext *cx, JSObject *obj);

static JSBool
split_addProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    ComplexObject *cpx;
    jsid asId;

    cpx = split_get_private(cx, obj);
    if (!cpx)
        return JS_TRUE;
    if (!cpx->isInner && cpx->inner) {
        /* Make sure to define this property on the inner object. */
        if (!JS_ValueToId(cx, *vp, &asId))
            return JS_FALSE;
        return JS_DefinePropertyById(cx, cpx->inner, asId, *vp, NULL, NULL, JSPROP_ENUMERATE);
    }
    return JS_TRUE;
}

static JSBool
split_getProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    ComplexObject *cpx;

    cpx = split_get_private(cx, obj);
    if (!cpx)
        return JS_TRUE;

    if (JSVAL_IS_STRING(id) &&
        !strcmp(JS_GetStringBytes(JSVAL_TO_STRING(id)), "isInner")) {
        *vp = BOOLEAN_TO_JSVAL(cpx->isInner);
        return JS_TRUE;
    }

    if (!cpx->isInner && cpx->inner) {
        if (JSVAL_IS_STRING(id)) {
            JSString *str;

            str = JSVAL_TO_STRING(id);
            return JS_GetUCProperty(cx, cpx->inner, JS_GetStringChars(str),
                                    JS_GetStringLength(str), vp);
        }
        if (JSVAL_IS_INT(id))
            return JS_GetElement(cx, cpx->inner, JSVAL_TO_INT(id), vp);
        return JS_TRUE;
    }

    return JS_TRUE;
}

static JSBool
split_setProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    ComplexObject *cpx;

    cpx = split_get_private(cx, obj);
    if (!cpx)
        return JS_TRUE;
    if (!cpx->isInner && cpx->inner) {
        if (JSVAL_IS_STRING(id)) {
            JSString *str;

            str = JSVAL_TO_STRING(id);
            return JS_SetUCProperty(cx, cpx->inner, JS_GetStringChars(str),
                                    JS_GetStringLength(str), vp);
        }
        if (JSVAL_IS_INT(id))
            return JS_SetElement(cx, cpx->inner, JSVAL_TO_INT(id), vp);
        return JS_TRUE;
    }

    return JS_TRUE;
}

static JSBool
split_delProperty(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
    ComplexObject *cpx;
    jsid asId;

    cpx = split_get_private(cx, obj);
    if (!cpx)
        return JS_TRUE;
    if (!cpx->isInner && cpx->inner) {
        /* Make sure to define this property on the inner object. */
        if (!JS_ValueToId(cx, *vp, &asId))
            return JS_FALSE;
        return cpx->inner->deleteProperty(cx, asId, vp);
    }
    return JS_TRUE;
}

static JSBool
split_enumerate(JSContext *cx, JSObject *obj, JSIterateOp enum_op,
                  jsval *statep, jsid *idp)
{
    ComplexObject *cpx;
    JSObject *iterator;

    switch (enum_op) {
      case JSENUMERATE_INIT:
        cpx = (ComplexObject *) JS_GetPrivate(cx, obj);

        if (!cpx->isInner && cpx->inner)
            obj = cpx->inner;

        iterator = JS_NewPropertyIterator(cx, obj);
        if (!iterator)
            return JS_FALSE;

        *statep = OBJECT_TO_JSVAL(iterator);
        if (idp)
            *idp = JSVAL_ZERO;
        break;

      case JSENUMERATE_NEXT:
        iterator = (JSObject*)JSVAL_TO_OBJECT(*statep);
        if (!JS_NextProperty(cx, iterator, idp))
            return JS_FALSE;

        if (!JSVAL_IS_VOID(*idp))
            break;
        /* Fall through. */

      case JSENUMERATE_DESTROY:
        /* Let GC at our iterator object. */
        *statep = JSVAL_NULL;
        break;
    }

    return JS_TRUE;
}

static JSBool
split_resolve(JSContext *cx, JSObject *obj, jsval id, uintN flags,
                JSObject **objp)
{
    ComplexObject *cpx;

    if (JSVAL_IS_STRING(id) &&
        !strcmp(JS_GetStringBytes(JSVAL_TO_STRING(id)), "isInner")) {
        *objp = obj;
        return JS_DefineProperty(cx, obj, "isInner", JSVAL_VOID, NULL, NULL,
                                 JSPROP_SHARED);
    }

    cpx = split_get_private(cx, obj);
    if (!cpx)
        return JS_TRUE;
    if (!cpx->isInner && cpx->inner) {
        jsid asId;
        JSProperty *prop;

        if (!JS_ValueToId(cx, id, &asId))
            return JS_FALSE;

        if (!cpx->inner->lookupProperty(cx, asId, objp, &prop))
            return JS_FALSE;
        if (prop)
            cpx->inner->dropProperty(cx, prop);

        return JS_TRUE;
    }

#ifdef LAZY_STANDARD_CLASSES
    if (!(flags & JSRESOLVE_ASSIGNING)) {
        JSBool resolved;

        if (!JS_ResolveStandardClass(cx, obj, id, &resolved))
            return JS_FALSE;

        if (resolved) {
            *objp = obj;
            return JS_TRUE;
        }
    }
#endif

    /* XXX For additional realism, let's resolve some random property here. */
    return JS_TRUE;
}

static void
split_finalize(JSContext *cx, JSObject *obj)
{
    JS_free(cx, JS_GetPrivate(cx, obj));
}

static uint32
split_mark(JSContext *cx, JSObject *obj, void *arg)
{
    ComplexObject *cpx;

    cpx = (ComplexObject *) JS_GetPrivate(cx, obj);

    if (!cpx->isInner && cpx->inner) {
        /* Mark the inner object. */
        JS_MarkGCThing(cx, cpx->inner, "ComplexObject.inner", arg);
    }

    return 0;
}

static JSObject *
split_outerObject(JSContext *cx, JSObject *obj)
{
    ComplexObject *cpx;

    cpx = (ComplexObject *) JS_GetPrivate(cx, obj);
    return cpx->isInner ? cpx->outer : obj;
}

static JSObject *
split_thisObject(JSContext *cx, JSObject *obj)
{
    OBJ_TO_OUTER_OBJECT(cx, obj);
    if (!obj)
        return NULL;
    return obj;
}

static JSObjectOps split_objectops;

static JSObjectOps *
split_getObjectOps(JSContext *cx, JSClass *clasp)
{
    if (!split_objectops.thisObject) {
        memcpy(&split_objectops, &js_ObjectOps, sizeof split_objectops);
        /* see note above */
        /* split_objectops.thisObject = split_thisObject; */
    }

    return &split_objectops;
}

static JSBool
split_equality(JSContext *cx, JSObject *obj, jsval v, JSBool *bp);

static JSObject *
split_innerObject(JSContext *cx, JSObject *obj)
{
    ComplexObject *cpx;

    cpx = (ComplexObject *) JS_GetPrivate(cx, obj);
    if (cpx->frozen) {
        JS_ASSERT(!cpx->isInner);
        return obj;
    }
    return !cpx->isInner ? cpx->inner : obj;
}

static JSExtendedClass split_global_class = {
    {"split_global",
    JSCLASS_NEW_RESOLVE | JSCLASS_NEW_ENUMERATE | JSCLASS_HAS_PRIVATE |
    JSCLASS_GLOBAL_FLAGS | JSCLASS_IS_EXTENDED,
    split_addProperty, split_delProperty,
    split_getProperty, split_setProperty,
    (JSEnumerateOp)split_enumerate,
    (JSResolveOp)split_resolve,
    JS_ConvertStub, split_finalize,
    split_getObjectOps, NULL, NULL, NULL, NULL, NULL,
    split_mark, NULL},
    split_equality, split_outerObject, split_innerObject,
    NULL, NULL, NULL, NULL, NULL
};

#if 0
static JSBool
split_equality(JSContext *cx, JSObject *obj, jsval v, JSBool *bp)
{
    *bp = JS_FALSE;
    if (JSVAL_IS_PRIMITIVE(v))
        return JS_TRUE;

    JSObject *obj2 = JSVAL_TO_OBJECT(v);
    if (JS_GET_CLASS(cx, obj2) != &split_global_class.base)
        return JS_TRUE;

    ComplexObject *cpx = (ComplexObject *) JS_GetPrivate(cx, obj2);
    JS_ASSERT(!cpx->isInner);

    ComplexObject *ourCpx = (ComplexObject *) JS_GetPrivate(cx, obj);
    JS_ASSERT(!ourCpx->isInner);

    *bp = (cpx == ourCpx);
    return JS_TRUE;
}
#else
static JSBool
split_equality(JSContext *cx, JSObject *obj, jsval v, JSBool *bp)
{
    *bp = JS_FALSE;
    if (JSVAL_IS_PRIMITIVE(v))
        return JS_TRUE;

    JSObject *obj2 = JSVAL_TO_OBJECT(v);
    if (JS_GET_CLASS(cx, obj2) != &split_global_class.base)
        return JS_TRUE;

    ComplexObject *cpx = (ComplexObject *) JS_GetPrivate(cx, obj2);
    ComplexObject *ourCpx = (ComplexObject *) JS_GetPrivate(cx, obj);

    if( cpx == ourCpx ) {
      *bp = JS_TRUE;
    } else if ( cpx->inner ) {
      *bp = ( cpx->inner == obj && ourCpx->outer == obj2);
    } else {
      *bp = ( cpx->outer == obj && ourCpx->inner == obj2);
    }
    return JS_TRUE;
}
#endif

JSObject *
split_create_outer(JSContext *cx)
{
    ComplexObject *cpx;
    JSObject *obj;

    cpx = (ComplexObject *) JS_malloc(cx, sizeof *obj);
    if (!cpx)
        return NULL;
    cpx->isInner = JS_FALSE;
    cpx->frozen = JS_TRUE;
    cpx->inner = NULL;
    cpx->outer = NULL;

    obj = JS_NewObject(cx, &split_global_class.base, NULL, NULL);
    if (!obj || !JS_SetParent(cx, obj, NULL)) {
        JS_free(cx, cpx);
        return NULL;
    }

    if (!JS_SetPrivate(cx, obj, cpx)) {
        JS_free(cx, cpx);
        return NULL;
    }

    return obj;
}

static JSObject *
split_create_inner(JSContext *cx, JSObject *outer)
{
    ComplexObject *cpx, *outercpx;
    JSObject *obj;

    JS_ASSERT(JS_GET_CLASS(cx, outer) == &split_global_class.base);

    cpx = (ComplexObject *) JS_malloc(cx, sizeof *cpx);
    if (!cpx)
        return NULL;
    cpx->isInner = JS_TRUE;
    cpx->frozen = JS_FALSE;
    cpx->inner = NULL;
    cpx->outer = outer;

    obj = JS_NewObject(cx, &split_global_class.base, NULL, NULL);
    if (!obj || !JS_SetParent(cx, obj, NULL) || !JS_SetPrivate(cx, obj, cpx)) {
        JS_free(cx, cpx);
        return NULL;
    }

    outercpx = (ComplexObject *) JS_GetPrivate(cx, outer);
    outercpx->inner = obj;
    outercpx->frozen = JS_FALSE;

    return obj;
}

static ComplexObject *
split_get_private(JSContext *cx, JSObject *obj)
{
    do {
        if (JS_GET_CLASS(cx, obj) == &split_global_class.base)
            return (ComplexObject *) JS_GetPrivate(cx, obj);
        obj = JS_GetParent(cx, obj);
    } while (obj);

    return NULL;
}
