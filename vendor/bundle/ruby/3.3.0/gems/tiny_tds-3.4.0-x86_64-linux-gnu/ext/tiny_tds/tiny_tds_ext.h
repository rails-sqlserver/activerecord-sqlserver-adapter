#ifndef TINYTDS_EXT
#define TINYTDS_EXT

#undef SYBDBLIB
#define MSDBLIB 1

#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/version.h>
#include <ruby/thread.h>
#include <sybfront.h>
#include <sybdb.h>

#include <client.h>
#include <result.h>

#endif
