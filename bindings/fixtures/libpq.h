/*
** The part of libpq-fe.h and postgres_ext.h that Standard.Postgres binds.
**
** Every declaration below is copied word for word from the headers of
** PostgreSQL 17.11 (Debian libpq-dev 17.11-0+deb13u1), with the header and
** line number in the comment above it.  PostgreSQL is Copyright the
** PostgreSQL Global Development Group and licensed under the PostgreSQL
** License; these are its declarations, quoted for the binding generator.
**
** Why a copy: the checks of this repository read no file of the machine
** they run on.  scripts/postgres/check-header.sh compiles this file
** together with the real headers, and C accepts a declaration or a typedef
** twice only when both say the same.
**
** The three enumerations ConnStatusType, ExecStatusType and
** PGTransactionStatusType are not copied: C does not take an enumeration
** twice.  ../libpq.spec names them as int, the type C gives an enumeration
** whose values fit one, and takes each value from the system header
** through a system-constant line.
*/

/* postgres_ext.h line 31 */
typedef unsigned int Oid;

/* libpq-fe.h line 186 */
typedef struct pg_conn PGconn;

/* libpq-fe.h line 198 */
typedef struct pg_result PGresult;

/* libpq-fe.h lines 316-317 */
extern PGconn *PQconnectdbParams(const char *const *keywords,
								 const char *const *values, int expand_dbname);

/* libpq-fe.h line 327 */
extern void PQfinish(PGconn *conn);

/* libpq-fe.h lines 391-392 */
extern ConnStatusType PQstatus(const PGconn *conn);
extern PGTransactionStatusType PQtransactionStatus(const PGconn *conn);

/* libpq-fe.h line 397 */
extern char *PQerrorMessage(const PGconn *conn);

/* libpq-fe.h line 408 */
extern int	PQsslInUse(PGconn *conn);

/* libpq-fe.h lines 469-477 */
extern PGresult *PQexec(PGconn *conn, const char *query);
extern PGresult *PQexecParams(PGconn *conn,
							  const char *command,
							  int nParams,
							  const Oid *paramTypes,
							  const char *const *paramValues,
							  const int *paramLengths,
							  const int *paramFormats,
							  int resultFormat);

/* libpq-fe.h line 565 */
extern ExecStatusType PQresultStatus(const PGresult *res);

/* libpq-fe.h lines 571-573 */
extern char *PQresultErrorField(const PGresult *res, int fieldcode);
extern int	PQntuples(const PGresult *res);
extern int	PQnfields(const PGresult *res);

/* libpq-fe.h line 580 */
extern Oid	PQftype(const PGresult *res, int field_num);

/* libpq-fe.h lines 586-589 */
extern char *PQcmdTuples(PGresult *res);
extern char *PQgetvalue(const PGresult *res, int tup_num, int field_num);
extern int	PQgetlength(const PGresult *res, int tup_num, int field_num);
extern int	PQgetisnull(const PGresult *res, int tup_num, int field_num);

/* libpq-fe.h line 606 */
extern void PQclear(PGresult *res);

/* libpq-fe.h line 692 */
extern int	PQlibVersion(void);
