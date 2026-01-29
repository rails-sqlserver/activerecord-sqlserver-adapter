
#include <tiny_tds_ext.h>
#include <stdint.h>

// File Types/Vars

VALUE cTinyTdsResult;
extern VALUE mTinyTds, cTinyTdsClient, cTinyTdsError;
VALUE cKernel, cDate;
VALUE opt_decimal_zero, opt_float_zero, opt_one, opt_zero, opt_four, opt_19hdr, opt_onek, opt_tenk, opt_onemil, opt_onebil;
static ID intern_new, intern_utc, intern_local, intern_localtime, intern_merge,
       intern_civil, intern_new_offset, intern_plus, intern_divide, intern_bigd;
static ID sym_symbolize_keys, sym_as, sym_array, sym_cache_rows, sym_first, sym_timezone, sym_local, sym_utc, sym_empty_sets;


// Lib Macros

rb_encoding *binaryEncoding;
#define ENCODED_STR_NEW(_data, _len) ({ \
  VALUE _val = rb_str_new((char *)_data, (long)_len); \
  rb_enc_associate(_val, rwrap->encoding); \
  _val; \
})
#define ENCODED_STR_NEW2(_data2) ({ \
  VALUE _val = rb_str_new2((char *)_data2); \
  rb_enc_associate(_val, rwrap->encoding); \
  _val; \
})

#ifdef _WIN32
  #define LONG_LONG_FORMAT "I64d"
#else
  #define LONG_LONG_FORMAT "lld"
#endif


// Lib Backend (Memory Management)
static void rb_tinytds_result_mark(void *ptr)
{
  tinytds_result_wrapper *rwrap = (tinytds_result_wrapper *)ptr;

  if (rwrap) {
    rb_gc_mark(rwrap->local_offset);
    rb_gc_mark(rwrap->fields);
    rb_gc_mark(rwrap->fields_processed);
    rb_gc_mark(rwrap->results);
    rb_gc_mark(rwrap->dbresults_retcodes);
  }
}

static void rb_tinytds_result_free(void *ptr)
{
  xfree(ptr);
}

static size_t tinytds_result_wrapper_size(const void* data)
{
  return sizeof(tinytds_result_wrapper);
}

const rb_data_type_t tinytds_result_wrapper_type = {
  .wrap_struct_name = "tinytds_result_wrapper",
  .function = {
    .dmark = rb_tinytds_result_mark,
    .dfree = rb_tinytds_result_free,
    .dsize = tinytds_result_wrapper_size,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

VALUE rb_tinytds_new_result_obj(tinytds_client_wrapper *cwrap)
{
  VALUE obj;
  tinytds_result_wrapper *rwrap;
  obj = TypedData_Make_Struct(cTinyTdsResult, tinytds_result_wrapper, &tinytds_result_wrapper_type, rwrap);
  rwrap->cwrap = cwrap;
  rwrap->client = cwrap->client;
  rwrap->local_offset = Qnil;
  rwrap->fields = rb_ary_new();
  rwrap->fields_processed = rb_ary_new();
  rwrap->results = Qnil;
  rwrap->dbresults_retcodes = rb_ary_new();
  rwrap->number_of_results = 0;
  rwrap->number_of_fields = 0;
  rwrap->number_of_rows = 0;
  rb_obj_call_init(obj, 0, NULL);
  return obj;
}

// No GVL Helpers

#define NOGVL_DBCALL(_dbfunction, _client) ( \
  (RETCODE)(intptr_t)rb_thread_call_without_gvl( \
    (void *(*)(void *))_dbfunction, _client, \
    (rb_unblock_function_t*)dbcancel_ubf, _client ) \
)

static void dbcancel_ubf(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  dbcancel(client);
  userdata->dbcancel_sent = 1;
}

static void nogvl_setup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 1;
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors = malloc(ERRORS_STACK_INIT_SIZE * sizeof(tinytds_errordata));
  userdata->nonblocking_errors_size = ERRORS_STACK_INIT_SIZE;
}

static void nogvl_cleanup(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);
  userdata->nonblocking = 0;
  userdata->timing_out = 0;
  /*
  Now that the blocking operation is done, we can finally throw any
  exceptions based on errors from SQL Server.
  */
  short int i;

  for (i = 0; i < userdata->nonblocking_errors_length; i++) {
    tinytds_errordata error = userdata->nonblocking_errors[i];

    // lookahead to drain any info messages ahead of raising error
    if (!error.is_message) {
      short int j;

      for (j = i; j < userdata->nonblocking_errors_length; j++) {
        tinytds_errordata msg_error = userdata->nonblocking_errors[j];

        if (msg_error.is_message) {
          rb_tinytds_raise_error(client, msg_error);
        }
      }
    }

    rb_tinytds_raise_error(client, error);
  }

  free(userdata->nonblocking_errors);
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors_size = 0;
}

static RETCODE nogvl_dbsqlok(DBPROCESS *client)
{
  int retcode = FAIL;
  GET_CLIENT_USERDATA(client);
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlok, client);
  nogvl_cleanup(client);
  userdata->dbsqlok_sent = 1;
  return retcode;
}

static RETCODE nogvl_dbsqlexec(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbsqlexec, client);
  nogvl_cleanup(client);
  return retcode;
}

static RETCODE nogvl_dbresults(DBPROCESS *client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbresults, client);
  nogvl_cleanup(client);
  return retcode;
}

static RETCODE nogvl_dbnextrow(DBPROCESS * client)
{
  int retcode = FAIL;
  nogvl_setup(client);
  retcode = NOGVL_DBCALL(dbnextrow, client);
  nogvl_cleanup(client);
  return retcode;
}

// Lib Backend (Helpers)

static RETCODE rb_tinytds_result_dbresults_retcode(VALUE self)
{
  VALUE ruby_rc;
  RETCODE db_rc;
  GET_RESULT_WRAPPER(self);
  ruby_rc = rb_ary_entry(rwrap->dbresults_retcodes, rwrap->number_of_results);

  if (NIL_P(ruby_rc)) {
    db_rc = nogvl_dbresults(rwrap->client);
    ruby_rc = INT2FIX(db_rc);
    rb_ary_store(rwrap->dbresults_retcodes, rwrap->number_of_results, ruby_rc);
  } else {
    db_rc = FIX2INT(ruby_rc);
  }

  return db_rc;
}

static RETCODE rb_tinytds_result_ok_helper(DBPROCESS *client)
{
  GET_CLIENT_USERDATA(client);

  if (userdata->dbsqlok_sent == 0) {
    userdata->dbsqlok_retcode = nogvl_dbsqlok(client);
  }

  return userdata->dbsqlok_retcode;
}

static void rb_tinytds_result_exec_helper(DBPROCESS *client)
{
  RETCODE dbsqlok_rc = rb_tinytds_result_ok_helper(client);
  GET_CLIENT_USERDATA(client);

  if (dbsqlok_rc == SUCCEED) {
    /*
    This is to just process each result set. Commands such as backup and
    restore are not done when the first result set is returned, so we need to
    exhaust the result sets before it is complete.
    */
    while (nogvl_dbresults(client) == SUCCEED) {
      /*
      If we don't loop through each row for calls to TinyTds::Result.do that
      actually do return result sets, we will trigger error 20019 about trying
      to execute a new command with pending results. Oh well.
      */
      while (dbnextrow(client) != NO_MORE_ROWS);
    }
  }

  dbcancel(client);
  userdata->dbcancel_sent = 1;
  userdata->dbsql_sent = 0;
}

static VALUE rb_tinytds_result_fetch_row(VALUE self, ID timezone, int symbolize_keys, int as_array)
{
  VALUE row;
  /* Storing Values */
  unsigned int i;
  /* Wrapper And Local Vars */
  GET_RESULT_WRAPPER(self);
  /* Create Empty Row */
  row = as_array ? rb_ary_new2(rwrap->number_of_fields) : rb_hash_new();

  for (i = 0; i < rwrap->number_of_fields; i++) {
    VALUE val = Qnil;
    int col = i+1;
    int coltype = dbcoltype(rwrap->client, col);
    BYTE *data = dbdata(rwrap->client, col);
    DBINT data_len = dbdatlen(rwrap->client, col);
    int null_val = ((data == NULL) && (data_len == 0));

    if (!null_val) {
      switch(coltype) {
        case SYBINT1:
          val = INT2FIX(*(DBTINYINT *)data);
          break;

        case SYBINT2:
          val = INT2FIX(*(DBSMALLINT *)data);
          break;

        case SYBINT4:
          val = INT2NUM(*(DBINT *)data);
          break;

        case SYBINT8:
          val = LL2NUM(*(DBBIGINT *)data);
          break;

        case SYBBIT:
          val = *(int *)data ? Qtrue : Qfalse;
          break;

        case SYBNUMERIC:
        case SYBDECIMAL: {
          DBTYPEINFO *data_info = dbcoltypeinfo(rwrap->client, col);
          int data_slength = (int)data_info->precision + (int)data_info->scale + 1;
          char converted_decimal[data_slength];
          dbconvert(rwrap->client, coltype, data, data_len, SYBVARCHAR, (BYTE *)converted_decimal, -1);
          val = rb_funcall(cKernel, intern_bigd, 1, rb_str_new2((char *)converted_decimal));
          break;
        }

        case SYBFLT8: {
          double col_to_double = *(double *)data;
          val = (col_to_double == 0.000000) ? opt_float_zero : rb_float_new(col_to_double);
          break;
        }

        case SYBREAL: {
          float col_to_float = *(float *)data;
          val = (col_to_float == 0.0) ? opt_float_zero : rb_float_new(col_to_float);
          break;
        }

        case SYBMONEY: {
          DBMONEY *money = (DBMONEY *)data;
          char converted_money[25];
          long long money_value = ((long long)money->mnyhigh << 32) | money->mnylow;
          sprintf(converted_money, "%" LONG_LONG_FORMAT, money_value);
          val = rb_funcall(cKernel, intern_bigd, 2, rb_str_new2(converted_money), opt_four);
          val = rb_funcall(val, intern_divide, 1, opt_tenk);
          break;
        }

        case SYBMONEY4: {
          DBMONEY4 *money = (DBMONEY4 *)data;
          char converted_money[20];
          sprintf(converted_money, "%f", money->mny4 / 10000.0);
          val = rb_funcall(cKernel, intern_bigd, 1, rb_str_new2(converted_money));
          break;
        }

        case SYBBINARY:
        case SYBIMAGE:
          val = rb_str_new((char *)data, (long)data_len);
          #ifdef HAVE_RUBY_ENCODING_H
          rb_enc_associate(val, binaryEncoding);
          #endif
          break;

        case 36: { // SYBUNIQUE
          char converted_unique[37];
          dbconvert(rwrap->client, coltype, data, 37, SYBVARCHAR, (BYTE *)converted_unique, -1);
          val = ENCODED_STR_NEW2(converted_unique);
          break;
        }

        case SYBDATETIME4: {
          DBDATETIME new_data;
          dbconvert(rwrap->client, coltype, data, data_len, SYBDATETIME, (BYTE *)&new_data, sizeof(new_data));
          data = (BYTE *)&new_data;
          data_len = sizeof(new_data);
        }

        case SYBDATETIME: {
          DBDATEREC dr;
          dbdatecrack(rwrap->client, &dr, (DBDATETIME *)data);

          if (dr.year + dr.month + dr.day + dr.hour + dr.minute + dr.second + dr.millisecond != 0) {
            val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(dr.year), INT2NUM(dr.month), INT2NUM(dr.day), INT2NUM(dr.hour), INT2NUM(dr.minute), INT2NUM(dr.second), INT2NUM(dr.millisecond*1000));
          }

          break;
        }

        case SYBMSDATE:
        case SYBMSTIME:
        case SYBMSDATETIME2:
        case SYBMSDATETIMEOFFSET: {
          DBDATEREC2 dr2;
          dbanydatecrack(rwrap->client, &dr2, coltype, data);

          switch(coltype) {
            case SYBMSDATE: {
              val = rb_funcall(cDate, intern_new, 3, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day));
              break;
            }

            case SYBMSTIME: {
              VALUE rational_nsec = rb_Rational(INT2NUM(dr2.nanosecond), opt_onek);
              val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(1900), INT2NUM(1), INT2NUM(1), INT2NUM(dr2.hour), INT2NUM(dr2.minute), INT2NUM(dr2.second), rational_nsec);
              break;
            }

            case SYBMSDATETIME2: {
              VALUE rational_nsec = rb_Rational(INT2NUM(dr2.nanosecond), opt_onek);
              val = rb_funcall(rb_cTime, timezone, 7, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day), INT2NUM(dr2.hour), INT2NUM(dr2.minute), INT2NUM(dr2.second), rational_nsec);
              break;
            }

            case SYBMSDATETIMEOFFSET: {
              long long numerator = ((long)dr2.second * (long long)1000000000) + (long long)dr2.nanosecond;
              VALUE rational_sec = rb_Rational(LL2NUM(numerator), opt_onebil);
              val = rb_funcall(rb_cTime, intern_new, 7, INT2NUM(dr2.year), INT2NUM(dr2.month), INT2NUM(dr2.day), INT2NUM(dr2.hour), INT2NUM(dr2.minute), rational_sec, INT2NUM(dr2.tzone*60));
              break;
            }
          }

          break;
        }

        case SYBCHAR:
        case SYBTEXT:
          val = ENCODED_STR_NEW(data, data_len);
          break;

        case 98: { // SYBVARIANT
          if (data_len == 4) {
            val = INT2NUM(*(DBINT *)data);
            break;
          } else {
            val = ENCODED_STR_NEW(data, data_len);
            break;
          }
        }

        default:
          val = ENCODED_STR_NEW(data, data_len);
          break;
      }
    }

    if (as_array) {
      rb_ary_store(row, i, val);
    } else {
      VALUE key;

      if (rwrap->number_of_results == 0) {
        key = rb_ary_entry(rwrap->fields, i);
      } else {
        key = rb_ary_entry(rb_ary_entry(rwrap->fields, rwrap->number_of_results), i);
      }

      rb_hash_aset(row, key, val);
    }
  }

  return row;
}


// TinyTds::Client (public)

static VALUE rb_tinytds_result_fields(VALUE self)
{
  RETCODE dbsqlok_rc, dbresults_rc;
  VALUE fields_processed;
  GET_RESULT_WRAPPER(self);
  dbsqlok_rc = rb_tinytds_result_ok_helper(rwrap->client);
  dbresults_rc = rb_tinytds_result_dbresults_retcode(self);
  fields_processed = rb_ary_entry(rwrap->fields_processed, rwrap->number_of_results);

  if ((dbsqlok_rc == SUCCEED) && (dbresults_rc == SUCCEED) && (fields_processed == Qnil)) {
    /* Default query options. */
    int symbolize_keys = 0;
    VALUE qopts = rb_iv_get(self, "@query_options");

    if (rb_hash_aref(qopts, sym_symbolize_keys) == Qtrue) {
      symbolize_keys = 1;
    }

    /* Set number_of_fields count for this result set. */
    rwrap->number_of_fields = dbnumcols(rwrap->client);

    if (rwrap->number_of_fields > 0) {
      /* Create fields for this result set. */
      unsigned int fldi = 0;
      VALUE fields = rb_ary_new2(rwrap->number_of_fields);

      for (fldi = 0; fldi < rwrap->number_of_fields; fldi++) {
        char *colname = dbcolname(rwrap->client, fldi+1);
        VALUE field = symbolize_keys ? rb_str_intern(ENCODED_STR_NEW2(colname))  : rb_obj_freeze(ENCODED_STR_NEW2(colname));
        rb_ary_store(fields, fldi, field);
      }

      /* Store the fields. */
      if (rwrap->number_of_results == 0) {
        rwrap->fields = fields;
      } else if (rwrap->number_of_results == 1) {
        VALUE multi_rs_fields = rb_ary_new();
        rb_ary_store(multi_rs_fields, 0, rwrap->fields);
        rb_ary_store(multi_rs_fields, 1, fields);
        rwrap->fields = multi_rs_fields;
      } else {
        rb_ary_store(rwrap->fields, rwrap->number_of_results, fields);
      }
    }

    rb_ary_store(rwrap->fields_processed, rwrap->number_of_results, Qtrue);
  }

  return rwrap->fields;
}

static VALUE rb_tinytds_result_each(int argc, VALUE * argv, VALUE self)
{
  /* Local Vars */
  VALUE qopts, opts, block;
  ID timezone;
  int symbolize_keys = 0, as_array = 0, cache_rows = 0, first = 0, empty_sets = 0;
  tinytds_client_userdata *userdata;
  GET_RESULT_WRAPPER(self);
  userdata = (tinytds_client_userdata *)dbgetuserdata(rwrap->client);
  /* Merge Options Hash To Query Options. Populate Opts & Block Var. */
  qopts = rb_iv_get(self, "@query_options");

  if (rb_scan_args(argc, argv, "01&", &opts, &block) == 1) {
    qopts = rb_funcall(qopts, intern_merge, 1, opts);
  }

  rb_iv_set(self, "@query_options", qopts);

  /* Locals From Options */
  if (rb_hash_aref(qopts, sym_first) == Qtrue) {
    first = 1;
  }

  if (rb_hash_aref(qopts, sym_symbolize_keys) == Qtrue) {
    symbolize_keys = 1;
  }

  if (rb_hash_aref(qopts, sym_as) == sym_array) {
    as_array = 1;
  }

  if (rb_hash_aref(qopts, sym_cache_rows) == Qtrue) {
    cache_rows = 1;
  }

  if (rb_hash_aref(qopts, sym_timezone) == sym_local) {
    timezone = intern_local;
  } else if (rb_hash_aref(qopts, sym_timezone) == sym_utc) {
    timezone = intern_utc;
  } else {
    rb_warn(":timezone option must be :utc or :local - defaulting to :local");
    timezone = intern_local;
  }

  if (rb_hash_aref(qopts, sym_empty_sets) == Qtrue) {
    empty_sets = 1;
  }

  /* Make The Results Or Yield Existing */
  if (NIL_P(rwrap->results)) {
    RETCODE dbsqlok_rc, dbresults_rc;
    rwrap->results = rb_ary_new();
    dbsqlok_rc = rb_tinytds_result_ok_helper(rwrap->client);
    dbresults_rc = rb_tinytds_result_dbresults_retcode(self);

    while ((dbsqlok_rc == SUCCEED) && (dbresults_rc == SUCCEED)) {
      int has_rows = (DBROWS(rwrap->client) == SUCCEED) ? 1 : 0;

      if (has_rows || empty_sets || (rwrap->number_of_results == 0)) {
        rb_tinytds_result_fields(self);
      }

      if ((has_rows || empty_sets) && rwrap->number_of_fields > 0) {
        /* Create rows for this result set. */
        unsigned long rowi = 0;
        VALUE result = rb_ary_new();

        while (nogvl_dbnextrow(rwrap->client) != NO_MORE_ROWS) {
          VALUE row = rb_tinytds_result_fetch_row(self, timezone, symbolize_keys, as_array);

          if (cache_rows) {
            rb_ary_store(result, rowi, row);
          }

          if (!NIL_P(block)) {
            rb_yield(row);
          }

          if (first) {
            dbcanquery(rwrap->client);
            userdata->dbcancel_sent = 1;
          }

          rowi++;
        }

        rwrap->number_of_rows = rowi;

        /* Store the result. */
        if (cache_rows) {
          if (rwrap->number_of_results == 0) {
            rwrap->results = result;
          } else if (rwrap->number_of_results == 1) {
            VALUE multi_resultsets = rb_ary_new();
            rb_ary_store(multi_resultsets, 0, rwrap->results);
            rb_ary_store(multi_resultsets, 1, result);
            rwrap->results = multi_resultsets;
          } else {
            rb_ary_store(rwrap->results, rwrap->number_of_results, result);
          }
        }

        // If we find results increment the counter that helpers use and setup the next loop.
        rwrap->number_of_results = rwrap->number_of_results + 1;
        dbresults_rc = rb_tinytds_result_dbresults_retcode(self);
        rb_ary_store(rwrap->fields_processed, rwrap->number_of_results, Qnil);
      } else {
        // If we do not find results, side step the rb_tinytds_result_dbresults_retcode helper and
        // manually populate its memoized array while nullifing any memoized fields too before loop.
        dbresults_rc = nogvl_dbresults(rwrap->client);
        rb_ary_store(rwrap->dbresults_retcodes, rwrap->number_of_results, INT2FIX(dbresults_rc));
        rb_ary_store(rwrap->fields_processed, rwrap->number_of_results, Qnil);
      }
    }

    if (dbresults_rc == FAIL) {
      rb_warn("TinyTDS: Something in the dbresults() while loop set the return code to FAIL.\n");
    }

    userdata->dbsql_sent = 0;
  } else if (!NIL_P(block)) {
    unsigned long i;

    for (i = 0; i < rwrap->number_of_rows; i++) {
      rb_yield(rb_ary_entry(rwrap->results, i));
    }
  }

  return rwrap->results;
}

static VALUE rb_tinytds_result_cancel(VALUE self)
{
  tinytds_client_userdata *userdata;
  GET_RESULT_WRAPPER(self);
  userdata = (tinytds_client_userdata *)dbgetuserdata(rwrap->client);

  if (rwrap->client && !userdata->dbcancel_sent) {
    rb_tinytds_result_ok_helper(rwrap->client);
    dbcancel(rwrap->client);
    userdata->dbcancel_sent = 1;
    userdata->dbsql_sent = 0;
  }

  return Qtrue;
}

static VALUE rb_tinytds_result_do(VALUE self)
{
  GET_RESULT_WRAPPER(self);

  if (rwrap->client) {
    rb_tinytds_result_exec_helper(rwrap->client);
    return LONG2NUM((long)dbcount(rwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_result_affected_rows(VALUE self)
{
  GET_RESULT_WRAPPER(self);

  if (rwrap->client) {
    return LONG2NUM((long)dbcount(rwrap->client));
  } else {
    return Qnil;
  }
}

/* Duplicated in client.c */
static VALUE rb_tinytds_result_return_code(VALUE self)
{
  GET_RESULT_WRAPPER(self);

  if (rwrap->client && dbhasretstat(rwrap->client)) {
    return LONG2NUM((long)dbretstatus(rwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_result_insert(VALUE self)
{
  GET_RESULT_WRAPPER(self);

  if (rwrap->client) {
    VALUE identity = Qnil;
    rb_tinytds_result_exec_helper(rwrap->client);
    dbcmd(rwrap->client, rwrap->cwrap->identity_insert_sql);

    if (nogvl_dbsqlexec(rwrap->client) != FAIL
        && nogvl_dbresults(rwrap->client) != FAIL
        && DBROWS(rwrap->client) != FAIL) {
      while (nogvl_dbnextrow(rwrap->client) != NO_MORE_ROWS) {
        int col = 1;
        BYTE *data = dbdata(rwrap->client, col);
        DBINT data_len = dbdatlen(rwrap->client, col);
        int null_val = ((data == NULL) && (data_len == 0));

        if (!null_val) {
          identity = LL2NUM(*(DBBIGINT *)data);
        }
      }
    }

    return identity;
  } else {
    return Qnil;
  }
}


// Lib Init

void init_tinytds_result()
{
  /* Data Classes */
  cKernel = rb_const_get(rb_cObject, rb_intern("Kernel"));
  cDate = rb_const_get(rb_cObject, rb_intern("Date"));
  /* Define TinyTds::Result */
  cTinyTdsResult = rb_define_class_under(mTinyTds, "Result", rb_cObject);
  rb_undef_alloc_func(cTinyTdsResult);
  /* Define TinyTds::Result Public Methods */
  rb_define_method(cTinyTdsResult, "fields", rb_tinytds_result_fields, 0);
  rb_define_method(cTinyTdsResult, "each", rb_tinytds_result_each, -1);
  rb_define_method(cTinyTdsResult, "cancel", rb_tinytds_result_cancel, 0);
  rb_define_method(cTinyTdsResult, "do", rb_tinytds_result_do, 0);
  rb_define_method(cTinyTdsResult, "affected_rows", rb_tinytds_result_affected_rows, 0);
  rb_define_method(cTinyTdsResult, "return_code", rb_tinytds_result_return_code, 0);
  rb_define_method(cTinyTdsResult, "insert", rb_tinytds_result_insert, 0);
  /* Intern String Helpers */
  intern_new = rb_intern("new");
  intern_utc = rb_intern("utc");
  intern_local = rb_intern("local");
  intern_merge = rb_intern("merge");
  intern_localtime = rb_intern("localtime");
  intern_civil = rb_intern("civil");
  intern_new_offset = rb_intern("new_offset");
  intern_plus = rb_intern("+");
  intern_divide = rb_intern("/");
  intern_bigd = rb_intern("BigDecimal");
  /* Symbol Helpers */
  sym_symbolize_keys = ID2SYM(rb_intern("symbolize_keys"));
  sym_as = ID2SYM(rb_intern("as"));
  sym_array = ID2SYM(rb_intern("array"));
  sym_cache_rows = ID2SYM(rb_intern("cache_rows"));
  sym_first = ID2SYM(rb_intern("first"));
  sym_local = ID2SYM(intern_local);
  sym_utc = ID2SYM(intern_utc);
  sym_timezone = ID2SYM(rb_intern("timezone"));
  sym_empty_sets = ID2SYM(rb_intern("empty_sets"));
  /* Data Conversion Options */
  opt_decimal_zero = rb_str_new2("0.0");
  rb_global_variable(&opt_decimal_zero);
  opt_float_zero = rb_float_new((double)0);
  rb_global_variable(&opt_float_zero);
  opt_one = INT2NUM(1);
  opt_zero = INT2NUM(0);
  opt_four = INT2NUM(4);
  opt_19hdr = INT2NUM(1900);
  opt_onek = INT2NUM(1000);
  opt_tenk = INT2NUM(10000);
  opt_onemil = INT2NUM(1000000);
  opt_onebil = INT2NUM(1000000000);
  /* Encoding */
  #ifdef HAVE_RUBY_ENCODING_H
  binaryEncoding = rb_enc_find("binary");
  #endif
}
