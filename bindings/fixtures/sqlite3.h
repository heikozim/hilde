/*
** The part of sqlite3.h that Standard.Sqlite binds.
**
** Every declaration and #define below is copied word for word from
** /usr/include/sqlite3.h of SQLite 3.46.1 (Debian libsqlite3-dev
** 3.46.1-7+deb13u2), in the header's own order, with the header's own line
** number in the comment above it.  SQLite is in the public domain; its
** header says so at the top.
**
** Why a copy and not the header: the checks of this repository read no
** file of the machine they run on, and the container image they run in has
** no sqlite3.h at all.  Why it is still the header's text:
** scripts/sqlite/check-header.sh compiles this file together with a real
** sqlite3.h, and C accepts a declaration twice only when both say the same
** -- so a line that drifted from the header, or a header that changed,
** stops that script.
*/
#ifndef SQLITE_API
/* line 75 */
# define SQLITE_API
#endif

/* line 272 */
typedef struct sqlite3 sqlite3;

/* line 301 */
  typedef long long int sqlite_int64;
/* line 304 */
typedef sqlite_int64 sqlite3_int64;

/* line 354 */
SQLITE_API int sqlite3_close_v2(sqlite3*);

/* lines 446-477 */
#define SQLITE_OK           0   /* Successful result */
#define SQLITE_BUSY         5   /* The database file is locked */
#define SQLITE_LOCKED       6   /* A table in the database is locked */
#define SQLITE_TOOBIG      18   /* A string or a blob over the size limit */
#define SQLITE_ROW         100  /* sqlite3_step() has another row ready */
#define SQLITE_DONE        101  /* sqlite3_step() has finished executing */

/* lines 595-616 */
#define SQLITE_OPEN_READONLY         0x00000001  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_READWRITE        0x00000002  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_CREATE           0x00000004  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_NOMUTEX          0x00008000  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_EXRESCODE        0x02000000  /* Extended result codes */

/* line 2705 */
SQLITE_API sqlite3_int64 sqlite3_changes64(sqlite3*);

/* line 2909 */
SQLITE_API int sqlite3_busy_timeout(sqlite3*, int ms);

/* line 3794 */
SQLITE_API int sqlite3_open_v2(
  const char *filename,   /* Database filename (UTF-8) */
  sqlite3 **ppDb,         /* OUT: SQLite db handle */
  int flags,              /* Flags */
  const char *zVfs        /* Name of VFS module to use */
);

/* lines 4040-4043 */
SQLITE_API int sqlite3_extended_errcode(sqlite3 *db);
SQLITE_API const char *sqlite3_errmsg(sqlite3*);
SQLITE_API const char *sqlite3_errstr(int);

/* line 186 */
SQLITE_API const char *sqlite3_libversion(void);

/* line 6468 */
SQLITE_API int sqlite3_sleep(int);

/* line 4070 */
typedef struct sqlite3_stmt sqlite3_stmt;

/* line 4218 */
#define SQLITE_PREPARE_PERSISTENT              0x01

/* line 4336 */
SQLITE_API int sqlite3_prepare_v3(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  unsigned int prepFlags, /* Zero or more SQLITE_PREPARE_ flags */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
);

/* line 4461 */
SQLITE_API int sqlite3_stmt_readonly(sqlite3_stmt *pStmt);

/* lines 4729-4736 */
SQLITE_API int sqlite3_bind_blob(sqlite3_stmt*, int, const void*, int n, void(*)(void*));
SQLITE_API int sqlite3_bind_double(sqlite3_stmt*, int, double);
SQLITE_API int sqlite3_bind_int64(sqlite3_stmt*, int, sqlite3_int64);
SQLITE_API int sqlite3_bind_null(sqlite3_stmt*, int);
SQLITE_API int sqlite3_bind_text(sqlite3_stmt*,int,const char*,int,void(*)(void*));

/* line 4764 */
SQLITE_API int sqlite3_bind_parameter_count(sqlite3_stmt*);

/* line 4820 */
SQLITE_API int sqlite3_clear_bindings(sqlite3_stmt*);

/* line 4836 */
SQLITE_API int sqlite3_column_count(sqlite3_stmt *pStmt);

/* line 5032 */
SQLITE_API int sqlite3_step(sqlite3_stmt*);

/* line 5079 */
#define SQLITE_NULL     5

/* lines 5300-5309 */
SQLITE_API const void *sqlite3_column_blob(sqlite3_stmt*, int iCol);
SQLITE_API double sqlite3_column_double(sqlite3_stmt*, int iCol);
SQLITE_API sqlite3_int64 sqlite3_column_int64(sqlite3_stmt*, int iCol);
SQLITE_API const unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol);
SQLITE_API int sqlite3_column_bytes(sqlite3_stmt*, int iCol);
SQLITE_API int sqlite3_column_type(sqlite3_stmt*, int iCol);

/* line 5337 */
SQLITE_API int sqlite3_finalize(sqlite3_stmt *pStmt);

/* line 5376 */
SQLITE_API int sqlite3_reset(sqlite3_stmt *pStmt);

/* line 6622 */
SQLITE_API int sqlite3_get_autocommit(sqlite3*);

/* line 9169 */
typedef struct sqlite3_backup sqlite3_backup;

/* lines 9357-9364 */
SQLITE_API sqlite3_backup *sqlite3_backup_init(
  sqlite3 *pDest,                        /* Destination database handle */
  const char *zDestName,                 /* Destination database name */
  sqlite3 *pSource,                      /* Source database handle */
  const char *zSourceName                /* Source database name */
);
SQLITE_API int sqlite3_backup_step(sqlite3_backup *p, int nPage);
SQLITE_API int sqlite3_backup_finish(sqlite3_backup *p);
