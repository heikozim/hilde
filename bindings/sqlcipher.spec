# The C functions Standard.SqlCipher calls -- SQLite's,
# which SQLCipher exports under the same names, and sqlite3_key -- read from
# fixtures/sqlcipher.h (scripts/sqlcipher/check-header.sh holds it against a
# real SQLCipher header).  Only Standard.SqlCipher should import it.
module     Bindings.C.SqlCipher
header     fixtures/sqlcipher.h
output     generated/SqlCipher
library    sqlcipher
# SQLITE_API stands before every declaration and is empty; the preprocessor
# takes it off.
preprocess yes
opaque     sqlite3
opaque     sqlite3_stmt
ctype      sqlite3_int64 Int64
# The one callback is the destructor of sqlite3_bind_text and
# sqlite3_bind_blob, and Standard.SqlCipher only ever passes SQLITE_TRANSIENT.
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
function   sqlite3_key
