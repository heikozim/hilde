/*
** The part of mysql.h and mariadb_stmt.h that Standard.MariaDB binds.
**
** Every declaration below is copied word for word from the headers of
** MariaDB Connector/C 3.4.9 (Debian libmariadb-dev 1:11.8.6-0+deb13u1),
** with the header and line number in the comment above it.  MariaDB
** Connector/C is licensed under the GNU Lesser General Public License 2.1;
** these are its declarations, quoted for the binding generator.
**
** scripts/mariadb/check-header.sh compiles this file together with the real
** headers, and C accepts a declaration or a typedef twice only when both
** say the same.
**
** Four lines are not the header's own text.  MYSQL is a typedef of a struct
** whose body C does not take twice, so it is written as the typedef of the
** same struct without the body, which C takes as the same type.  STDCALL
** is empty on every platform but Windows, as mysql.h line 44 has it; the
** preprocessor takes it off.  MYSQL_RES and MYSQL_BIND are used only through
** a pointer and filled by Bindings.MariaDB in C, so their bodies are not
** copied either.
*/
#ifndef STDCALL
/* mysql.h line 44 */
#define STDCALL
#endif

/* mysql.h line 40 */
typedef char my_bool;

/* mysql.h line 355, the struct without its body */
typedef struct st_mysql MYSQL;

/* mysql.h line 392, the struct without its body */
typedef struct st_mysql_res MYSQL_RES;

/* mariadb_stmt.h line 55 */
typedef struct st_mysql_stmt MYSQL_STMT;

/* mariadb_stmt.h line 111, the struct without its body */
typedef struct st_mysql_bind MYSQL_BIND;

/* mysql.h line 558 */
int STDCALL mysql_next_result(MYSQL *mysql);

/* mysql.h line 641 */
const char * STDCALL mysql_get_client_info(void);

/* mysql.h lines 564-565 */
unsigned int STDCALL mysql_errno(MYSQL *mysql);
const char * STDCALL mysql_error(MYSQL *mysql);

/* mysql.h line 574 */
MYSQL *		STDCALL mysql_init(MYSQL *mysql);

/* mysql.h line 578 */
const char *	STDCALL mysql_get_ssl_cipher(MYSQL *mysql);

/* mysql.h lines 581-587 */
MYSQL *		STDCALL mysql_real_connect(MYSQL *mysql, const char *host,
					   const char *user,
					   const char *passwd,
					   const char *db,
					   unsigned int port,
					   const char *unix_socket,
					   unsigned long clientflag);

/* mysql.h line 588 */
void		STDCALL mysql_close(MYSQL *sock);

/* mysql.h lines 594-595 */
int		STDCALL mysql_real_query(MYSQL *mysql, const char *q,
					 unsigned long length);

/* mysql.h line 612 */
MYSQL_RES *	STDCALL mysql_store_result(MYSQL *mysql);

/* mysql.h line 618 */
void		STDCALL mysql_free_result(MYSQL_RES *result);

/* mysql.h line 634 */
const char * STDCALL mysql_sqlstate(MYSQL *mysql);

/* mariadb_stmt.h lines 233-238 */
MYSQL_STMT * STDCALL mysql_stmt_init(MYSQL *mysql);
int STDCALL mysql_stmt_prepare(MYSQL_STMT *stmt, const char *query, unsigned long length);
int STDCALL mysql_stmt_execute(MYSQL_STMT *stmt);
int STDCALL mysql_stmt_fetch(MYSQL_STMT *stmt);
int STDCALL mysql_stmt_fetch_column(MYSQL_STMT *stmt, MYSQL_BIND *bind_arg, unsigned int column, unsigned long offset);
int STDCALL mysql_stmt_store_result(MYSQL_STMT *stmt);

/* mariadb_stmt.h lines 242-244 */
my_bool STDCALL mysql_stmt_bind_param(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool STDCALL mysql_stmt_bind_result(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool STDCALL mysql_stmt_close(MYSQL_STMT * stmt);

/* mariadb_stmt.h line 246 */
my_bool STDCALL mysql_stmt_free_result(MYSQL_STMT *stmt);

/* mariadb_stmt.h line 250 */
unsigned int STDCALL mysql_stmt_errno(MYSQL_STMT * stmt);

/* mariadb_stmt.h line 252 */
const char *STDCALL mysql_stmt_sqlstate(MYSQL_STMT * stmt);

/* mariadb_stmt.h line 257 */
unsigned long long STDCALL mysql_stmt_affected_rows(MYSQL_STMT *stmt);

/* mariadb_stmt.h line 259 */
unsigned int STDCALL mysql_stmt_field_count(MYSQL_STMT *stmt);
