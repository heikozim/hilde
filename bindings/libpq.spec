# The libpq functions Standard.Postgres calls, read from the copy of
# libpq-fe.h in fixtures/ (scripts/postgres/check-header.sh holds that copy
# against the real header).  Only Bindings.Postgres should import the
# generated module.
module     Bindings.C.Libpq
header     fixtures/libpq.h
output     generated/Libpq
# The file is libpq.so; pkg-config knows it as libpq, which the compiler
# asks for when it does not know pq, and which names the include
# directory /usr/include/postgresql on Debian.
library    pq
opaque     PGconn
opaque     PGresult
ctype      Oid Nat32
# The three enumerations are int in C; their values come from the system
# header, never from the copy.
ctype      ConnStatusType Int32
ctype      ExecStatusType Int32
ctype      PGTransactionStatusType Int32
system-header   libpq-fe.h
system-constant CONNECTION_OK Int32
system-constant PGRES_COMMAND_OK Int32
system-constant PGRES_TUPLES_OK Int32
system-constant PQTRANS_IDLE Int32
system-constant PQTRANS_INERROR Int32
system-constant PG_DIAG_SQLSTATE Int32
system-constant PG_DIAG_MESSAGE_PRIMARY Int32
function   PQconnectdbParams
function   PQfinish
function   PQstatus
function   PQtransactionStatus
function   PQerrorMessage
function   PQsslInUse
function   PQexec
function   PQexecParams
function   PQresultStatus
function   PQresultErrorField
function   PQntuples
function   PQnfields
function   PQftype
function   PQcmdTuples
function   PQgetvalue
function   PQgetlength
function   PQgetisnull
function   PQclear
function   PQlibVersion
