#ifndef JOHNSON_TRACEMONKEY_JS_LAND_PROXY_H
#define JOHNSON_TRACEMONKEY_JS_LAND_PROXY_H

#include "tracemonkey.h"
#include "runtime.h"

bool js_value_is_proxy(JohnsonRuntime* runtime, jsval maybe_proxy);
VALUE unwrap_js_land_proxy(JohnsonRuntime* runtime, jsval proxy);
JSBool make_js_land_proxy(JohnsonRuntime* runtime, VALUE value, jsval* retval);

#if false
#include "node.h"
#else

typedef struct RNode {
    unsigned long flags;
    char *nd_file;
    union {
	struct RNode *node;
	ID id;
	VALUE value;
	VALUE (*cfunc)(ANYARGS);
	ID *tbl;
    } u1;
    union {
	struct RNode *node;
	ID id;
	long argc;
	VALUE value;
    } u2;
    union {
	struct RNode *node;
	ID id;
	long state;
	struct global_entry *entry;
	long cnt;
	VALUE value;
    } u3;
} NODE;

#define NODE_IVAR 51
#define NODE_TYPESHIFT 8
#define NODE_TYPEMASK  (((VALUE)0x7f)<<NODE_TYPESHIFT)
#define RNODE(obj)  (R_CAST(RNode)(obj))
#define nd_type(n) ((int) (((RNODE(n))->flags & NODE_TYPEMASK)>>NODE_TYPESHIFT))

#endif

typedef struct {
  VALUE oclass, rclass;
  VALUE recv;
  ID id, oid;
  NODE *body;
} METHOD;

#endif
