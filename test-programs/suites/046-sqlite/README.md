# 046-sqlite

`Standard.Sqlite`, `@query`, `@execute` and `@migrations`.  Every test has
its schema beside it, in `migrations/`, because that is where the compiler
reads it.

The requirements, each with a test that it holds and a test that the
wrong use does not compile:

1. SQL checked at compile time: 001 runs; 007-013 and 017-021 must not
   compile, each with its message.
2. Linear transactions: 002 runs; 003 must not compile.
3. Text and blobs borrowed from the row: 001 prints them; 004 (a span kept
   past its row), 005 (stepping while a row is lent) and 006 (ending the
   statement while a row is lent) must not compile.
4. Prepared statements per connection, one writer and several readers:
   015 prints how many statements were prepared, 016 runs three reader
   tasks beside a writer on a WAL file; 014 (a write through a reading
   connection) and 022 (a connection lent to a task) must not compile.
   023 and 024 must abort: a statement or a transaction ended on another
   connection than it was started on -- two connections of one type the
   compiler cannot tell apart.
5. A text that holds no statement: 028 runs an empty text and one that is only
   a comment, each a failure with SQLITE_MISUSE (21), and a CREATE TABLE after
   them.

The oracle is the `sqlite3` shell on a host:
`sh scripts/sqlite/oracle.sh <test-dir> <out-file>` runs a test's
migrations and its `oracle.sql`.  001 has one.

016 writes `/tmp/hilde-046-016.db` with its `-wal` and `-shm` files, and
removes all three before it starts and after it ends; every other test uses
an in-memory database.

016 asserts the order of ONE thread -- the readers count, yield, and the writer writes in between -- and names HILDE_TASK_THREADS=1 in its env.txt since tasks run on several threads.
