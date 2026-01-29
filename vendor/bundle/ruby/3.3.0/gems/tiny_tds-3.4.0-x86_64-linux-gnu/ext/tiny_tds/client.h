
#ifndef TINYTDS_CLIENT_H
#define TINYTDS_CLIENT_H

void init_tinytds_client();

#define ERROR_MSG_SIZE 1024
#define ERRORS_STACK_INIT_SIZE 2

typedef struct {
  int is_message;
  int cancel;
  char error[ERROR_MSG_SIZE];
  char source[ERROR_MSG_SIZE];
  int severity;
  int dberr;
  int oserr;
} tinytds_errordata;

typedef struct {
  short int closed;
  short int timing_out;
  short int dbsql_sent;
  short int dbsqlok_sent;
  RETCODE dbsqlok_retcode;
  short int dbcancel_sent;
  short int nonblocking;
  short int nonblocking_errors_length;
  short int nonblocking_errors_size;
  tinytds_errordata *nonblocking_errors;
  VALUE message_handler;
} tinytds_client_userdata;

typedef struct {
  LOGINREC *login;
  RETCODE return_code;
  DBPROCESS *client;
  short int closed;
  VALUE charset;
  tinytds_client_userdata *userdata;
  const char *identity_insert_sql;
  rb_encoding *encoding;
} tinytds_client_wrapper;

VALUE rb_tinytds_raise_error(DBPROCESS *dbproc, tinytds_errordata error);

// Lib Macros

#define GET_CLIENT_USERDATA(dbproc) \
  tinytds_client_userdata *userdata = (tinytds_client_userdata *)dbgetuserdata(dbproc);


#endif
