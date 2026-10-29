# The unsafe modules of the standard library

A module is unsafe when its body says `pragma Unsafe_Module;`.  Only an
unsafe module may bind a C function (`pragma Foreign_Import`), paste C into
the program (`@embed`), or import `Hilde.Memory`, the built-in module of
addresses and raw memory.  A safe module can do none of these, and the
compiler checks it.

The modules a program imports are safe.  Every call into C of the standard
library is in one of the modules below, and a program cannot import them:
only a module whose name begins with `Standard.` or `Bindings.` may import
a `Bindings.` module (error H2045).  Each binding begins with a short
explanation of what it binds and which safe module is built on it.

The project's checks hold this list to the tree with `scripts/check-unsafe.py`: a
module that is unsafe and has no row here, a row whose module is missing
or safe, a binding without its explanation, and a module outside this list
that imports `Hilde.Memory` or names its raw types in its interface each
fail the check.

## The bindings

| module | files | binds | why it is unsafe | the safe module built on it |
| --- | --- | --- | --- | --- |
| `Bindings.Libcrypto` | `standard/src/Bindings/Libcrypto.hih`, `.hiq` | libcrypto (LibreSSL or OpenSSL) | scratch buffers, the EVP calls and RAND_bytes, with addresses | `Standard.Libcrypto` |
| `Bindings.MlDsa` | `standard/src/Bindings/MlDsa.hih`, `.hiq` | ML-DSA of FIPS 204 from libcrux, the C the compiler carries (`lib/mldsa.c`, `vendor/libcrux`) | the addresses of keys, message, context, randomness and the buffers the results are written into, of the fixed sizes of FIPS 204 | `Standard.MlDsa` |
| `Bindings.Argon2` | `standard/src/Bindings/Argon2.hih`, `.hiq` | libargon2, the reference implementation of Argon2 | the buffer the tag is written into, the addresses of password, salt, secret and data, and the context the library reads them from | `Standard.Password` |
| `Bindings.Bcrypt` | `standard/src/Bindings/Bcrypt.hih`, `.hiq` | the check of a bcrypt hash through the runtime: `crypt_checkpass` of OpenBSD's libc, `crypt_rn` of libxcrypt on Linux, `crypt_r` of libcrypt on FreeBSD | calls into the runtime with `@embed` | `Standard.Password` |
| `Bindings.Tls` | `standard/src/Bindings/Tls.hih`, `.hiq` | libtls, and the runtime's wait for a socket and its monotonic clock | the two handles of a client connection, the buffers of a send and a receive, and the socket's number it waits on | `Standard.Tls` |
| `Bindings.Pcre` | `standard/src/Bindings/Pcre.hih`, `.hiq` | PCRE2, and its JIT for `Standard.PcreJit` | a compiled pattern, the match slots and the JIT stack of one search | `Standard.Pcre` |
| `Bindings.Sqlite` | `standard/src/Bindings/Sqlite.hih`, `.hiq` | SQLite | the connection, its statements, the values handed in and read out, the migrations | `Standard.Sqlite` |
| `Bindings.SqlCipher` | `standard/src/Bindings/SqlCipher.hih`, `.hiq` | SQLCipher | as `Bindings.Sqlite`, with the key; written by `scripts/gen-sqlcipher.py` | `Standard.SqlCipher` |
| `Bindings.SqliteReplica` | `standard/src/Bindings/SqliteReplica.hih`, `.hiq` | SQLite | the connection, statements prepared from text known only at run time, the values bound and the columns copied out, the online backup to and from a file | `Standard.SqliteReplica` |
| `Bindings.Postgres` | `standard/src/Bindings/Postgres.hih`, `.hiq` | libpq, the client library of PostgreSQL | the connection, its results, the arrays of values, types, lengths and formats handed to `PQexecParams`, and the bytes read out of a result | `Standard.Postgres` |
| `Bindings.MariaDB` | `standard/src/Bindings/MariaDB.hih`, `.hiq` | libmariadb, MariaDB Connector/C | the connection, its prepared statements, the `MYSQL_BIND` arrays of values and columns and the C memory they point at, and the options of the connection, written in `@embed` against `mysql.h` | `Standard.MariaDB` |
| `Bindings.DuckDB` | `standard/src/Bindings/DuckDB.hih`, `.hiq` | libduckdb, DuckDB's release build | the database, its connection and configuration, prepared statements, results and data chunks, the slots of out parameters, and values passed by value in `@embed` against `duckdb.h` | `Standard.DuckDB` |
| `Bindings.Database` | `standard/src/Bindings/Database.hih`, `.hiq` | nothing outside: `abandon`, and the box `Erased` with `erase`, `unerase`, `reveal` and `revealWrite` | it ends the programme with a linear value that can no longer be ended the right way; it keeps a driver's connection, transaction or cursor in a box of bytes and casts it back to the type the driver names, which only the driver module that erased it does, Standard.Database.Sqlite, .Postgres and .MariaDB | `Standard.Database` |
| `Bindings.Time` | `standard/src/Bindings/Time.hih`, `.hiq` | the clocks of the C library, through the runtime | calls into the runtime with `@embed` | `Standard.Time` |
| `Bindings.BuildInfo` | `standard/src/Bindings/BuildInfo.hih`, `.hiq` | nothing outside: the macros and the table of values the compiler writes into a programme that compiles this module | spans made from the addresses of those C strings, with `@embed` | `Standard.BuildInfo` |
| `Bindings.Platform` | `standard/src/Bindings/Platform.hih`, `.hiq` | gethostname(3), asked once and kept; besides two functions of the runtime that answer from the macros of the C compiler | spans made from the addresses of three C strings, with `@embed` | `Standard.Platform` |
| `Bindings.Bits` | `standard/src/Bindings/Bits.hih`, `.hiq` | nothing outside the programme: a C union reads the bits of a binary64 or binary32 number, or of a two's complement integer, as an unsigned number of the same width | eight expressions with `@embed` over a union compound literal, no memory and no pointer | `Standard.Bits` |
| `Bindings.Secret` | `standard/src/Bindings/Secret.hih`, `.hiq` | the terminal of the process with its echo off (readpassphrase on the BSDs and macOS, termios on Linux) and standard input, through the runtime | a buffer of 1024 bytes from the allocator, its address handed to the runtime, wiped before it is freed | `Standard.Secret` |
| `Bindings.Account` | `standard/src/Bindings/Account.hih`, `.hiq` | the password database through getpwnam_r(3), and geteuid(2), through the runtime | a name copied into a buffer of 256 bytes on the stack of the runtime, refused when longer or holding a zero byte | `Standard.Account` |
| `Bindings.Resolve` | `standard/src/Bindings/Resolve.hih`, `.hiq` | the resolver of the C library, `getaddrinfo`, through the runtime | the buffer the runtime writes the addresses into, and calls into the runtime with `@embed` | `Standard.Resolve` |
| `Bindings.Terminal` | `standard/src/Bindings/Terminal.hih`, `.hiq` | the standard streams of the C library, a whole text written to standard error with write(2), and the terminal's echo, width and pending input, through the runtime | calls into the runtime, and the address of the text's bytes | `Standard.IO.Terminal` |
| `Bindings.SystemLog` | `standard/src/Bindings/SystemLog.hih`, `.hiq` | the system log, `openlog`, `syslog` and `closelog`, through the runtime | the addresses of the bytes of the name and the text, and calls into the runtime with `@embed` | `Standard.Log` |
| `Bindings.Signal` | `standard/src/Bindings/Signal.hih`, `.hiq` | the runtime's signal handler and its pipe, `sigaction`, `kill`, `alarm` and `getpid` | calls into the runtime with `@embed` | `Standard.Signal` |
| `Bindings.Arena` | `standard/src/Bindings/Arena.hih`, `.hiq` | the runtime's arena, memory from the kernel | the arena's handle, and references and spans made from its addresses | `Standard.Arena` |
| `Bindings.Poller` | `standard/src/Bindings/Poller.hih`, `.hiq` | the runtime's poller, epoll on Linux and kqueue on OpenBSD, FreeBSD and macOS | the poller's handle and its calls | `Standard.Poller` |
| `Bindings.Task` | `standard/src/Bindings/Task.hih`, `.hiq` | the runtime's fibers, scopes and channels, on threads of the process | a task's argument and result, and a channel's values, in raw memory | `Standard.Task` |
| `Bindings.Shared` | `standard/src/Bindings/Shared.hih`, `.hiq` | the runtime's mutexes, which park a waiting task, and its atomic operations on a word of 64 bits | the value a mutex guards in one raw cell, moved out and back through a read reference, and the word | `Standard.Shared` |
| `Bindings.File` | `standard/src/Bindings/File.hih`, `.hiq` | the file, directory, process, environment and socket calls of the C library, a TCP connection and reads and writes on a socket with a time limit among them, a file's status, owner, rename, link and sync and a temporary file, through the runtime | the addresses of the bytes of paths, buffers and network addresses, and a directory stream | `Standard.File` |
| `Bindings.Sandbox` | `standard/src/Bindings/Sandbox.hih`, `.hiq` | pledge with its execpromises, unveil and the child that measures its room on OpenBSD, no new privileges, Landlock and seccomp on Linux, the Seatbelt profile and the start under sandbox-exec on macOS, Capsicum on FreeBSD, through the runtime | the addresses of the bytes of promises, paths and permissions | `Standard.Sandbox` |
| `Bindings.Serial` | `standard/src/Bindings/Serial.hih`, `.hiq` | a count shared by the whole process, kept in C | calls into C with `@embed` | `Standard.Graph` |
| `Bindings.Resource` | `standard/src/Bindings/Resource.hih`, `.hiq` | getrlimit, setrlimit and getrusage, and the clock that counts from the system's start, through the runtime | a buffer of slots the runtime writes the numbers into, and calls into the runtime with `@embed` | `Standard.Resource` |
| `Bindings.Watch` | `standard/src/Bindings/Watch.hih`, `.hiq` | inotify on Linux and kqueue on OpenBSD and FreeBSD, through the runtime | the address of a path's bytes, and calls into the runtime with `@embed` | `Standard.Watch` |
| `Bindings.Context` | `standard/src/Bindings/Context.hih`, `.hiq` | a pipe of the runtime, and the runtime's chain of reading ends with a count of references per level, which it waits on with `poll` | the address of a level of the chain, and calls into C with `@embed` | `Standard.Context` |
| `Bindings.X509` | `standard/src/Bindings/X509.hih`, `.hiq` | libcrypto's keys, X.509 certificates and requests, PEM and DER, and the verification of a chain, called in `@embed` against the system's headers, the functions `Bindings.C.Libcrypto` imports called through it, and the two functions of ML-DSA found with `dlsym` | memory BIOs, the slots of out parameters, the buffers of signatures and DER, and the handles of keys and certificates | `Standard.X509` |
| `Bindings.Entropy` | `standard/src/Bindings/Entropy.hih`, `.hiq` | getentropy, for the keys of hash maps | a call into C with `@embed` | `Standard.HashMap` |
| `Bindings.Testing` | `standard/src/Bindings/Testing.hih`, `.hiq` | the runtime's question whether the programme runs under valgrind, which only a build of `hilde test --valgrind` asks valgrind | a call into the runtime with `@embed` | `Standard.Testing` |

## The declarations of C

`scripts/gen-bindings.py` writes these from a spec under `bindings/`: the C
functions and constants of a library as its header declares them, with
address types.  Only the bindings above use them.

| module | files | from | used by |
| --- | --- | --- | --- |
| `Bindings.C.Libcrypto` | `bindings/generated/Libcrypto.hih`, `.hiq` | `bindings/libcrypto.spec` | `Bindings.Libcrypto` |
| `Bindings.C.Tls` | `bindings/generated/Tls.hih`, `.hiq` | `bindings/tls.spec` | `Bindings.Tls` |
| `Bindings.C.Pcre2` | `bindings/generated/Pcre2.hih`, `.hiq` | `bindings/pcre2.spec` | `Bindings.Pcre` |
| `Bindings.C.Sqlite3` | `bindings/generated/Sqlite3.hih`, `.hiq` | `bindings/sqlite3.spec` | `Bindings.Sqlite`, `Bindings.SqliteReplica` |
| `Bindings.C.SqlCipher` | `bindings/generated/SqlCipher.hih`, `.hiq` | `bindings/sqlcipher.spec` | `Bindings.SqlCipher` |
| `Bindings.C.Libpq` | `bindings/generated/Libpq.hih`, `.hiq` | `bindings/libpq.spec` | `Bindings.Postgres` |
| `Bindings.C.Mariadb` | `bindings/generated/Mariadb.hih`, `.hiq` | `bindings/mariadb.spec` | `Bindings.MariaDB` |
| `Bindings.C.Duckdb` | `bindings/generated/Duckdb.hih`, `.hiq` | `bindings/duckdb.spec` | `Bindings.DuckDB` |
| `Bindings.C.Argon2` | `bindings/generated/Argon2.hih`, `.hiq` | `bindings/argon2.spec` | `Bindings.Argon2` |
| `Bindings.C.Probe` | `bindings/generated/Probe.hih`, `.hiq` | `bindings/probe.spec` | nothing: the generator's own test, over libm |
| `Bindings.C.ProbePP` | `bindings/generated/ProbePP.hih`, `.hiq` | `bindings/probe-pp.spec` | nothing: the generator's own test, over libm |

## Built into the compiler

Three modules are compiled into the compiler rather than read from
`standard/src`.  `Hilde.Pervasive` is the prelude every module sees;
its `spanPart` checks the part it is asked for before it makes a span
of it.
`Hilde.Memory` holds addresses, pointers and raw memory, and only an unsafe
module may import it (error H2028).  `Hilde.Array` is the heap array:
every one of its operations checks its index or its span and stops the
program with a message when it is out of range, so a safe module may import
it; `Standard.Buffer` and `Standard.Box` are built on it.
