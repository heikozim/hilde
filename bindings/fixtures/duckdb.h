/*
** The part of duckdb.h that Standard.DuckDB binds.
**
** Every declaration below is copied word for word from duckdb.h of the
** DuckDB 1.5.6 release build (libduckdb-linux-arm64.zip and
** libduckdb-linux-amd64.zip carry the same header), with the line number in
** the comment above it.  DuckDB is Copyright the DuckDB Foundation and
** licensed under the MIT License; these are its declarations, quoted for
** the binding generator.
**
** scripts/duckdb/check-header.sh compiles this file together with the real
** header, and C accepts a declaration or a typedef twice only when both say
** the same.
**
** Lines that are not the header's own text: DUCKDB_C_API is a visibility
** attribute there and empty here, since the attribute changes no call.  The
** handle types are typedefs of a pointer to a struct whose body C does not
** take twice, so they are written as the typedef of the same pointer
** without the body, which C takes as the same type.  The three enumerations
** are written as the typedef of the enumeration by its tag, without the
** values: ../duckdb.spec names them as int, and every value the binding
** uses comes from the system header through a system-constant line.
** duckdb_result, duckdb_timestamp and duckdb_string_t are passed by value
** in a few functions; Bindings.DuckDB calls those in C itself, so they are
** not here.
*/
#ifndef DUCKDB_C_API
/* duckdb.h line 35 */
#define DUCKDB_C_API
#endif

/* duckdb.h line 141, the enumeration by its tag */
typedef enum duckdb_state duckdb_state;

/* duckdb.h line 146 */
typedef uint64_t idx_t;

/* duckdb.h line 359, the enumeration by its tag */
typedef enum duckdb_error_type duckdb_error_type;

/* duckdb.h line 160, the enumeration by its tag */
typedef enum DUCKDB_TYPE DUCKDB_TYPE;

/* duckdb.h line 492 */
typedef DUCKDB_TYPE duckdb_type;

/* duckdb.h line 556 */
typedef struct duckdb_result duckdb_result;

/* duckdb.h line 867, the pointer without the body */
typedef struct _duckdb_database *duckdb_database;

/* duckdb.h line 877, the pointer without the body */
typedef struct _duckdb_connection *duckdb_connection;

/* duckdb.h line 898, the pointer without the body */
typedef struct _duckdb_prepared_statement *duckdb_prepared_statement;

/* duckdb.h line 949, the pointer without the body */
typedef struct _duckdb_config *duckdb_config;

/* duckdb.h line 990, the pointer without the body */
typedef struct _duckdb_data_chunk *duckdb_data_chunk;

/* duckdb.h line 1042, the pointer without the body */
typedef struct _duckdb_vector *duckdb_vector;

/* duckdb.h line 3686 */
DUCKDB_C_API duckdb_state duckdb_connect(duckdb_database database, duckdb_connection *out_connection);

/* duckdb.h line 3723 */
DUCKDB_C_API void duckdb_disconnect(duckdb_connection *connection);

/* duckdb.h line 4393 */
DUCKDB_C_API void duckdb_destroy_data_chunk(duckdb_data_chunk *chunk);

/* duckdb.h line 4437 */
DUCKDB_C_API duckdb_vector duckdb_data_chunk_get_vector(duckdb_data_chunk chunk, idx_t col_idx);

/* duckdb.h line 4450 */
DUCKDB_C_API idx_t duckdb_data_chunk_get_size(duckdb_data_chunk chunk);

/* duckdb.h lines 4563-4564 */
DUCKDB_C_API duckdb_state duckdb_open_ext(const char *path, duckdb_database *out_database, duckdb_config config,
                                          char **out_error);

/* duckdb.h line 4579 */
DUCKDB_C_API void duckdb_close(duckdb_database *database);

/* duckdb.h line 4592 */
DUCKDB_C_API const char *duckdb_library_version(void);

/* duckdb.h line 4611 */
DUCKDB_C_API duckdb_state duckdb_create_config(duckdb_config *out_config);

/* duckdb.h line 4663 */
DUCKDB_C_API duckdb_state duckdb_set_config(duckdb_config config, const char *name, const char *option);

/* duckdb.h line 4676 */
DUCKDB_C_API void duckdb_destroy_config(duckdb_config *config);

/* duckdb.h lines 5754-5755 */
DUCKDB_C_API duckdb_state duckdb_prepare(duckdb_connection connection, const char *query,
                                         duckdb_prepared_statement *out_prepared_statement);

/* duckdb.h line 5766 */
DUCKDB_C_API void duckdb_destroy_prepare(duckdb_prepared_statement *prepared_statement);

/* duckdb.h line 5781 */
DUCKDB_C_API const char *duckdb_prepare_error(duckdb_prepared_statement prepared_statement);

/* duckdb.h line 5796 */
DUCKDB_C_API idx_t duckdb_nparams(duckdb_prepared_statement prepared_statement);

/* duckdb.h line 6044 */
DUCKDB_C_API duckdb_state duckdb_bind_int64(duckdb_prepared_statement prepared_statement, idx_t param_idx, int64_t val);

/* duckdb.h line 6181 */
DUCKDB_C_API duckdb_state duckdb_bind_double(duckdb_prepared_statement prepared_statement, idx_t param_idx, double val);

/* duckdb.h lines 6294-6295 */
DUCKDB_C_API duckdb_state duckdb_bind_varchar_length(duckdb_prepared_statement prepared_statement, idx_t param_idx,
                                                     const char *val, idx_t length);

/* duckdb.h lines 6311-6312 */
DUCKDB_C_API duckdb_state duckdb_bind_blob(duckdb_prepared_statement prepared_statement, idx_t param_idx,
                                           const void *data, idx_t length);

/* duckdb.h line 6326 */
DUCKDB_C_API duckdb_state duckdb_bind_null(duckdb_prepared_statement prepared_statement, idx_t param_idx);

/* duckdb.h lines 6344-6345 */
DUCKDB_C_API duckdb_state duckdb_execute_prepared(duckdb_prepared_statement prepared_statement,
                                                  duckdb_result *out_result);

/* duckdb.h line 6496 */
DUCKDB_C_API duckdb_state duckdb_query(duckdb_connection connection, const char *query, duckdb_result *out_result);

/* duckdb.h line 6507 */
DUCKDB_C_API void duckdb_destroy_result(duckdb_result *result);

/* duckdb.h line 6539 */
DUCKDB_C_API duckdb_type duckdb_column_type(duckdb_result *result, idx_t col);

/* duckdb.h line 6598 */
DUCKDB_C_API idx_t duckdb_column_count(duckdb_result *result);

/* duckdb.h line 6612 */
DUCKDB_C_API idx_t duckdb_rows_changed(duckdb_result *result);

/* duckdb.h line 6627 */
DUCKDB_C_API const char *duckdb_result_error(duckdb_result *result);

/* duckdb.h line 6641 */
DUCKDB_C_API duckdb_error_type duckdb_result_error_type(duckdb_result *result);

/* duckdb.h line 6769 */
DUCKDB_C_API void duckdb_free(void *ptr);

/* duckdb.h line 9938 */
DUCKDB_C_API void *duckdb_vector_get_data(duckdb_vector vector);

/* duckdb.h line 9964 */
DUCKDB_C_API uint64_t *duckdb_vector_get_validity(duckdb_vector vector);
