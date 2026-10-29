/*
** What Standard.SqlCipher binds: SQLite's declarations -- SQLCipher's
** header is SQLite's with its own additions, and its library exports the
** same functions -- and sqlite3_key, the one addition it uses.
**
** The SQLite part is the copy Standard.Sqlite's binding reads, included
** rather than copied a second time, so that the two cannot drift apart.
** sqlite3_key is copied word for word from /usr/include/sqlcipher/sqlite3.h
** of SQLCipher 4.6.1 (Debian libsqlcipher-dev 4.6.1-2), lines 6415-6418,
** where it stands under #ifdef SQLITE_HAS_CODEC (line 6407).  SQLCipher is
** Copyright Zetetic LLC and licensed under the BSD licence; this is its
** declaration, quoted for the binding generator.
**
** scripts/sqlcipher/check-header.sh compiles this file together with a real
** SQLCipher sqlite3.h, SQLITE_HAS_CODEC defined, and C accepts a declaration
** twice only when both say the same.
*/
#include "sqlite3.h"

/* sqlcipher/sqlite3.h lines 6415-6418 */
SQLITE_API int sqlite3_key(
  sqlite3 *db,                   /* Database to be rekeyed */
  const void *pKey, int nKey     /* The key */
);
