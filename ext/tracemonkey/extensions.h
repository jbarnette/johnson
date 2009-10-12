#ifndef JOHNSON_TRACEMONKEY_EXTENSIONS_H
#define JOHNSON_TRACEMONKEY_EXTENSIONS_H

#include "tracemonkey.h"
#include "context.h"
#include "conversions.h"

// A context is passed here because there might not be a current context
// for the runtime when the function is called.
VALUE init_tracemonkey_extensions(JohnsonContext* context, VALUE self);

#endif
