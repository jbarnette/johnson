#include "idhash.h"

static JSHashNumber key_hash(const void *key)
{
  return (JSHashNumber)(unsigned long)key;
}

static intN comparator(const void *v1, const void *v2)
{
  return v1 == v2;
}

JSHashTable* create_id_hash()
{
  return JS_NewHashTable(0, key_hash, comparator, comparator, NULL, NULL);  
}
