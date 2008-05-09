#include "error.h"

static VALUE error = Qnil;

void init_Johnson_Error(VALUE johnson)
{
  /* HACK:  These comments are *only* to make RDoc happy.
  VALUE johnson = rb_define_module("Johnson");
  */

  /* Johnson::Error class. */
  error = rb_define_class_under(johnson, "Error", rb_eStandardError);
}

NORETURN(VALUE) Johnson_Error_raise(const char* message)
{
  rb_raise(error, message);
}
