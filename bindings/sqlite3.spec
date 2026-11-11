# The C functions Standard.Sqlite calls, read from the
# copy of sqlite3.h in fixtures/ (scripts/sqlite/check-header.sh holds that
# copy against a real header).  Nothing outside Standard.Sqlite should
# import the generated module: it is C, one call at a time.
module     Bindings.C.Sqlite3
header     fixtures/sqlite3.h
output     generated/Sqlite3
library    sqlite3
# SQLITE_API stands before every declaration and is empty; the preprocessor
# takes it off.
preprocess yes
opaque     sqlite3
opaque     sqlite3_stmt
opaque     sqlite3_backup
ctype      sqlite3_int64 Int64
# The one callback is the destructor of sqlite3_bind_text and
# sqlite3_bind_blob, and Standard.Sqlite only ever passes SQLITE_TRANSIENT.
callbacks  address
flags      OpenFlags Nat32 SQLITE_OPEN_
flags      PrepareFlags Nat32 SQLITE_PREPARE_
constant   SQLITE_OK Int32
constant   SQLITE_BUSY Int32
constant   SQLITE_LOCKED Int32
constant   SQLITE_TOOBIG Int32
constant   SQLITE_ROW Int32
constant   SQLITE_DONE Int32
constant   SQLITE_NULL Int32
function   sqlite3_open_v2
function   sqlite3_close_v2
function   sqlite3_extended_errcode
function   sqlite3_errmsg
function   sqlite3_errstr
function   sqlite3_libversion
function   sqlite3_sleep
function   sqlite3_busy_timeout
function   sqlite3_prepare_v3
function   sqlite3_step
function   sqlite3_reset
function   sqlite3_clear_bindings
function   sqlite3_finalize
function   sqlite3_bind_int64
function   sqlite3_bind_double
function   sqlite3_bind_text
function   sqlite3_bind_blob
function   sqlite3_bind_null
function   sqlite3_column_type
function   sqlite3_column_int64
function   sqlite3_column_double
function   sqlite3_column_text
function   sqlite3_column_blob
function   sqlite3_column_bytes
function   sqlite3_changes64
function   sqlite3_get_autocommit
# A replicated database: statements whose text comes from the log are
# checked for what they do and take, and the whole database is copied
# with the online backup for a snapshot.
function   sqlite3_stmt_readonly
function   sqlite3_bind_parameter_count
function   sqlite3_column_count
function   sqlite3_backup_init
function   sqlite3_backup_step
function   sqlite3_backup_finish
