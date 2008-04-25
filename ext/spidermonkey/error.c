#include "error.h"

static VALUE error = Qnil;

void init_Johnson_Error(VALUE johnson)
{
  error = rb_define_class_under(johnson, "Error", rb_eStandardError);
}

NORETURN(VALUE) Johnson_Error_raise(const char* message)
{
  rb_raise(error, message);
}
