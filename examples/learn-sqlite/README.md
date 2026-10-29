# learn-sqlite

## What it shows

Two programmes over the same table, `notes`, which the files under
`migrations` make.

- `main` uses SQLite in memory: no file is made.  It inserts three notes
  and reads them back in order.
- `cipher` uses SQLCipher, SQLite with an encrypted file.  It writes a
  note into `notes.db` in the working directory, reads it back with the
  same key, shows that the file does not start the way a plain SQLite
  file does, and removes the file, together with the two files SQLite
  keeps beside a database in WAL mode, `notes.db-wal` and
  `notes.db-shm`.

Every statement is checked by the compiler against the table: a column
that does not exist is a compile error.  Values go to the database as
parameters, never into the text of a statement.

The key in `LearnSqlCipher.hiq` is an example and nothing else.  A real
programme reads its key from a place that is not its source.

SQLite and SQLCipher have the same names in C, so they are built into two
programmes and never linked into one.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-sqlite
make
./main
./cipher
```

SQLite and SQLCipher have to be installed.

## What comes out

`./main`:

```
migrations applied: 1
insert: 1 row
insert: 1 row
insert: 1 row
1 buy bread
2 call Ann
3 water the plants
```

`./cipher`:

```
migrations applied: 1
inserted: 1
1 the code of the safe
the file starts with the plain SQLite header: false
the file removed: true
```
