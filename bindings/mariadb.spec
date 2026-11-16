# The libmariadb functions Standard.MariaDB calls, read from the copy of
# mysql.h and mariadb_stmt.h in fixtures/ (scripts/mariadb/check-header.sh
# holds that copy against the real headers).  Only Bindings.MariaDB should
# import the generated module.
module     Bindings.C.Mariadb
header     fixtures/mariadb.h
output     generated/Mariadb
# The file is libmariadb.so; pkg-config knows it as libmariadb, which names
# the include directory /usr/include/mariadb on Debian.
library    mariadb
# STDCALL stands before every declaration and is empty; the preprocessor
# takes it off.
preprocess yes
opaque     MYSQL
opaque     MYSQL_STMT
opaque     MYSQL_RES
opaque     MYSQL_BIND
# my_bool is a char holding 0 or 1, which reads the same whether the
# platform's char has a sign or not.
ctype      my_bool Nat8
system-header   mysql.h
system-constant MYSQL_NO_DATA Int32
system-constant MYSQL_DATA_TRUNCATED Int32
system-constant CLIENT_MULTI_STATEMENTS Nat64
function   mysql_next_result
function   mysql_store_result
function   mysql_free_result
function   mysql_errno
function   mysql_error
function   mysql_init
function   mysql_get_ssl_cipher
function   mysql_real_connect
function   mysql_close
function   mysql_real_query
function   mysql_sqlstate
function   mysql_stmt_init
function   mysql_stmt_prepare
function   mysql_stmt_execute
function   mysql_stmt_fetch
function   mysql_stmt_fetch_column
function   mysql_stmt_store_result
function   mysql_stmt_bind_param
function   mysql_stmt_bind_result
function   mysql_stmt_close
function   mysql_stmt_free_result
function   mysql_stmt_errno
function   mysql_stmt_sqlstate
function   mysql_stmt_affected_rows
function   mysql_stmt_field_count
# The version of the client library, for version --full.
function   mysql_get_client_info
