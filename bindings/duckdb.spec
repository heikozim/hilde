# The libduckdb functions Standard.DuckDB calls, read from the copy of
# duckdb.h in fixtures/ (scripts/duckdb/check-header.sh holds that copy
# against the real header).  Only Bindings.DuckDB should import the
# generated module.
module     Bindings.C.Duckdb
header     fixtures/duckdb.h
output     generated/Duckdb
# The file is libduckdb.so; the gate image writes duckdb.pc for it, which
# names /usr/local/include and /usr/local/lib.
library    duckdb
# DUCKDB_C_API stands before every declaration and is empty in the copy;
# the preprocessor takes it off.
preprocess yes
opaque     duckdb_result
# The handles are pointers to a struct of DuckDB's own.
ctype      duckdb_database Address[Unit]
ctype      duckdb_connection Address[Unit]
ctype      duckdb_prepared_statement Address[Unit]
ctype      duckdb_config Address[Unit]
ctype      duckdb_data_chunk Address[Unit]
ctype      duckdb_vector Address[Unit]
ctype      idx_t Nat64
# The three enumerations are int in C; their values come from the system
# header, never from the copy.
ctype      duckdb_state Int32
ctype      duckdb_type Int32
ctype      duckdb_error_type Int32
system-header   duckdb.h
system-constant DuckDBSuccess Int32
system-constant DUCKDB_TYPE_BOOLEAN Int32
system-constant DUCKDB_TYPE_TINYINT Int32
system-constant DUCKDB_TYPE_SMALLINT Int32
system-constant DUCKDB_TYPE_INTEGER Int32
system-constant DUCKDB_TYPE_BIGINT Int32
system-constant DUCKDB_TYPE_FLOAT Int32
system-constant DUCKDB_TYPE_DOUBLE Int32
system-constant DUCKDB_TYPE_TIMESTAMP Int32
system-constant DUCKDB_TYPE_TIMESTAMP_TZ Int32
system-constant DUCKDB_TYPE_VARCHAR Int32
system-constant DUCKDB_TYPE_BLOB Int32
system-constant DUCKDB_ERROR_CONSTRAINT Int32
system-constant DUCKDB_ERROR_TRANSACTION Int32
system-constant DUCKDB_ERROR_CATALOG Int32
system-constant DUCKDB_ERROR_PARSER Int32
system-constant DUCKDB_ERROR_BINDER Int32
system-constant DUCKDB_ERROR_INVALID_INPUT Int32
system-constant DUCKDB_ERROR_PERMISSION Int32
function   duckdb_open_ext
function   duckdb_close
function   duckdb_connect
function   duckdb_disconnect
function   duckdb_create_config
function   duckdb_set_config
function   duckdb_destroy_config
function   duckdb_free
function   duckdb_library_version
function   duckdb_prepare
function   duckdb_prepare_error
function   duckdb_destroy_prepare
function   duckdb_nparams
function   duckdb_bind_int64
function   duckdb_bind_double
function   duckdb_bind_varchar_length
function   duckdb_bind_blob
function   duckdb_bind_null
function   duckdb_execute_prepared
function   duckdb_query
function   duckdb_destroy_result
function   duckdb_result_error
function   duckdb_result_error_type
function   duckdb_rows_changed
function   duckdb_column_count
function   duckdb_column_type
function   duckdb_data_chunk_get_size
function   duckdb_data_chunk_get_vector
function   duckdb_destroy_data_chunk
function   duckdb_vector_get_data
function   duckdb_vector_get_validity
