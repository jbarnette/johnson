#include "idhash.h"

static JSHashNumber key_hash(const void *key)
{
  // just use the jsid
  return (JSHashNumber)key;
}

static intN key_comparator(const void *v1, const void *v2)
{
  return (jsid)v1 == (jsid)v2;
}

static intN value_comparator(const void* v1, const void* v2)
{
  return (VALUE)v1 == (VALUE)v2;
}

JSHashTable * new_idhash()
{
  return JS_NewHashTable(0, key_hash, key_comparator, value_comparator, NULL, NULL);  
}
