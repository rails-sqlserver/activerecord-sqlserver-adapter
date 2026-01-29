#include <tiny_tds_ext.h>

#ifndef DBVERSION_73
  #error "DBVERSION_73 is not defined. Aborting compilation."
#endif

VALUE mTinyTds, cTinyTdsError;

void Init_tiny_tds()
{
  mTinyTds      = rb_define_module("TinyTds");
  cTinyTdsError = rb_const_get(mTinyTds, rb_intern("Error"));
  init_tinytds_client();
  init_tinytds_result();
}

