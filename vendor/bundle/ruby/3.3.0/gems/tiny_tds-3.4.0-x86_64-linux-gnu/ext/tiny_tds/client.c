#include <tiny_tds_ext.h>
#include <errno.h>

VALUE cTinyTdsClient;
extern VALUE mTinyTds, cTinyTdsError;
static ID sym_username, sym_password, sym_dataserver, sym_database, sym_appname, sym_tds_version, sym_login_timeout, sym_timeout, sym_encoding, sym_azure, sym_contained, sym_use_utf16, sym_message_handler;
static ID intern_source_eql, intern_severity_eql, intern_db_error_number_eql, intern_os_error_number_eql;
static ID intern_new, intern_dup, intern_transpose_iconv_encoding, intern_local_offset, intern_gsub, intern_call;
VALUE opt_escape_regex, opt_escape_dblquote;

static void rb_tinytds_client_mark(void *ptr)
{
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;

  if (cwrap) {
    rb_gc_mark(cwrap->charset);
  }
}

static void rb_tinytds_client_free(void *ptr)
{
  tinytds_client_wrapper *cwrap = (tinytds_client_wrapper *)ptr;

  if (cwrap->login) {
    dbloginfree(cwrap->login);
  }

  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->client = NULL;
    cwrap->closed = 1;
    cwrap->userdata->closed = 1;
  }

  xfree(cwrap->userdata);
  xfree(ptr);
}

static size_t tinytds_client_wrapper_size(const void* data)
{
  return sizeof(tinytds_client_wrapper);
}

static const rb_data_type_t tinytds_client_wrapper_type = {
  .wrap_struct_name = "tinytds_client_wrapper",
  .function = {
    .dmark = rb_tinytds_client_mark,
    .dfree = rb_tinytds_client_free,
    .dsize = tinytds_client_wrapper_size,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

// Lib Macros

#define GET_CLIENT_WRAPPER(self) \
  tinytds_client_wrapper *cwrap; \
  TypedData_Get_Struct(self, tinytds_client_wrapper, &tinytds_client_wrapper_type, cwrap)

#define REQUIRE_OPEN_CLIENT(cwrap) \
  if (cwrap->closed || cwrap->userdata->closed) { \
    rb_raise(cTinyTdsError, "closed connection"); \
    return Qnil; \
  }


// Lib Backend (Helpers)

VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, tinytds_errordata error)
{
  VALUE e;
  GET_CLIENT_USERDATA(dbproc);

  if (error.cancel && !dbdead(dbproc) && userdata && !userdata->closed) {
    userdata->dbsqlok_sent = 1;
    dbsqlok(dbproc);
    userdata->dbcancel_sent = 1;
    dbcancel(dbproc);
  }

  e = rb_exc_new2(cTinyTdsError, error.error);
  rb_funcall(e, intern_source_eql, 1, rb_str_new2(error.source));

  if (error.severity) {
    rb_funcall(e, intern_severity_eql, 1, INT2FIX(error.severity));
  }

  if (error.dberr) {
    rb_funcall(e, intern_db_error_number_eql, 1, INT2FIX(error.dberr));
  }

  if (error.oserr) {
    rb_funcall(e, intern_os_error_number_eql, 1, INT2FIX(error.oserr));
  }

  if (error.severity <= 10 && error.is_message) {
    VALUE message_handler = userdata && userdata->message_handler ? userdata->message_handler : Qnil;

    if (message_handler && message_handler != Qnil && rb_respond_to(message_handler, intern_call) != 0) {
      rb_funcall(message_handler, intern_call, 1, e);
    }

    return Qnil;
  }

  rb_exc_raise(e);
  return Qnil;
}


// Lib Backend (Memory Management & Handlers)
static void push_userdata_error(tinytds_client_userdata *userdata, tinytds_errordata error)
{
  // reallocate memory for the array as needed
  if (userdata->nonblocking_errors_size == userdata->nonblocking_errors_length) {
    userdata->nonblocking_errors_size *= 2;
    userdata->nonblocking_errors = realloc(userdata->nonblocking_errors, userdata->nonblocking_errors_size * sizeof(tinytds_errordata));
  }

  userdata->nonblocking_errors[userdata->nonblocking_errors_length] = error;
  userdata->nonblocking_errors_length++;
}

int tinytds_err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr)
{
  static const char *source = "error";
  /* Everything should cancel by default */
  int return_value = INT_CANCEL;
  int cancel = 0;

  GET_CLIENT_USERDATA(dbproc);

  /* These error codes are documented in include/sybdb.h in FreeTDS */
  switch(dberr) {

    /* We don't want to raise these as a ruby exception for various reasons */
    case 100: /* SYBEVERDOWN, indicating the connection can only be v7.1 */
    case SYBESEOF: /* Usually accompanied by another more useful error */
    case SYBESMSG: /* Generic "check messages from server" error */
    case SYBEICONVI: /* Just return ?s to the client, as explained in readme */
      return return_value;

    case SYBEICONVO:
      dbfreebuf(dbproc);
      return return_value;

    case SYBETIME:

      /*
      SYBETIME is the only error that can send INT_TIMEOUT or INT_CONTINUE,
      but we don't ever want to automatically retry. Instead have the app
      decide what to do.
      */
      if (userdata && userdata->timing_out) {
        return INT_CANCEL;
      }

      // userdata will not be set if hitting timeout during login so check for it first
      if (userdata) {
        userdata->timing_out = 1;
      }

      return_value = INT_TIMEOUT;
      cancel = 1;
      break;

    case SYBEWRIT:

      /* Write errors may happen after we abort a statement */
      if (userdata && (userdata->dbsqlok_sent || userdata->dbcancel_sent)) {
        return return_value;
      }

      cancel = 1;
      break;
  }

  tinytds_errordata error_data = {
    .is_message = 0,
    .cancel = cancel,
    .severity = severity,
    .dberr = dberr,
    .oserr = oserr
  };
  strncpy(error_data.error, dberrstr, ERROR_MSG_SIZE);
  strncpy(error_data.source, source, ERROR_MSG_SIZE);

  /*
  When in non-blocking mode we need to store the exception data to throw it
  once the blocking call returns, otherwise we will segfault ruby since part
  of the contract of the ruby non-blocking indicator is that you do not call
  any of the ruby C API.
  */
  if (userdata && userdata->nonblocking) {
    if (cancel && !dbdead(dbproc) && !userdata->closed) {
      dbcancel(dbproc);
      userdata->dbcancel_sent = 1;
    }

    push_userdata_error(userdata, error_data);
  } else {
    rb_tinytds_raise_error(dbproc, error_data);
  }

  return return_value;
}

int tinytds_msg_handler(DBPROCESS *dbproc, DBINT msgno, int msgstate, int severity, char *msgtext, char *srvname, char *procname, int line)
{
  static const char *source = "message";
  GET_CLIENT_USERDATA(dbproc);

  int is_message_an_error = severity > 10 ? 1 : 0;

  tinytds_errordata error_data = {
    .is_message = !is_message_an_error,
    .cancel = is_message_an_error,
    .severity = severity,
    .dberr = msgno,
    .oserr = msgstate
  };
  strncpy(error_data.error, msgtext, ERROR_MSG_SIZE);
  strncpy(error_data.source, source, ERROR_MSG_SIZE);

  // See tinytds_err_handler() for info about why we do this
  if (userdata && userdata->nonblocking) {
    /*
    In the case of non-blocking command batch execution we can receive multiple messages
    (including errors). We keep track of those here so they can be processed once the
    non-blocking call returns.
    */
    push_userdata_error(userdata, error_data);

    if (is_message_an_error && !dbdead(dbproc) && !userdata->closed) {
      dbcancel(dbproc);
      userdata->dbcancel_sent = 1;
    }
  } else {
    rb_tinytds_raise_error(dbproc, error_data);
  }

  return 0;
}

/*
Used by dbsetinterrupt -
This gets called periodically while waiting on a read from the server
Right now, we only care about cases where a read from the server is
taking longer than the specified timeout and dbcancel is not working.
In these cases we decide that we actually want to handle the interrupt
*/
static int check_interrupt(void *ptr)
{
  GET_CLIENT_USERDATA((DBPROCESS *)ptr);
  return userdata->timing_out;
}

/*
Used by dbsetinterrupt -
This gets called if check_interrupt returns TRUE.
Right now, this is only used in cases where a read from the server is
taking longer than the specified timeout and dbcancel is not working.
Return INT_CANCEL to abort the current command batch.
*/
static int handle_interrupt(void *ptr)
{
  GET_CLIENT_USERDATA((DBPROCESS *)ptr);

  if (userdata->timing_out) {
    return INT_CANCEL;
  }

  return INT_CONTINUE;
}

static void rb_tinytds_client_reset_userdata(tinytds_client_userdata *userdata)
{
  userdata->timing_out = 0;
  userdata->dbsql_sent = 0;
  userdata->dbsqlok_sent = 0;
  userdata->dbcancel_sent = 0;
  userdata->nonblocking = 0;
  // the following is mainly done for consistency since the values are reset accordingly in nogvl_setup/cleanup.
  // the nonblocking_errors array does not need to be freed here. That is done as part of nogvl_cleanup.
  userdata->nonblocking_errors_length = 0;
  userdata->nonblocking_errors_size = 0;
}

static VALUE allocate(VALUE klass)
{
  VALUE obj;
  tinytds_client_wrapper *cwrap;
  obj = TypedData_Make_Struct(klass, tinytds_client_wrapper, &tinytds_client_wrapper_type, cwrap);
  cwrap->closed = 1;
  cwrap->charset = Qnil;
  cwrap->userdata = malloc(sizeof(tinytds_client_userdata));
  cwrap->userdata->closed = 1;
  rb_tinytds_client_reset_userdata(cwrap->userdata);
  return obj;
}


// TinyTds::Client (public)

static VALUE rb_tinytds_tds_version(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return INT2FIX(dbtds(cwrap->client));
}

static VALUE rb_tinytds_close(VALUE self)
{
  GET_CLIENT_WRAPPER(self);

  if (cwrap->client && !cwrap->closed) {
    dbclose(cwrap->client);
    cwrap->client = NULL;
    cwrap->closed = 1;
    cwrap->userdata->closed = 1;
  }

  return Qtrue;
}

static VALUE rb_tinytds_dead(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return dbdead(cwrap->client) ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_closed(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return (cwrap->closed || cwrap->userdata->closed) ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_canceled(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->userdata->dbcancel_sent ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_sqlsent(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->userdata->dbsql_sent ? Qtrue : Qfalse;
}

static VALUE rb_tinytds_execute(VALUE self, VALUE sql)
{
  VALUE result;

  GET_CLIENT_WRAPPER(self);
  rb_tinytds_client_reset_userdata(cwrap->userdata);
  REQUIRE_OPEN_CLIENT(cwrap);
  dbcmd(cwrap->client, StringValueCStr(sql));

  if (dbsqlsend(cwrap->client) == FAIL) {
    rb_raise(cTinyTdsError, "failed dbsqlsend() function");
  }

  cwrap->userdata->dbsql_sent = 1;
  result = rb_tinytds_new_result_obj(cwrap);
  rb_iv_set(result, "@query_options", rb_funcall(rb_iv_get(self, "@query_options"), intern_dup, 0));
  {
    GET_RESULT_WRAPPER(result);
    rwrap->local_offset = rb_funcall(cTinyTdsClient, intern_local_offset, 0);
    rwrap->encoding = cwrap->encoding;
    return result;
  }
}

static VALUE rb_tinytds_charset(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return cwrap->charset;
}

static VALUE rb_tinytds_encoding(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return rb_enc_from_encoding(cwrap->encoding);
}

static VALUE rb_tinytds_escape(VALUE self, VALUE string)
{
  VALUE new_string;
  GET_CLIENT_WRAPPER(self);

  Check_Type(string, T_STRING);
  new_string = rb_funcall(string, intern_gsub, 2, opt_escape_regex, opt_escape_dblquote);
  rb_enc_associate(new_string, cwrap->encoding);
  return new_string;
}

/* Duplicated in result.c */
static VALUE rb_tinytds_return_code(VALUE self)
{
  GET_CLIENT_WRAPPER(self);

  if (cwrap->client && dbhasretstat(cwrap->client)) {
    return LONG2NUM((long)dbretstatus(cwrap->client));
  } else {
    return Qnil;
  }
}

static VALUE rb_tinytds_identity_sql(VALUE self)
{
  GET_CLIENT_WRAPPER(self);
  return rb_str_new2(cwrap->identity_insert_sql);
}



// TinyTds::Client (protected)

static VALUE rb_tinytds_connect(VALUE self, VALUE opts)
{
  /* Parsing options hash to local vars. */
  VALUE user, pass, dataserver, database, app, version, ltimeout, timeout, charset, azure, contained, use_utf16;
  GET_CLIENT_WRAPPER(self);

  user = rb_hash_aref(opts, sym_username);
  pass = rb_hash_aref(opts, sym_password);
  dataserver = rb_hash_aref(opts, sym_dataserver);
  database = rb_hash_aref(opts, sym_database);
  app = rb_hash_aref(opts, sym_appname);
  version = rb_hash_aref(opts, sym_tds_version);
  ltimeout = rb_hash_aref(opts, sym_login_timeout);
  timeout = rb_hash_aref(opts, sym_timeout);
  charset = rb_hash_aref(opts, sym_encoding);
  azure = rb_hash_aref(opts, sym_azure);
  contained = rb_hash_aref(opts, sym_contained);
  use_utf16 = rb_hash_aref(opts, sym_use_utf16);
  cwrap->userdata->message_handler = rb_hash_aref(opts, sym_message_handler);

  /* Dealing with options. */
  if (dbinit() == FAIL) {
    rb_raise(cTinyTdsError, "failed dbinit() function");
    return self;
  }

  dberrhandle(tinytds_err_handler);
  dbmsghandle(tinytds_msg_handler);
  cwrap->login = dblogin();

  if (!NIL_P(version)) {
    dbsetlversion(cwrap->login, NUM2INT(version));
  }

  if (!NIL_P(user)) {
    dbsetluser(cwrap->login, StringValueCStr(user));
  }

  if (!NIL_P(pass)) {
    dbsetlpwd(cwrap->login, StringValueCStr(pass));
  }

  if (!NIL_P(app)) {
    dbsetlapp(cwrap->login, StringValueCStr(app));
  }

  if (!NIL_P(ltimeout)) {
    dbsetlogintime(NUM2INT(ltimeout));
  }

  if (!NIL_P(charset)) {
    DBSETLCHARSET(cwrap->login, StringValueCStr(charset));
  }

  if (!NIL_P(database)) {
    if (azure == Qtrue || contained == Qtrue) {
      #ifdef DBSETLDBNAME
      DBSETLDBNAME(cwrap->login, StringValueCStr(database));
      #else

      if (azure == Qtrue) {
        rb_warn("TinyTds: :azure option is not supported in this version of FreeTDS.\n");
      }

      if (contained == Qtrue) {
        rb_warn("TinyTds: :contained option is not supported in this version of FreeTDS.\n");
      }

      #endif
    }
  }

  if (use_utf16 == Qtrue)  {
    DBSETLUTF16(cwrap->login, 1);
  }

  if (use_utf16 == Qfalse) {
    DBSETLUTF16(cwrap->login, 0);
  }

  cwrap->client = dbopen(cwrap->login, StringValueCStr(dataserver));

  if (cwrap->client) {
    if (dbtds(cwrap->client) < 11) {
      rb_raise(cTinyTdsError, "connecting with a TDS version older than 7.3!");
    }

    VALUE transposed_encoding, timeout_string;

    cwrap->closed = 0;
    cwrap->charset = charset;

    if (!NIL_P(version)) {
      dbsetversion(NUM2INT(version));
    }

    if (!NIL_P(timeout)) {
      timeout_string = rb_sprintf("%"PRIsVALUE"", timeout);

      if (dbsetopt(cwrap->client, DBSETTIME, StringValueCStr(timeout_string), 0) == FAIL) {
        dbsettime(NUM2INT(timeout));
      }
    }

    dbsetuserdata(cwrap->client, (BYTE*)cwrap->userdata);
    dbsetinterrupt(cwrap->client, check_interrupt, handle_interrupt);
    cwrap->userdata->closed = 0;

    if (!NIL_P(database) && (azure != Qtrue)) {
      dbuse(cwrap->client, StringValueCStr(database));
    }

    transposed_encoding = rb_funcall(cTinyTdsClient, intern_transpose_iconv_encoding, 1, charset);
    cwrap->encoding = rb_enc_find(StringValueCStr(transposed_encoding));
    cwrap->identity_insert_sql = "SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident";
  }

  return self;
}


// Lib Init

void init_tinytds_client()
{
  cTinyTdsClient = rb_define_class_under(mTinyTds, "Client", rb_cObject);
  rb_define_alloc_func(cTinyTdsClient, allocate);
  /* Define TinyTds::Client Public Methods */
  rb_define_method(cTinyTdsClient, "tds_version", rb_tinytds_tds_version, 0);
  rb_define_method(cTinyTdsClient, "close", rb_tinytds_close, 0);
  rb_define_method(cTinyTdsClient, "closed?", rb_tinytds_closed, 0);
  rb_define_method(cTinyTdsClient, "canceled?", rb_tinytds_canceled, 0);
  rb_define_method(cTinyTdsClient, "dead?", rb_tinytds_dead, 0);
  rb_define_method(cTinyTdsClient, "sqlsent?", rb_tinytds_sqlsent, 0);
  rb_define_method(cTinyTdsClient, "execute", rb_tinytds_execute, 1);
  rb_define_method(cTinyTdsClient, "charset", rb_tinytds_charset, 0);
  rb_define_method(cTinyTdsClient, "encoding", rb_tinytds_encoding, 0);
  rb_define_method(cTinyTdsClient, "escape", rb_tinytds_escape, 1);
  rb_define_method(cTinyTdsClient, "return_code", rb_tinytds_return_code, 0);
  rb_define_method(cTinyTdsClient, "identity_sql", rb_tinytds_identity_sql, 0);
  /* Define TinyTds::Client Protected Methods */
  rb_define_protected_method(cTinyTdsClient, "connect", rb_tinytds_connect, 1);
  /* Symbols For Connect */
  sym_username = ID2SYM(rb_intern("username"));
  sym_password = ID2SYM(rb_intern("password"));
  sym_dataserver = ID2SYM(rb_intern("dataserver"));
  sym_database = ID2SYM(rb_intern("database"));
  sym_appname = ID2SYM(rb_intern("appname"));
  sym_tds_version = ID2SYM(rb_intern("tds_version"));
  sym_login_timeout = ID2SYM(rb_intern("login_timeout"));
  sym_timeout = ID2SYM(rb_intern("timeout"));
  sym_encoding = ID2SYM(rb_intern("encoding"));
  sym_azure = ID2SYM(rb_intern("azure"));
  sym_contained = ID2SYM(rb_intern("contained"));
  sym_use_utf16 = ID2SYM(rb_intern("use_utf16"));
  sym_message_handler = ID2SYM(rb_intern("message_handler"));
  /* Intern TinyTds::Error Accessors */
  intern_source_eql = rb_intern("source=");
  intern_severity_eql = rb_intern("severity=");
  intern_db_error_number_eql = rb_intern("db_error_number=");
  intern_os_error_number_eql = rb_intern("os_error_number=");
  /* Intern Misc */
  intern_new = rb_intern("new");
  intern_dup = rb_intern("dup");
  intern_transpose_iconv_encoding = rb_intern("transpose_iconv_encoding");
  intern_local_offset = rb_intern("local_offset");
  intern_gsub = rb_intern("gsub");
  intern_call = rb_intern("call");
  /* Escape Regexp Global */
  opt_escape_regex = rb_funcall(rb_cRegexp, intern_new, 1, rb_str_new2("\\\'"));
  opt_escape_dblquote = rb_str_new2("''");
  rb_global_variable(&opt_escape_regex);
  rb_global_variable(&opt_escape_dblquote);
}
