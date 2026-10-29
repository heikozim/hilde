# The standard library

Every module of the standard library, in the order of its name, with the
head of its interface: what it is for, what it guarantees, and an example.
The modules named Bindings bind a C library and are unsafe; which
safe module stands on each is in `docs/unsafe.md`.  This file is made by
`python3 scripts/check-standard-library-doc.py --write`, and the checks hold
it to the heads.

## Bindings.Account

Binds the lookup of an account in the password database and the effective user of the process, from the runtime.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Account is the safe module built on it, and the one a programme imports.
- A name longer than 255 bytes or holding a zero byte is not looked up.

```
let user: Int64 := accountNumber("_notes", false);
```

## Bindings.Arena

Binds the arena of the runtime in lib/prelude.c, which takes memory with mmap and hands out pieces.

- It reaches C with @embed and turns an address into a reference, so it is an unsafe module.
- Standard.Arena is the safe module built on it, and the one a programme imports.
- Each function here is the one of Standard.Arena with the same name.

```
let made: Option[Arena] := createArena(65536);
let got: Option[Span![Int32, R]] := arenaSpan(r, 100);
```

## Bindings.Argon2

Binds libargon2, the reference implementation of Argon2, through Bindings.C.Argon2.

- It hands addresses to C, so it is an unsafe module.
- Standard.Password is the safe module built on it.
- It computes Argon2id of version 0x13 only.
- A refused input or a failure of the library gives None, and nothing aborts.

```
let tag: Option[String] := argon2id(asSpan(&password), asSpan(&salt), 3, 65536, 4, 32);
```

## Bindings.Bcrypt

Binds the check of a bcrypt hash through the system's own library, by a function of the runtime.

- The check is crypt_checkpass on OpenBSD, crypt_rn of libxcrypt on Linux and crypt_r on FreeBSD.
- On macOS the C library has no bcrypt, and every check answers -1.
- It reaches C with @embed, so it is an unsafe module.
- Standard.Password is the safe module built on it.
- It checks a bcrypt hash and never makes one.

```
let verdict: Int32 := bcryptCheck(asSpan(&password), asSpan(&stored));
```

## Bindings.Bits

Binds the reading of the bits of a number as a number of another type of the same width, in C.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Bits is the safe module built on it, and the one a programme imports.
- Every bit pattern is kept: nothing is rounded, and a NaN keeps its payload.

```
let bits: Nat64 := float64Bits(1.0);
```

## Bindings.BuildInfo

Binds what the compiler writes into the C of the programme about its build.

- It reaches C with @embed, so it is an unsafe module.
- Standard.BuildInfo is the safe module built on it, and the one a programme imports.
- The texts are C strings of the programme's data, so their spans live as long as the programme.

```
let hash: Span[Nat8, Static] := commitText();
```

## Bindings.Context

Binds what Standard.Context needs of the kernel and the runtime: pipes and a chain to wait on.

- The chain of reading ends lives in lib/prelude.c, and a context waits on it with poll(2).
- Both ends of a new pipe are close-on-exec.
- It hands addresses to C, so it is an unsafe module.
- Standard.Context is the safe module built on it, and the one a programme imports.

```
let root: Node := emptyNode();
let ready: Int32 := nodeReady(&root, 0);
releaseNode(root);
```

## Bindings.Database

Binds nothing outside: it holds a driver's value in a box whose type does not name the driver.

- It binds nothing outside, but it casts a box to the type its caller names, so it is an unsafe module.
- Standard.Database is the safe module built on it, and its drivers reveal only what they erased.
- abandon does not return.

```
let box: Erased := erase(connection);
```

## Bindings.DuckDB

Binds libduckdb, DuckDB's release build, through the declarations of Bindings.C.Duckdb.

- It hands handles to C by value and by address and makes spans over the memory of a data chunk.
- So it is an unsafe module.
- Standard.DuckDB is the safe module built on it, the one a programme imports and documented there.

```
let opened: Either[DuckError, Connection] := connect("/var/db/stats.duckdb", false);
let changed: Either[DuckError, Nat64] := execute(&!db, "DELETE FROM hits", noValues());
```

## Bindings.Entropy

Binds getentropy, the system's call for a few bytes of secure random, for the keys of hash maps.

- It calls C with @embed, so it is an unsafe module.
- Standard.HashMap is the safe module built on it.
- A failed call gives 0, which a caller tells from a rare true 0 by asking twice.

```
let seed: Nat64 := entropyWord();
```

## Bindings.File

Binds the file, directory, process, environment and socket calls of the C library, by lib/prelude.c.

- It hands the kernel the address of a string's bytes, so it is an unsafe module.
- It holds a directory stream as a pointer.
- Standard.File is the safe module built on it, and the one a programme imports.
- A path here is a copy with a zero byte after it and none inside, as Standard.File makes it.
- A path that is empty, does not end in a zero byte or holds one before its end is refused.
- A count never reaches past the string it names.

```
let number: Int32 := openRead(&path);
let read: Int64 := readInto(number, &!buffer, 0, 4096);
let closed: Bool := closeNumber(number);
```

## Bindings.Libcrypto

Binds libcrypto through the declarations in Bindings.C.Libcrypto.

- The library is that of OpenSSL on Linux and that of LibreSSL on OpenBSD.
- It hands addresses to C, so it is an unsafe module.
- Standard.Libcrypto is the safe module built on it, and the one a programme imports.
- Each function here is the one of Standard.Libcrypto with the same name.

```
let digest: Option[String] := sha256(asSpan(&message));
let sealed: Option[String] := sealAes256Gcm(asSpan(&key), asSpan(&nonce), asSpan(&text), "");
```

## Bindings.MariaDB

Binds libmariadb, MariaDB Connector/C, through the declarations of Bindings.C.Mariadb.

- It fills the binding structures of prepared statements in C and makes spans over C memory.
- So it is an unsafe module.
- Standard.MariaDB is the safe module built on it, the one a programme imports and documented there.

```
let opened: Either[MariaError, Connection] := connect("db.example.org", 3306, "shop", "app",
    asSpan(&password), "/etc/ssl/cert.pem", false);
let changed: Either[MariaError, Nat64] := execute(&!db, "DELETE FROM carts", noValues());
```

## Bindings.MlDsa

Binds ML-DSA of FIPS 204 from the libcrux code the compiler carries, the backend of Standard.MlDsa.

- It calls C with @embed, so it is an unsafe module.
- Standard.MlDsa is the safe module built on it, and the one a programme imports.
- The same portable C runs on every system, with no library to link.
- The libcrux code is a stopgap: once LibreSSL offers ML-DSA natively, this backend moves to libcrypto and the libcrux code is removed.
- Every length is checked here before C reads a byte; a wrong one gives None or false.
- A level is 44, 65 or 87; any other gives None, false or 0.
- In a task with too little stack left a call gives None or false instead of running past the guard pages.

```
let made: Option[KeyBytes] := keypair(44, asSpan(&seed));
```

## Bindings.Pcre

Binds the 8-bit library of PCRE2, libpcre2-8, through the declarations in Bindings.C.Pcre2.

- It hands addresses to C, so it is an unsafe module.
- Standard.Pcre is the safe module built on it, and the one a programme imports.
- It compiles a pattern and runs one search; every search a programme sees is built on that.
- Standard.PcreJit, the other safe module on it, also asks the JIT of PCRE2 for machine code.

```
let compiled: Either[String, Code] := compileCode("[a-z]+", 1000000);
let found: Either[Int32, Option[Buffer[Index]]] := search(&regex, asSpan(&text), 0);
```

## Bindings.Platform

Binds the names of the system and the machine the programme was compiled for, and of its host, from the runtime.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Platform is the safe module built on it, and the one a programme imports.
- The system and the machine are fixed when the programme is compiled, from the macros of the C compiler.
- The host name is asked of the kernel once, the first time, and kept.

```
let system: Span[Nat8, Static] := systemText();
```

## Bindings.Poller

Binds the poller of the runtime in lib/prelude.c, which waits on many descriptors at once.

- It waits with epoll on Linux and with kqueue on OpenBSD, FreeBSD and macOS.
- It reaches C with @embed and holds the runtime's handle as a pointer, so it is an unsafe module.
- Standard.Poller is the safe module built on it, and the one a programme imports.

```
let added: Bool := addDescriptor(&!handle, listener, 1);
let ready: Int32 := waitHandle(&!handle, 1000);
let first: Int32 := eventDescriptorAt(&handle, 0);
```

## Bindings.Postgres

Binds libpq, the client library of PostgreSQL, through the declarations of Bindings.C.Libpq.

- It hands addresses and arrays of values to C and makes spans over a result: an unsafe module.
- Standard.Postgres is the safe module built on it, the one a programme imports and reads.
- A connection runs over TCP with TLS, sslmode verify-full, against the CA certificates given.
- All values and all columns travel in the binary form of the server.
- A failure is a PgError: the SQLSTATE read in base 36, or a negative code of this module.
- A failure of start is kept in the cursor and reported by finish.

```
let values: Values := withInt64(noValues(), 42);
let changed: Either[PgError, Nat64] := execute(&!db, "DELETE FROM cart WHERE id = $1", values);
```

## Bindings.Resolve

Binds the resolver of the C library, getaddrinfo, for Standard.Resolve.

- It reaches C with @embed, so it is an unsafe module; Standard.Resolve is the safe module built on it.
- A function of the runtime copies every address out of the answer before the answer is freed.
- One answer gives at most maximumAddresses addresses; the resolver's others are dropped.
- Both families come back; an IPv6 address that maps an IPv4 one comes as the IPv4 address.
- A failure is a number: -1 no address for the name, -2 no answer, -3 anything else.

```
let found: Either[Int32, String] := resolveRecords("example.org");
```

## Bindings.Resource

Binds the resource calls of the runtime in lib/prelude.c: limits, usage and the boot clock.

- It reaches C with @embed, so it is an unsafe module; Standard.Resource is the safe module built on it.
- The calls are getrlimit(2), setrlimit(2), getrusage(2) and the clock since the system started.
- A resource is an index: 0 the data segment, 1 open files, 2 the size of a core file.
- No limit is the largest Nat64.
- A refusal of the kernel gives None or false; nothing aborts.
- CPU time is counted in microseconds, the largest resident set in bytes.

```
let files: Option[LimitPair] := limitOf(1);
let raised: Bool := setLimitOf(1, 4096, 4096);
```

## Bindings.Sandbox

Binds the calls that confine the process, through the functions of the runtime in lib/prelude.c.

- On OpenBSD the calls are pledge and unveil; on Linux no new privileges, Landlock and seccomp.
- On macOS the call is seatbelt, which starts the programme again under a Seatbelt profile.
- On FreeBSD the call is capsicum, which opens the paths and enters capability mode.
- It hands the kernel the address of a string's bytes, so it is an unsafe module.
- Standard.Sandbox is the safe module built on it, and the one a programme imports.
- A string given here ends in one zero byte and holds no other, as Standard.Sandbox makes it.
- Every function checks that itself and refuses a string that does not, without a call.
- An answer is a number: as a rule 1 done, 0 refused, -1 when the platform has no such mechanism.

```
if platform() = 1 then
    let pledged: Int32 := pledge(&promises);
end if;
```

## Bindings.Secret

Binds the reading of a secret from the terminal or a descriptor, into memory that is wiped before it is given back.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Secret is the safe module built on it, and the one a programme imports.
- The buffer holds secretCapacity bytes; it is wiped on every failure and when it is destroyed.

```
case allocateRaw() of
    when Some(value as raw: RawSecret) do
        destroyRaw(raw);
    when None do
        skip;
end case;
```

## Bindings.Serial

Binds a count shared by the whole process, for numbers that must never repeat.

- It keeps the count in C with @embed, so it is an unsafe module.
- Standard.Graph is the safe module built on it.
- The count holds when tasks on several threads call it at once.
- After the largest Nat64 the count wraps round to 0, which the caller must refuse.

```
let serial: Nat64 := nextSerial();
```

## Bindings.Shared

Binds the mutexes of the runtime in lib/prelude.c and the atomic operations of the C compiler.

- The value a mutex guards lives in raw memory beside the lock, so it is an unsafe module.
- That value is moved out and back through a read reference.
- An atomic is one word of 64 bits.
- Standard.Shared is the safe module built on it, and the one a programme imports.
- Each declaration here is the one of Standard.Shared with the same name.

```
let { value: Nat64, key: Key } := acquire(&mutex);
release(&mutex, value + 1, key);
```

## Bindings.Signal

Binds the signal handling of the runtime in lib/prelude.c, with alarm(2), getpid(2) and kill(2).

- It reaches C with @embed, so it is an unsafe module; Standard.Signal is the safe module built on it.
- The handler counts signals and writes a byte to a pipe of the runtime.
- A kind is an index: 0 hangup, 1 interrupt, 2 terminate, 3 user1, 4 user2.
- One watch is in place at a time; a second watchMask fails and installs nothing.
- The counts go on from one watch to the next.

```
if watchMask(7) then
    let woken: Bool := waitPipe(1000);
    let stops: Nat32 := arrivals(2);
end if;
```

## Bindings.SqlCipher

Binds libsqlcipher, the C library of SQLCipher, through the declarations in Bindings.C.SqlCipher.

- It hands addresses to C and makes spans over the memory of SQLite, so it is an unsafe module.
- Standard.SqlCipher is the safe module built on it, and the one a programme imports.
- Everything but the key is generated from Bindings.Sqlite.
- Each function is the one of Standard.SqlCipher with the same name, on a connection without a mode.

```
case openWriter("app.db", makeKey(secret)) of
    when Right(right as db: Connection) do
        closeDatabase(db);
    when Left(left as error: SqlError) do
        printLn(describe(error));
end case;
```

## Bindings.Sqlite

Binds libsqlite3, the C library of SQLite, through the declarations in Bindings.C.Sqlite3.

- It hands addresses to C and makes spans over the memory of SQLite, so it is an unsafe module.
- Standard.Sqlite is the safe module built on it, and the one a programme imports.
- Each function is the one of Standard.Sqlite with the same name, on a connection without a mode.

```
case openWriter("app.db") of
    when Right(right as db: Connection) do
        closeDatabase(db);
    when Left(left as error: SqlError) do
        printLn(describe(error));
end case;
```

## Bindings.SqliteReplica

Binds libsqlite3 through the declarations in Bindings.C.Sqlite3, for statements whose text is known only when they run.

- It hands addresses to C, so it is an unsafe module.
- Standard.SqliteReplica is the safe module built on it, and the one a programme imports.
- A statement is prepared alone and finalized after its run; nothing is cached.
- prepareOne refuses text that holds more than one statement, or none.
- The backup copies a whole database from one connection into a file or from a file.
- A failure comes back as SQLite's extended result code, or its words.

```
let opened: Either[String, Database] := openDatabase("data.db");
```

## Bindings.SystemLog

Binds the system log, openlog(3), syslog(3) and closelog(3), through the runtime in lib/prelude.c.

- It reaches C with @embed, so it is an unsafe module; Standard.Log is the safe module built on it.
- The name is cut to 63 bytes; an unknown facility counts as user, an unknown priority as error.
- Text is sent as it is, never read as a format, and ends at a zero byte if it holds one.
- Opening again closes the connection made before.

```
openSystemLog("shop", 1);
writeSystemLog(1, "started");
closeSystemLog();
```

## Bindings.Task

Binds the fibers, scopes and channels of the runtime in lib/prelude.c, which run tasks on threads.

- A task's argument and result live in raw memory between spawn and join: an unsafe module.
- Standard.Task is the safe module built on it, and the one a programme imports.
- The compiler checks what a task is handed at the calls of Standard.Task, not here.
- Each declaration here is the one of Standard.Task with the same name.

```
let started: Either[Nat64, Task[Nat64]] := spawn(&!scope, double, 21);
```

## Bindings.Terminal

Binds the standard streams of libc, stdin, stdout and stderr, through the runtime in lib/prelude.c.

- It reaches C with @embed and imports C functions, so it is an unsafe module.
- Standard.IO.Terminal is the safe module built on it, and the one a programme imports.
- Bytes go one at a time through the streams of libc; writeStderrText writes with write(2).
- A terminal is named by the number of its descriptor.

```
if isTerminalNumber(0) then
    let quiet: Bool := setEcho(0, false);
end if;
```

## Bindings.Testing

Binds what Standard.Testing asks the runtime: whether the programme runs under valgrind.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Testing is the safe module built on it, and the one a test imports.
- Only a build of hilde test --valgrind asks valgrind; any other build answers false.

```
let underValgrind: Bool := runningUnderValgrind();
```

## Bindings.Time

Binds the clocks of libc through the runtime in lib/prelude.c, which calls clock_gettime.

- It reaches C with @embed, so it is an unsafe module.
- Standard.Time is the safe module built on it, and the one a programme imports.
- The wall clock gives zero when it could not be read.
- The monotonic clock gives a negative number in a build without one; hasMonotonic says which.

```
if hasMonotonic() then
    let now: Int64 := monotonicReading();
end if;
```

## Bindings.Tls

Binds libtls, the TLS library of OpenBSD and, as libretls over OpenSSL, of Debian.

- It hands addresses to C through the declarations in Bindings.C.Tls, so it is an unsafe module.
- Standard.Tls is the safe module built on it, and the one a programme imports.
- Each function here is the one of Standard.Tls with the same name, except connectSocket and connectSocketAs.
- connectSocket is the half of Standard.Tls.connectOver that works on the socket's number.
- A socket handed to connectSocket or acceptSocket stays open when the client is closed.
- A failure comes back as a String with the message.

```
let client: Either[String, Client] := connect("example.org", "443", "/etc/ssl/cert.pem");
```

## Bindings.Watch

Binds the watching of files in the runtime in lib/prelude.c: inotify on Linux, kqueue on the BSDs.

- It reaches C with @embed and hands it the address of a path's bytes: an unsafe module.
- Standard.Watch is the safe module built on it.
- A path ends in a zero byte and holds no other; watchAdd refuses one that does not.
- Watchers and watches are numbers; a negative number is a failure.
- watchWait gives -2 when the time ran out and -1 on a failure.

```
let watcher: Int32 := watchOpen();
let watch: Int32 := watchAdd(watcher, &path, true);
let changed: Int32 := watchWait(watcher, 5000);
```

## Bindings.X509

Binds the X.509 and key functions of libcrypto that Standard.X509 needs.

- Every call is a C expression on the system's OpenSSL headers, held to its real prototype.
- It hands addresses to C, so it is an unsafe module.
- Standard.X509 is the safe module built on it, and the one a programme imports.
- Each function is the one of Standard.X509 its docstring names, on the raw numbers of the kinds.
- rsaBits takes only the three kinds of RSA; any other kind stops the programme.
- Kinds: 1 P-256, 2 P-384, 3 Ed25519, 4 to 6 RSA of 2048, 3072 and 4096 bits, 7 P-521.
- Kinds 8 to 10 are ML-DSA-44, -65 and -87; 0 stands for no kind.
- Key and Cert are linear: dropKey and dropCert free them.

```
let key: Option[Key] := newKey(1);
```

## Standard.About

The full version text and the info text of a programme, from its build and its platform.

- One line per field, the name in the first twelve columns and the value from column 13.
- The fields are version, commit, built, compiler and system, then the copyright last.
- fullVersionWith adds a line library for each linked C library the programme names, before the copyright.
- info adds what the running programme sees: binary, host and the time, read when it is called.
- The commit carries (dirty) when the work tree held changes; none when the build had no commit.
- The build time is UTC, in the form 2026-10-17T19:30:00Z.
- A programme that imports this module carries Standard.BuildInfo with it; one that does not, carries neither.

```
setFullVersion(&!command, fullVersion("1.2.0", "2026 Example Corp"));
```

## Standard.Account

The accounts of the system: the numbers of an account by its name, and who the process runs as.

- An account is looked up in the password database, as getpwnam(3) does; nothing is changed.
- A name longer than 255 bytes or holding a zero byte is no account.

```
case lookupAccount("_notes") of
    when AccountFound(numbers as n: AccountNumbers) do
        useOwner(n.user, n.group);
    when NoAccount do
        refuse();
    when LookupFailed do
        refuse();
end case;
```

## Standard.Acme

A client of the ACME protocol of RFC 8555, by which a CA issues certificates for DNS names.

- Every request is a JWS signed with the account key, a P-256 key, and so ES256.
- Every request carries a fresh nonce of the server and the URL it goes to.
- Requests go through Standard.HttpClient over HTTPS, verified against the certificates in caFile.
- A badNonce answer is retried once with the nonce it brought, as the RFC asks.
- Any other problem the server reports comes back as a Left with its type and detail.
- The steps are separate functions: between them the caller proves control of each name.

```
let opened: Either[AcmeError, Account] := openAccount(directory, key, "", caFile, limits);
let order: Either[AcmeError, Order] := newOrder(&!account, "example.org,www.example.org");
let challenge: Either[AcmeError, Challenge] := challengeOf(&!account, authorization, "dns-01");
let record: String := dnsChallengeValue(&!account, asSpan(&token));
let ready: Either[AcmeError, Unit] := respond(&!account, challengeUrl);
```

## Standard.Archive

Archives in tar, tar with gzip and zip, read whole and written in memory.

- Reading stays within a Budget: so many entries, bytes in one entry and bytes in all.
- The budget is checked on the headers first, and again while a compressed entry unpacks.
- Reading checks the headers but not the names, which are listed as the archive holds them.
- Extracting judges every name first: absolute, empty, a zero byte or a .. part is refused.
- A name under which a symbolic link already lies inside the target is refused as well.
- A symbolic link is made only when its target, seen from its own directory, stays inside.
- A hard link is never extracted, and nothing that exists is overwritten.
- Modes are cut to 0755 for a directory and 0644 for a file, whatever the archive says.

```
case readArchive(asSpan(&bytes), TarGz(), defaultBudget()) of
    when Right(right as archive: Archive) do
        let unpacked: Either[Failure, Unit] := extractArchive(&archive, "/var/www/site");
        destroyArchive(archive);
    when Left(left as failure: Failure) do
        report(failure);
end case;
```

## Standard.Arena

A bump allocator behind a linear handle, for the memory of one unit of work such as one request.

- Only code that asks an arena for memory allocates from it; nothing else does.
- A reference or span it hands out carries the region of its borrow and cannot outlive it.
- The arena cannot be reset or freed while it is borrowed.
- The arena never grows: a request beyond its capacity gives None.
- It holds Free values only, because resetArena releases everything at once.
- resetArena and freeArena overwrite what was used.

```
case createArena(65536) of
    when Some(value as made: Arena) do
        var arena: Arena := made;
        borrow r: &![Arena, R] := &!arena do
            let got: Option[Span![Int32, R]] := arenaSpan(r, 100);
        end borrow;
        arena := resetArena(arena);
        freeArena(arena);
    when None do
        abort("No memory for the arena.");
end case;
```

## Standard.Arguments

Reading a programme's command line against a declared command, its options and subcommands.

- Every declaration hands back a key, so a misspelt name is one the compiler does not know.
- Nothing on the command line stops the programme: every mistake comes back as an ArgumentError.
- An error names the argument it was found at and, for a name nearly right, the name meant.
- The syntax is POSIX with long options; options and positional arguments may be mixed.
- -h, --help, and -V and --version once a version is set, are built in, as are help and version as words; --full after a version asks for the full text.
- -v -s -c -e and --verbose --sandbox --config --env --pepper --socket --json are reserved for their one meaning.
- Help, usage, an mdoc man page and completion for bash, zsh and fish come from the declarations.
- Option names and words are ASCII; a text value must be UTF-8, and a path is taken as its bytes.
- In help and in messages a byte that is not UTF-8 is shown as \xNN.

```
var command: Command := makeCommand("fetch", "Fetches a file.");
let verbose: FlagKey := addVerbose(&!command, "Say more.");
let output: PathKey := addPath(&!command, option("output", 0, "Where to write."));
let arguments: Buffer[String] := processArguments();
let parsed: Either[ArgumentError, Outcome] := parse(&command, &arguments);
```

## Standard.AtomicFile

Writing a file so that whoever opens it finds the old content or the new, never a part.

- The content goes to a temporary file beside it, is synced, and is renamed over the old file.
- The directory is synced after the rename, so that the rename survives a crash.
- A replaced file keeps its owner and group; when they cannot be given, nothing is replaced.
- The file gets exactly the mode given; the umask does not change it.
- Only an ordinary file is replaced; a symbolic link is neither followed nor overwritten.
- A backup is a hard link to the old file, named with .bak, so it keeps owner, mode and times.
- The directory must allow hard links for a backup.

```
let mode: Nat32 := 420;
let written: Either[AtomicFailure, Bool] := writeWithBackup("app.conf", asSpan(&text), mode);
let change: Either[AtomicFailure, Change] := writeIfChanged("app.conf", asSpan(&text), mode);
```

## Standard.Base32

Base32 after RFC 4648, section 6, the form in which the secrets of one-time passwords are written.

- The alphabet is A to Z and 2 to 7; five bytes become eight characters.
- The padded form ends with = up to a multiple of eight characters; the unpadded form has none.
- Decoding takes capitals and small letters alike, since people type these secrets.
- A byte outside the alphabet, a length no encoding has or misplaced padding gives None.
- Bits left over at the end that are not zero give None too; nothing aborts on bad input.

```
let secret: String := encodeBase32Unpadded(asSpan(&key));
let back: Option[String] := decodeBase32(asSpan(&secret));
```

## Standard.Base64

Base64 after RFC 4648, section 4, padded or unpadded.

- The alphabet is A to Z, a to z, 0 to 9, plus and slash; three bytes become four characters.
- The padded form ends with one or two = so that its length is a multiple of four.
- The unpadded form leaves them out, as the strings of password hashes do.
- Decoding refuses rather than guesses: bad input gives None, and nothing aborts on it.

```
let text: String := encode(asSpan(&bytes));
let back: Option[String] := decode(asSpan(&text));
let salt: Option[String] := decodeUnpadded("c2FsdHNhbHQ");
```

## Standard.Bits

Reads the bits of a number as an unsigned number of the same width, and back, for formats that store numbers as bytes.

- Every bit pattern is kept: nothing is rounded, and a NaN keeps its payload.
- A number read back from its bits is the same number.
- The bytes of a number, lowest first, are the bytes of its bits.

```
let one: Float64 := float64FromBits(float64Bits(1.0));
```

## Standard.Bounded

A typeclass for the smallest and the largest value of a type.

- minBound and maxBound take nothing and cannot fail.
- Instances: Bool, Nat8 to Nat64, Int8 to Int64 and Index.
- For Bool the smallest is false and the largest true.
- For a natural type the smallest is 0.

```
let top: Nat32 := maxBound();
let bottom: Int64 := minBound();
```

## Standard.Box

One value on the heap, owned by a linear handle.

- A box is how a recursive type refers to itself, and a pattern in a case looks through it.
- A box is linear: unbox gives it back and returns the contents.
- A failed allocation hands the value back as the Left, so nothing leaks.

```
case makeBox(7) of
    when Right(right as box: Box[Nat64]) do
        let seven: Nat64 := unbox(box);
    when Left(left as value: Nat64) do
        skip;
end case;
```

## Standard.Buffer

A linear, growable array on the heap.

- Every index and every span is checked; one out of range stops the programme with a message.
- Growing aborts when the memory cannot be had; the safe makers give None instead.
- The readers that copy take Free elements; nthRef and swapNth work for linear ones too.
- A buffer is linear: destroyEmpty or destroyFree gives it back.
- insertFront costs time linear in the length of the buffer.

```
var prices: Buffer[Nat64] := allocateEmpty();
insertBack(&!prices, 250);
let first: Nat64 := nth(&prices, 0);
destroyFree(prices);
```

## Standard.BuildInfo

What a programme knows about its own build: commit, state of the work tree, time, compiler and its own values.

- The compiler fills it in only for a programme that imports this module; git runs only then.
- The commit is 40 or 64 hex digits, or empty when the build was not in a git work tree or ran with --no-build-vcs.
- The time is SOURCE_DATE_EPOCH when it was set, so that a build can give the same bytes twice.
- Values come from --build-value=name=value: names of 1 to 64 bytes, texts of at most 1024 bytes.
- Every text lives as long as the programme; no function allocates.

```
printLn(commit());
case value("channel") of
    when Some(value as channel: Span[Nat8, Static]) do
        printLn(channel);
    when None do
        printLn("no channel");
end case;
```

## Standard.Cache

A cache of values under keys, with a lifetime per entry and limits on count and total size.

- Time comes from the caller in monotonic nanoseconds; a lifetime of 0 never expires.
- When full, the entry used longest ago goes first, chosen the same way on every run.
- A put into a full cache costs time linear in the number of entries.
- Every entry that leaves the cache comes back to the caller as a key and value pair.
- Keys are Free, and the readers copy, so they take Free values only.
- A fill that began before a clear or a flush stores nothing.

```
var cache: Cache[Nat64, Nat64] := makeCache(1000, 1048576, 60000000000);
let price: Option[Nat64] := getWith(&!cache, item, nowNanos(), lookUpPrice);
```

## Standard.Calendar

Dates and times of day in the Gregorian calendar, time zones from zone files, and RFC 3339 text.

- An Instant counts seconds and nanoseconds since 1970-01-01T00:00:00Z, without leap seconds.
- A Civil is what a clock shows: a date from the year 0 to 9999 and a time of day, no zone.
- A Zone is read from a file in the format of RFC 8536, version 2 or later, at most one MiB.
- After the last transition a zone file lists, the rule of its footer gives the offset.
- Outside the years 0 to 9999 the functions give None; a second 60 is never read.
- Standard.Time reads the clocks; this module only computes and reads zone files.

```
let zone: Either[ZoneFailure, Zone] := loadZone("Europe/Berlin");
let stamp: Option[Stamp] := parseRfc3339("2026-09-27T01:10:00+02:00");
```

## Standard.Cbor

CBOR as RFC 8949 defines it, read strictly into a document and looked into by items.

- An item is checked from its first byte to its last when it is read, and the document kept.
- Only the shortest head of a number or a length is taken, as deterministic encoding asks.
- Indefinite lengths, tags and simple values other than false, true, null and undefined are refused.
- Nesting deeper than mostDepth and a map of more than mostEntries pairs are refused.
- A key twice in one map is refused, compared by its encoded bytes.
- Text strings are checked to be UTF-8.
- Reading refuses rather than guesses, and a refusal names the fault and the byte offset.
- Nothing here aborts on bad input; time linear in the length times mostEntries.

```
case readCbor(asSpan(&coseKey)) of
    when Right(right as key: Cbor) do
        let top: CborItem := rootOf(&key);
        let entries: Option[Index] := countOf(&key, top);
        destroyCbor(key);
    when Left(left as refused: CborError) do
        printLn(refused.offset);
end case;
```

## Standard.CompositeSig

Signs and verifies with the composite of ML-DSA-44 and Ed25519 of the IETF draft for composite signatures.

- The signed message is M' = prefix, label, the length of the context, the context and the SHA-512 of the message.
- The signature is the one of ML-DSA-44 over M' with the label as its context, then the one of Ed25519 over M'.
- verify holds only when both hold: either scheme alone breaking does not forge a signature.
- The label names the use; openSshLabel is the one of OpenSSH's ssh-mldsa44-ed25519.
- A key is two seeds of 32 bytes, ML-DSA first, as OpenSSH keeps it; the public key is the two public keys.

```
let signed: Option[String] := sign(&key, openSshLabel(), asSpan(&message), "");
```

## Standard.Context

Cancellation and deadlines that reach a whole chain of calls and tasks.

- A context is done when its canceller or that of any context above it was cancelled.
- It is done as well when its deadline or one of those above it has passed.
- A context is passed down by read reference, into the tasks of a lending scope as well.
- A cancel is seen at once, from any thread.
- A chain of n levels holds at most 2n descriptors and is at most maxDepth deep.
- Context and Canceller are linear: every canceller is cancelled, every context destroyed.

```
let root: Context := background();
case withTimeout(&root, 5000) of
    when Some(value as made: Derived) do
        let { context: Context, canceller: Canceller } := made;
        let budget: Nat32 := remainingMilliseconds(&context, 1000);
        cancel(canceller);
        destroyContext(context);
    when None do
        skip;
end case;
destroyContext(root);
```

## Standard.Cookie

HTTP cookies after RFC 6265: one cookie read out of a Cookie header, a Set-Cookie value written.

- A cookie written here has no Domain attribute, so only the host that set it gets it back.
- strictOptions gives Secure, HttpOnly, SameSite=Strict and no expiry.
- A name, value or path that could end the header or start an attribute is refused, not escaped.
- A value outside printable ASCII has to be encoded by the caller first, as hexadecimal or base64.
- Every refusal comes back as None.

```
let header: Option[String] := setCookie("session", token, "/", strictOptions());
let sent: Option[String] := cookieValue(asSpan(&cookieHeader), "session");
```

## Standard.Cose

COSE keys of RFC 9052 and RFC 9053 turned into the DER public keys that Standard.X509 verifies with.

- A key of kty 2 with crv 1, 2 or 3 is NIST P-256, P-384 or P-521; x and y are taken, a compressed point is refused.
- A key of kty 1 with crv 6 is Ed25519; a key of kty 3 is RSA with n and e, of 2048 bits at least.
- When the key names alg, it must be the one X509.verifyMessage checks: -7, -35 and -36 for the curves, -8 for Ed25519, -257 for RSA.
- Any other key, a coordinate of the wrong length and bytes that are no CBOR map give None.
- Nothing here aborts on bad input.

```
case publicKeyFromCose(asSpan(&credentialKey)) of
    when Some(value as der: String) do
        let good: Bool := verifyMessage(asSpan(&der), asSpan(&signed), asSpan(&signature));
        destroyString(der);
    when None do
        printLn("not a key");
end case;
```

## Standard.Csrf

Protection against cross-site request forgery: a token bound to the session, and origin headers.

- The token is the HMAC-SHA256 of the session token under a key of the server, never stored.
- Another session's token is worth nothing, and an empty session token is never valid.
- A key shorter than csrfKeyBytes gives None from csrfToken and false from csrfValid.
- csrfValid compares in the same time whatever the bytes.
- sameOriginRequest is a second line of defence, from the Sec-Fetch-Site and Origin headers.

```
let token: Option[String] := csrfToken(serverKey, sessionToken);
if changingMethod(verb) and not csrfValid(serverKey, sessionToken, submitted) then
    refuse();
end if;
```

## Standard.Csv

Tables in CSV, as RFC 4180 describes them, read and written.

- A quoted field may hold the separator, a doubled double quote and line breaks; a plain one not.
- Rows end with CR LF or LF, the last one with neither too; an empty line is no row.
- Reading refuses rather than guesses, with the line and the byte where the fault was found.
- Every row has as many fields as the first; text that is not UTF-8 is refused.
- A byte order mark at the start is skipped; nothing aborts on bad input.
- Writing quotes a field only when it has to, and ends every row with CR LF.

```
case readCsv(text) of
    when Right(right as table: CsvTable) do
        let rows: Index := rowCount(&table);
        destroyCsv(table);
    when Left(left as error: CsvError) do
        report(error.line, error.offset);
end case;
```

## Standard.Database

One interface over SQLite, SQLCipher, PostgreSQL and MariaDB, the backend chosen at open.

- A backend is in the programme only when its driver module is imported: Standard.Database.Sqlite, Standard.Database.Postgres or Standard.Database.MariaDB.
- The code that reads and writes stays the same whatever backend was opened.
- Values go to the question marks of a statement and never become part of its text.
- For PostgreSQL each question mark outside strings, quoted names and comments becomes $1, $2, ...
- Values are Int64, Float64, Bool, text, bytes, null and timestamps in microseconds since 1970 UTC.
- On SQLite a Bool is stored as the integer 0 or 1 and a timestamp as its integer.
- Database[M] is linear and must be closed; execute takes a Database[Writing] only.
- A Transaction ends by commit or rollback, a Cursor by finish; a column's text lives for its row.
- isUniqueViolation, isConstraintViolation and isBusy class a DbError the same on every backend.

```
case openSqlite("app.db") of
    when Right(right as opened: Database[Writing]) do
        var db: Database[Writing] := opened;
        let values: Values := withText(withInt64(noValues(), 7), "Ada");
        case execute(&!db, "INSERT INTO people (id, name) VALUES (?, ?)", values) of
            ...
        end case;
        closeDatabase(db);
    ...
end case;
```

## Standard.Database.MariaDB

The MariaDB driver of Standard.Database: a programme that imports it can open a MariaDB connection.

- It links libmariadb, and only a programme that imports it does.
- The question marks of a statement are sent as they stand.

```
case openMariaDB("db.example", 3306, "app", "app", password, "/etc/ssl/ca.pem") of
    when Right(right as opened: Database[Writing]) do
        ...
end case;
```

## Standard.Database.Postgres

The PostgreSQL driver of Standard.Database: a programme that imports it can open a PostgreSQL connection.

- It links libpq, and only a programme that imports it does.
- The question marks of a statement become $1, $2, ... before it is sent.

```
case openPostgres("db.example", 5432, "app", "app", password, "/etc/ssl/ca.pem") of
    when Right(right as opened: Database[Writing]) do
        ...
end case;
```

## Standard.Database.Sqlite

The SQLite and SQLCipher driver of Standard.Database: a programme that imports it can open those files.

- It links libsqlcipher, and only a programme that imports it does.
- SQLite is SQLCipher opened without a key, which writes SQLite's own file format.

```
case openSqlite("app.db") of
    when Right(right as opened: Database[Writing]) do
        ...
end case;
```

## Standard.DatabaseUsers

A store for Standard.Users in a database of Standard.Database, on every backend it has.

- The users are kept in the table hilde_users, the failed attempts in hilde_user_failures.
- openDatabaseUsers makes the two tables and their index when they are missing, in the types of the backend.
- The store holds the database; closeDatabaseUsers gives it back.

```
case openDatabaseUsers(db) of
    when Right(right as opened: DatabaseUsers) do
        var users: DatabaseUsers := opened;
        let added: Either[UserError, Bool] := addUser(&!users, "alice", asSpan(&password));
        closeDatabase(closeDatabaseUsers(users));
    when Left(left as failed: DatabaseUsersFailed) do
        let { db: Database[Writing], error: UserError } := failed;
        closeDatabase(db);
end case;
```

## Standard.Decimal

Decimal numbers for money: exact, with at most 18 digits and at most 18 of them after the point.

- A number is a sign, whole units and a scale, the digits after the point: 12.34 is 1234 at scale 2.
- Adding and subtracting are exact, and so is multiplying while the product fits in 18 digits.
- Dividing is rounded to the scale the caller names; 0.1 plus 0.2 is 0.3.
- Rounding is half away from zero: 2.345 is 2.35 at scale 2, and -2.345 is -2.35.
- Nothing aborts: overflow, division by zero and a text that is no number give None.

```
case parseDecimal("19.99") of
    when Some(value as price: Decimal) do
        let total: Option[Decimal] := multiplyDecimal(price, quantity);
    when None do
        skip;
end case;
```

## Standard.Doctor

Checks that the files, directories, socket and account a programme declares are there as they should be, and makes what is not there.

- One line per check, ok or missing, and for a missing one the command that makes it right on this system.
- A file or directory must have the kind, the mode of Standard.Paths and the owner: the service account, or the running user for a user tool.
- A socket must take a connection; nothing is written to it.
- A service's commands start with doas on OpenBSD and with sudo elsewhere when the process is not the superuser.
- Paths in the commands are quoted for the shell when they hold more than letters, digits and / . _ - + : @ % , =.
- runCheckup changes nothing; runInit makes only what is not there, overwrites nothing and runs its commands without a shell.
- For a service with a socket, init prints the FastCGIserver and UrlToolkit blocks that hand a Hiawatha site to it.

```
var checkup: Checkup := makeCheckup("notes", Service());
expectPath(&!checkup, DataDirectory(), "/var/notes");
var out: StringBuilder := makeStringBuilder();
let missing: Index := runCheckup(&checkup, false, &!out);
destroyCheckup(checkup);
```

## Standard.DuckDB

DuckDB, the database for analysis that runs inside the programme over a file of its own.

- Every open switches off reading and writing other files and loading or fetching extensions.
- The configuration is locked at open, so no statement turns those on again.
- One programme at a time opens a file for writing, and no reader opens it while a writer has it.
- Values go to the question marks of a statement and never become part of its text.
- Null is an Option; a timestamp is in microseconds since 1970-01-01 UTC.
- Each column reader takes its own types only; any other type stops the programme.
- A duplicate key and a conflict between two writers have codes of their own.

```
case openWriter("facts.duckdb") of
    when Right(right as opened: Connection[Writing]) do
        var db: Connection[Writing] := opened;
        let values: Values := withText(withInt64(noValues(), 7), "Ada");
        case execute(&!db, "INSERT INTO people VALUES (?, ?)", values) of
            ...
        end case;
        closeDatabase(db);
    ...
end case;
```

## Standard.Equality

Type classes for partial and total equivalence relations.

- PartialEquality is symmetric and transitive but need not be reflexive.
- Equality is a total equivalence: reflexive, symmetric and transitive.
- Both compare through read references, so neither uses up its arguments.
- The compiler does not check these laws; an instance is trusted to keep them.
- This module gives both instances for Unit, where any two values are equal.

```
let same: Bool := equal(&left, &right);
```

## Standard.Failure

A failure for the Left of an Either: its operation, its kind, its message and the failure behind it.

- It is meant for the boundary of a module or a programme, where a caller decides by the kind.
- Each operation on the way out may wrap a failure under its own name, with or without a kind.
- The kind of a chain is the first that is not Unclassified, from the outermost to the first cause.
- A kind maps to an HTTP status, so a server can answer a request with it.
- A Failure is linear: destroyFailure gives back the whole chain.
- Wrapping stops the programme when no memory is left, as a string does.

```
let failure: Failure := makeFailure("file.write", Unclassified(), "disk full");
let outer: Failure := wrapFailure("store.save", failure);
let line: String := describeFailure(&outer);
destroyFailure(outer);
```

## Standard.Fcgi

The FastCGI record protocol, from the responding side: records read from bytes and built into bytes.

- This module is the format and nothing else: no socket and no loop.
- The code that owns the descriptor hands bytes to it and takes bytes from it.
- Every length that arrives on the wire is checked against the bytes that are really there.
- A record that does not fit in what is left is refused with None, never read past its buffer.
- A record written holds less than 65536 bytes of content; splitting a longer one is the caller's.

```
case readHeader(bytes, 0) of
    when Some(value as header: RecordHeader) do
        let content: Option[String] := readContent(bytes, 0, header);
        let next: Index := recordLength(header);
    when None do
        skip;
end case;
```

## Standard.FcgiServer

A FastCGI responder: the loop that serves the requests of a web server through a handler.

- The handler maps a Request to the CGI output: header lines, an empty line and the body.
- Each connection is served by a task of its own, at most workers of them at a time.
- That task has 512 KiB of stack, for a handler that calls into C libraries.
- A connection beyond workers waits until one of them is done.
- A kept connection serves one request after another; a second one at once is refused.
- Parameters, body and the time a request may take to arrive are held to the limits.
- A request over a limit is answered with 431 or 413 and its connection closed.
- A late request or one that does not parse is closed without an answer.
- With serveUnixWith each running task has one of the given states alone.

```
function hello(request: Request): String is
    destroyRequest(request);
    return cgiResponse(200, "text/plain", "hello");
end;

let accepted: Option[Index] := serveUnix(&listener, hello, defaultLimits(), &!signals);
```

## Standard.File

Files, pipes, directories, child processes, the environment and sockets of Unix and TCP.

- A FileDescriptor is linear: it cannot be copied, and it cannot be dropped without closing it.
- Every path is checked before it reaches the kernel; a path that holds a zero byte is refused.
- Every descriptor is opened close-on-exec.
- A child process runs a binary given by its path; there is no search of PATH.
- In a child every descriptor above the standard three is closed first.
- An environment value longer than environmentLimit is refused, not shortened.
- secureDelete overwrites once; on flash memory and copy-on-write file systems old blocks may survive.

```
case openRead("notes.txt") of
    when Some(value as opened: FileDescriptor) do
        var file: FileDescriptor := opened;
        let text: Option[String] := readAll(&!file);
        let closed: Bool := closeFile(file);
    when None do
        skip;
end case;
```

## Standard.FileHelpers

Helpers over Standard.File for copying, measuring, naming and removing files and trees.

- Nothing here follows a symbolic link: a link in a copied tree is copied as a link.
- A link in a measured tree counts nothing, and a link where a file is expected is refused.
- A copy never replaces what is at its target; it fails instead.
- A tree deeper than 64 directories is refused rather than walked.
- A failure is a Failure whose operation names the function and whose message names the path.
- Its kind is NotFound for a missing source, Invalid for a bad argument, else Unclassified.

```
case copyDirectory("site", "site-backup") of
    when Right(right as done: Unit) do
        skip;
    when Left(left as failure: Failure) do
        let line: String := describeFailure(&failure);
        destroyFailure(failure);
end case;
```

## Standard.Graph

A directed graph whose nodes and edges each carry a value.

- A NodeId or EdgeId of a removed node or edge, or of another graph, gets None, false or Left.
- Such a number never reaches another node or edge.
- Values may be linear and nothing is dropped: whatever leaves the graph comes back to the caller.
- A graph is destroyed only empty, with destroyEmpty, or with free values, with destroyFree.
- Every walk and search has a fixed order, the same on every run and every platform.
- The instances of Weight and of TotalOrder for NodeId and EdgeId come with any import from here.

```
var graph: Graph[Nat32, Nat64] := makeGraph();
let from: NodeId := addNode(&!graph, 1);
let to: NodeId := addNode(&!graph, 2);
let added: Either[Nat64, EdgeId] := addEdge(&!graph, from, to, 5);
let reached: Bool := hasPath(&graph, from, to);
```

## Standard.Grapheme

Grapheme clusters, the characters a reader sees, by the rules of Unicode's Standard Annex 29.

- The rules are those of Unicode version 17.0.0.
- An e with a combining acute is one cluster, and so is a flag of two regional indicators.
- Emoji joined by zero width joiners, a Hangul syllable in parts and a Devanagari conjunct are one.
- CR and LF together are one cluster.
- Text is UTF-8; a byte that does not begin well-formed UTF-8 ends the cluster before it.

```
let clusters: Option[Index] := countClusters(asSpan(&name));
let firstEnd: Option[Index] := clusterEnd(asSpan(&name), 0);
```

## Standard.Gzip

Compression in the formats of gzip: DEFLATE of RFC 1951, raw or in a gzip member of RFC 1952.

- Written in Hilde; it binds no library.
- It decompresses every valid stream: stored blocks and blocks with fixed and dynamic codes.
- It compresses with fixed codes or stored blocks, finding repeats at most 32 KiB back.
- A stream of zlib at its default level is smaller than what it writes.
- Decompressing stops at a limit the caller names, since a few bytes can describe gigabytes.
- Every length, distance and code is checked before use; a stream that breaks a rule is refused.

```
let packed: String := gzip(asSpan(&page));
case gunzip(asSpan(&packed), 1048576) of
    when Right(right as unpacked: String) do
        skip;
    when Left(left as failure: GzipFailure) do
        skip;
end case;
```

## Standard.Hash

Keyed hashing with SipHash, and the type class Hashable that a hash map needs of its keys.

- SipHash takes a key of 128 bits, as two Nat64, and a message, and gives 64 bits.
- Without the key an attacker cannot choose many keys of a map that fall on one slot.
- SipHash-1-3 is the variant for hash maps: one round per word and three at the end.
- SipHash-2-4 is slower and meant where the output leaves the programme.
- Two values equal under their type's order must give the same hash under the same key.
- The integer types, Index and String are Hashable here; sipHash13 and sipHash24 never fail.

```
let tag: Nat64 := sipHash24(key0, key1, asSpan(&message));
let slot: Nat64 := hashOf(&name, key0, key1);
```

## Standard.HashMap

A hash map whose keys are hashed with SipHash-1-3 under a key of its own.

- makeHashMap keys a map from the secure random source, so nobody outside can make lookups slow.
- makeHashMapKeyed takes the key from the caller, for a map that behaves the same on every run.
- keyAt and valueAt reach every entry by its position, from 0 to the size less one.
- Removing an entry moves the last one into its place; Standard.Map keeps its entries sorted.
- A key type is Hashable and has a TotalOrder, whose equal decides whether two keys are the same.
- An instance is seen only through an import from Standard.Hash or Standard.Order.

```
var ages: HashMap[Nat64, Nat32] := makeHashMap();
let replaced: Option[Pair[Nat64, Nat32]] := put(&!ages, id, 36);
let age: Option[Nat32] := get(&ages, &id);
destroyFree(ages);
```

## Standard.Html

HTML read into tokens after the tokenizer of the HTML standard, its text taken out, or cleaned.

- A document is the list of its tokens: text, start and end tags, comments and doctypes.
- Tag and attribute names are in small letters; character references are decoded into UTF-8.
- The content of script, style, textarea and title is one text token: a tag in a script is none.
- sanitize keeps only what a policy allows, and drops elements of code, frames and forms whole.
- Other content of an element that is not allowed stays, as escaped text.
- A URL is kept only with the scheme http, https or mailto, or with none.
- sanitize closes every element in the order it was opened, and holds at most 100 open at once.
- The output of sanitize is well formed and escaped, whatever the input was.

```
let clean: String := sanitize(asSpan(&comment), basicPolicy());
let plain: String := textOf(asSpan(&page));
```

## Standard.Htmx

The server side of htmx: its requests told apart, its response headers written, its script served.

- A request is htmx's when its HX-Request header is the four bytes true, and no other value.
- An answer that depends on HX-Request says so with Vary: HX-Request.
- HX-Redirect takes a field value, and HX-Trigger an event name; anything else stops the programme.
- The header lines come out in the form FcgiServer.cgiResponseWith takes.
- The script is read from a file of at most scriptLimit bytes; a missing or larger file gives 404 or 500.

```
if isHtmxRequest(asSpan(&hxRequest)) then
    let line: String := redirectHeader("/done");
    let answer: String := htmlResponse(200, asSpan(&line), "");
end if;
```

## Standard.Http

Questions about an HTTP header block, answered from the text of the block as it stands.

- A block is lines separated by CRLF or a bare LF, ending at the first empty line or at the end.
- Each question takes time linear in the length of the block and keeps nothing of it.
- Header names are compared without regard to case, as RFC 9110 defines them.
- A line without a colon has neither a name nor a value.
- A header value that is a list is read item by item, with white space around each item allowed.

```
let length: Option[String] := headerValue(asSpan(&headers), "Content-Length");
let upgrade: Bool := valueHasToken(asSpan(&connection), "upgrade");
```

## Standard.HttpClient

An HTTPS client: one request, one answer, then the connection is closed.

- Only https URLs are read.
- The server's certificate is verified against the certificates in a file and the host name.
- Every request has a time limit to connect, one for the whole exchange and a limit on size.
- By default a host that is or resolves to a private or reserved address is refused.
- Redirects are not followed: the caller sees the status and the Location header.
- The time taken to resolve the name is not limited, as Standard.Resolve says.

```
let answer: Either[Failure, Response] :=
    request(Get(), "https://example.org/status", "", "", "/etc/ssl/cert.pem", defaultLimits());
```

## Standard.I18n

Translated texts from a catalog that is part of the programme, for templates and for code.

- A key is a case of a union, a language a function with a case over it: an unknown key and a missing one do not compile.
- The language is asked for by its code on every call; nothing is stored, and several tasks may translate at once.
- A code no language has gives the catalog's default language.
- A text holds placeholders {name}, replaced by the arguments; {{ is a brace, and a placeholder without an argument stays as written.
- Plural forms after the six plural categories of Unicode; englishPlural and germanPlural are given, a catalog may bring its own rule.

```
var arguments: Arguments := makeArguments();
addText(&!arguments, "name", "Ada");
let greeting: String := translate(messages(), "de", Greeting(), None(), &arguments);
destroyArguments(arguments);
```

## Standard.IO

The capability to reach the terminal, and the type classes of byte streams.

- A TerminalCapability is linear and comes only from the root capability.
- Standard.IO.Terminal takes it to hand out the standard output, error and input.
- ByteOutputStream writes one byte to a stream at a time.
- ByteInputStream reads one byte at a time, as an Option, so that a stream can end.

```
var terminal: TerminalCapability := acquireTerminal(&!root);
var output: StandardOutput := acquireOutput(&!terminal);
writeByte(&!output, 10);
releaseOutput(output);
releaseTerminal(terminal);
```

## Standard.IO.Terminal

The standard output, the standard error and the standard input of a programme.

- Each stream is linear, acquired through a TerminalCapability and released when done.
- readLine reads up to a carriage return, a line feed or the end of the input.
- readHiddenLine reads a password with the echo off; a signal while it is off leaves it off.
- terminalWidth gives 0 when the width is unknown, which is not a narrow terminal.
- writeErrorText and drainInput return false when the kernel refused.

```
var terminal: TerminalCapability := acquireTerminal(&!root);
var input: StandardInput := acquireInput(&!terminal);
let line: String := readLine(&!input);
releaseInput(input);
releaseTerminal(terminal);
```

## Standard.Ini

Configuration files in the INI form: lines of name = value grouped under [section] headers.

- Names before the first header belong to the section with the empty name.
- A line whose first byte past white space is # or ; is a comment.
- A value that ends with a backslash goes on in the next line.
- Names and values lose the white space around them; a # inside a value is part of it.
- The same name twice in one section: the later one counts.
- Nothing is refused: a line of no known form is skipped and counted by skippedLines.
- A local value wins over a default even when it is empty, which switches the default off.
- A switch is on for yes and true, in any case, and off for everything else.

```
let file: IniFile := readIni(asSpan(&text));
let defaults: IniFile := readIni(asSpan(&shipped));
let port: Option[String] := iniValueWith(&file, &defaults, "server", "port");
let verbose: Bool := iniSwitch(&file, "log", "verbose");
destroyIni(defaults);
destroyIni(file);
```

## Standard.Ip

IP addresses, IPv4 and IPv6: parse, render, mask, match and anonymise.

- An address is a Free value: it copies, compares and sits in a record like a number.
- Nothing here touches the network: no lookup, no socket and no name resolution.
- Parsing is strict and gives None for anything outside the forms each parser names.
- Text comes out in the form RFC 5952 asks for an IPv6 address, and as a dotted quad for IPv4.
- Addresses of different families are never the same and never in one subnet.
- Anonymising cuts an address to its /24 or /48; there is no way back.

```
case parseIp(asSpan(&peer)) of
    when Some(value as address: IpAddress) do
        let inside: Bool := inSubnet(address, office, 24);
        let logged: String := ipToString(anonymise(address));
    when None do
        printLn("not an address");
end case;
```

## Standard.Json

JSON as RFC 8259 defines it, read strictly into a document and written through a writer.

- A text is checked from its first byte to its last when it is read, and the document kept.
- A value is found by a JSON Pointer of RFC 6901; one that leads nowhere gives None.
- A cursor walks the children of an array or object in time linear in its text.
- Reading refuses rather than guesses, and a refusal names the fault and the byte offset.
- A name twice in one object, a lone surrogate and nesting deeper than mostDepth are refused.
- Nothing here aborts on bad input.
- Numbers are kept as the text they were written in; integerAt reads one within Int64.
- A writer puts commas, colons and quotes, and escapes what a string needs.
- A call to a writer out of order spoils it, and finishJson then gives None.

```
var writer: JsonWriter := makeJsonWriter();
beginObject(&!writer);
writeName(&!writer, "id");
writeInteger(&!writer, 42);
endObject(&!writer);
let text: Option[String] := finishJson(writer);

case readJson(asSpan(&body)) of
    when Right(right as document: Json) do
        let id: Option[Int64] := integerAt(&document, "/id");
        destroyJson(document);
    when Left(left as refused: JsonError) do
        printLn(refused.offset);
end case;
```

## Standard.Jws

JSON Web Signatures in the compact form of RFC 7515, JSON Web Keys and OpenID Connect claims.

- Public keys are read from JSON Web Keys after RFC 7517 and RFC 7518.
- The algorithm follows from the kind of the key and nothing else.
- ES256, ES384 and ES512 for P-256, P-384 and P-521, EdDSA for Ed25519, RS256 for RSA.
- ML-DSA-44, ML-DSA-65 and ML-DSA-87 follow the draft of the JOSE working group.
- A token whose header names another algorithm than the key's is refused, and none never holds.
- ECDSA signatures are the two numbers side by side, as RFC 7518 asks, not DER.

```
case verifyWithJwks(asSpan(&token), asSpan(&keySet)) of
    when Some(value as payload: String) do
        let problem: Option[String] :=
            claimsProblem(asSpan(&payload), issuer, clientId, asSpan(&nonce), now, 60);
    when None do
        printLn("token refused");
end case;
```

## Standard.Libcrypto

Authenticated encryption, key agreement, signatures, hashes and secure random bytes.

- Every function calls the system's libcrypto.
- Keys of the ciphers and curves are 32 bytes and nonces 12, 24 for XChaCha20; an HMAC key may have any length.
- A sealed message is the ciphertext followed by a 16-byte tag.
- A wrong input length or a failure of the library gives None or false, without saying which.
- A nonce must never be used twice with one key, and the caller counts them.
- Opening a message whose tag does not match gives None and nothing of the message.
- A code from an HMAC is checked with Standard.Text.constantTimeEqual, never a plain compare.

```
case randomBytes(12) of
    when Some(value as nonce: String) do
        let sealed: Option[String] :=
            sealChaCha20Poly1305(asSpan(&key), asSpan(&nonce), asSpan(&message), "");
        destroyString(nonce);
    when None do
        printLn("no random bytes");
end case;
```

## Standard.Log

Log entries with a level, a message and named fields, one line each.

- A line goes to the standard error, to a file or to the system log.
- A line is text, time=... level=... msg=... and name=value fields, or one JSON object.
- The time is UTC with milliseconds.
- A text value is quoted when it is empty or holds a space, an equals sign, a quote or a backslash.
- In message, names and values a tab or a line feed becomes a space.
- Other C0 and C1 controls, the delete character and malformed UTF-8 become a full stop.
- A byte of a name outside letters, digits and _ . - becomes _.
- A line is written only once it is complete; a log file is opened for appending, with mode 0640.

```
var log: Log := logToError(acquireError(&!terminal), Info(), TextLines());
let entry: Entry := addInteger(makeEntry(Warning(), "slow request"), "millis", millis);
let written: Bool := writeEntry(&!log, entry);
let closed: Bool := closeLog(log);
```

## Standard.Map

A map from keys to values, ordered by the TotalOrder of the keys from Standard.Order.

- A lookup takes O(log n) comparisons; put and remove take time O(n) in the number of entries.
- Entries come in the order of the keys, the same on every run and every platform.
- Keys and values may be linear, and whatever leaves the map comes back to the caller.
- A put over a key the map holds hands back the old key and the old value.
- A map is destroyed only when empty, or when both types are Free.
- A user of String or integer keys imports from Standard.Order, or the call fails with H3061.

```
var stock: Map[Nat64, Nat64] := makeMap();
let old: Option[Pair[Nat64, Nat64]] := put(&!stock, item, 12);
let count: Option[Nat64] := get(&stock, &item);
destroyFree(stock);
```

## Standard.MariaDB

A client for MariaDB through the system's libmariadb, in the form of Standard.Postgres.

- The same types and functions as Standard.Postgres, so Standard.Database holds it as a backend.
- Every connection runs over required TLS, the certificate verified against caFile, name included.
- A statement is prepared; its values are bound to its question marks, apart from its text.
- A timestamp is microseconds since 1970-01-01 UTC, sent as a UTC date and time of years 0 to 9999.
- Columns are read as libmariadb converts them, and a conversion it refuses stops the programme.
- An error carries the MariaDB error number, or one of the negative codes of this module.
- A migration that fails half way is not undone.

```
case openWriter("db.local", 3306, "shop", "app", asSpan(&password), "ca.pem") of
    when Right(right as db: Connection[Writing]) do
        let values: Values := withText(withInt64(noValues(), 7), "apple");
        let changed: Either[MariaError, Nat64] :=
            execute(&!db, "insert into stock (id, name) values (?, ?)", values);
        closeDatabase(db);
    when Left(left as failed: MariaError) do
        printLn(describe(failed));
end case;
```

## Standard.MlDsa

Signs and verifies with ML-DSA of FIPS 204 at the levels 44, 65 and 87.

- A key is made from a seed of 32 bytes, so the same seed always gives the same key.
- Signing is the pure form of FIPS 204 with a context of at most 255 bytes, hedged with 32 random bytes.
- The behaviour is the same on every system: the backend carries its own portable C and SHAKE.
- The seed and the expanded secret key are wiped when the key is destroyed.
- verify gives false for any length that does not fit; it never traps.
- In a task a call needs 256 KiB of stack left, 576 KiB to sign at level 87; with less it gives None or false.

```
let key: Option[MlDsaKey] := generateKeyPair(Level44());
```

## Standard.Normalization

The four normalization forms of Unicode for UTF-8 text, NFD, NFC, NFKD and NFKC.

- The data is that of the Unicode Character Database 17.0.0.
- NFD and NFC keep what a text means and differ only in how its accents are written.
- NFKD and NFKC also fold compatibility variants, such as ligatures, into their plain forms.
- Two texts that should compare equal compare equal byte for byte after the same form.
- Text that is not well-formed UTF-8 is refused with None, not repaired.

```
case toNfc(asSpan(&typed)) of
    when Some(value as normal: String) do
        printLn(asSpan(&normal));
        destroyString(normal);
    when None do
        printLn("not UTF-8");
end case;
```

## Standard.Order

Type classes for partial and total orders, with the total orders of integers and strings.

- Every integer type and Standard.String has a TotalOrder here, for sorts and ordered maps.
- The order of String is byte by byte, unsigned; a prefix comes before the longer string.
- That order knows no locale and no case; for valid UTF-8 it is the order of the code points.
- A module that orders String or integer keys imports something from here to see the instances.

```
case compare(&left, &right) of
    when LessThan do
        printLn("before");
    when Equal do
        printLn("same");
    when GreaterThan do
        printLn("after");
end case;
```

## Standard.Otp

One-time passwords, HOTP after RFC 4226 and TOTP after RFC 6238, as authenticator apps make them.

- A code is the HMAC of a counter under the shared secret, cut to 6 to 8 decimal digits.
- For TOTP the counter is the number of steps since 1970, of 30 seconds as a rule.
- SHA-1 is what the apps use; SHA-256 and SHA-512 are what the RFC adds.
- verifyTotp takes codes of window steps before and after too, and compares in constant time.
- A code once taken is the caller's to remember, so that it is not taken twice.

```
let accepted: Bool :=
    verifyTotp(asSpan(&secret), asSpan(&code), nowSeconds, 30, 6, OtpSha1(), 1);
```

## Standard.Password

Passwords stored as Argon2id hashes in the PHC string form, and checked against them.

- A hash reads $argon2id$v=19$m=65536,t=3,p=4$, then salt, $ and tag in Base64 without padding.
- A new hash takes 65536 kibibytes, 3 passes, 4 lanes, a 16-byte random salt and a 32-byte tag.
- No caller chooses weaker values.
- A stored hash is checked with the values it names, within bounds this module sets.
- The tags are compared in constant time.
- A broken stored string is an answer, Unreadable, never an abort.
- An old bcrypt hash, marked 2a, 2b or 2y, is checked through the system's library, never made.
- A matching bcrypt hash gives MatchesStoreAgain, and the caller stores a new hash.
- A peppered hash reads $argon2id-hmac$v=19$m=65536,t=3,p=4$, then salt, $ and the HMAC-SHA256 of the tag under the pepper.
- A pepper has 32 bytes at least and is kept apart from the stored hashes.

```
let stored: Option[String] := hashPassword(asSpan(&typed));
let check: PasswordCheck := checkPassword(asSpan(&typed), asSpan(&saved));
```

## Standard.Path

Taking a path apart and putting one together, as text.

- No function asks the kernel: every answer is about the string, not about what is there.
- A path is a String; there is no type of its own for it.
- The separator is / and there is no other.
- Nothing normalises: removing .. from a path with a symbolic link changes where it leads.
- A path joined from input is checked with hasParentComponent first, and refused on true.

```
if hasParentComponent(asSpan(&upload)) then
    printLn("refused");
else
    let target: String := joinPath("/var/spool/in", asSpan(&upload));
    let suffix: Option[String] := extension(asSpan(&target));
end if;
```

## Standard.Paths

Where a service or a user tool keeps its configuration, secrets, data, logs and socket on each system.

- A service follows hier(7) on OpenBSD and FreeBSD and the Filesystem Hierarchy Standard on Linux; a user tool the base directories of freedesktop.org, or ~/Library on macOS.
- An app name is 1 to 31 bytes of small letters, digits and hyphens, starting with a letter; its account is _ and the name.
- A path is chosen from the flag, then the variable APP_ENV, APP_PEPPER, APP_CONFIG or APP_SOCKET, then the configuration, then the default.
- A base directory variable that does not hold an absolute path is ignored, as the specification asks.
- The modes are 0600 for the env file and the pepper, 0640 for the configuration, 0660 for the socket, 0750 for directories.
- Nothing is made on the disk; the programme makes what it needs with the modes given here.

```
case choosePath("notes", Service(), PepperFile(), flag, configured) of
    when Some(value as path: String) do
        usePepper(asSpan(&path));
    when None do
        refuse();
end case;
```

## Standard.Pcre

Regular expressions through PCRE2, with its syntax and its engine.

- The names are those of Standard.Regex, but a search here can fail and gives an Either.
- Left when the match limit was reached, when one search needed over 512 MiB, or PCRE2 failed.
- Positions are byte offsets.
- A search does not change a compiled pattern.
- For text from outside the program use Standard.Regex, which runs in linear time.

```
case compile("([a-z]+)@([a-z.]+)", 100000) of
    when Right(right as regex: Regex) do
        let hits: Either[String, Buffer[Hit]] := find_all(&regex, asSpan(&text));
        destroyRegex(regex);
    when Left(left as message: String) do
        printLn(asSpan(&message));
end case;
```

## Standard.PcreJit

Patterns of Standard.Pcre compiled to machine code by the JIT of PCRE2.

- Importing this module is how a program says that it makes machine code at run time.
- Standard.Pcre alone never makes machine code.
- A pattern compiled here is a Regex of Standard.Pcre, searched with the same results.
- When the JIT gives no machine code, the interpreter of PCRE2 searches, and fallBack says why.
- The PCRE2 of Hilde makes machine code without a page writable and executable at once.

```
case compile("[0-9]{4}-[0-9]{2}-[0-9]{2}", 100000) of
    when Right(right as compiled: Compiled) do
        let { regex: Regex, fallBack: Option[String] } := compiled;
        let found: Either[String, Bool] := match(&regex, asSpan(&line));
        destroyRegex(regex);
    when Left(left as message: String) do
        printLn(asSpan(&message));
end case;
```

## Standard.Platform

The system and the machine the programme was compiled for, and the host it runs on.

- The system is linux, openbsd, freebsd, macos, wasi or unknown.
- The machine is x86_64, aarch64, i386, arm, riscv64, ppc64, wasm32 or unknown.
- The system and the machine are fixed when the programme is compiled.
- The host name is asked of the kernel once, the first time, at most 255 bytes, unknown when there is none.

```
print(systemName());
print("/");
printLn(machineName());
```

## Standard.Png

PNG images of 8 bits per channel, written and read.

- An image is width, height, kind of colour and pixels, row after row from the top.
- A pixel is one byte of grey, three of red, green and blue, or four with alpha after them.
- encodePng writes one IDAT chunk and no filter, so the same image gives the same bytes.
- decodePng reads bit depth 8, grey, RGB or RGBA, not interlaced, any of the five filters.
- Every chunk's CRC is checked; ancillary chunks are skipped.
- A critical chunk it does not know, such as a palette, is Unsupported rather than ignored.
- The caller limits the pixels before decompressing, so a small file cannot make a huge image.
- An image is Linear and goes back through destroyImage.

```
case decodePng(asSpan(&data), 4194304) of
    when Right(right as image: Image) do
        let file: String := encodePng(&image);
        destroyImage(image);
    when Left(left as error: PngError) do
        reportBadImage(error);
end case;
```

## Standard.Poller

Waiting on many descriptors at once.

- The backend is epoll on Linux, kqueue on OpenBSD, FreeBSD and macOS, none elsewhere.
- Without a backend createPoller returns None; backendAvailable says so before anything is built.
- A descriptor ready to be read and written comes back as one event with both flags.
- A descriptor is reported only for what it was opened for.
- A pipe's reading end is reported writable only on OpenBSD, which opens both ends both ways.
- Pipes, sockets and character devices can be watched; epoll refuses a regular file.
- The poller owns only its own descriptor; the descriptors it watches stay the caller's.

```
case createPoller() of
    when Some(value as made: Poller) do
        var poller: Poller := made;
        let watched: Bool := watchFile(&!poller, &socket, interestRead);
        let ready: Option[Index] := waitFor(&!poller, 1000);
        let first: Option[Event] := nthEvent(&poller, 0);
        destroyPoller(poller);
    when None do
        useBlockingReads();
end case;
```

## Standard.Postgres

PostgreSQL through the system's libpq, with the types and the shape of Standard.Sqlite.

- Every connection runs over TLS with sslmode verify-full; there is no way to open one without it.
- A value never becomes part of the statement's text: it goes to the server apart, as $1, $2.
- Values and columns travel in the binary form of their type; a text that looks like SQL stays text.
- A column reader of the wrong type stops the programme: that is a mistake in it, not in the data.
- A column that may be null is read with the OrNone reader.
- A reading connection makes every transaction read only, so a write fails on the server as well.
- The whole result arrives with the statement; a span from a column is valid for its row.
- Connection, Transaction, Values and Cursor are Linear and must be ended.

```
case openWriter(host, 5432, "app", "app", asSpan(&password), caFile) of
    when Right(right as made: Connection[Writing]) do
        var db: Connection[Writing] := made;
        let values: Values := withText(withInt64(noValues(), 42), "Ada");
        let insert: Span[Nat8, Static] := "INSERT INTO people (id, name) VALUES ($1, $2)";
        let changed: Either[PgError, Nat64] := execute(&!db, insert, values);
        closeDatabase(db);
    when Left(left as error: PgError) do
        logLine(describe(error));
end case;
```

## Standard.Qr

QR codes of ISO/IEC 18004, model 2, made from text in Hilde.

- The text is one segment: numeric when all digits, else alphanumeric when it can, else bytes.
- The smallest of the 40 versions that holds the text at the level asked for is taken.
- Of the eight masks the one with the lowest penalty is taken, the first of equal ones.
- So the same text at the same level gives the same code on every run.
- A code is a square of dark and light modules, without the quiet zone.
- qrToImage draws a code as an image of Standard.Png and adds the quiet zone.
- A code is Linear and goes back through destroyQr.

```
case encodeQr("https://example.org/ticket/4711", QrMedium()) of
    when Some(value as code: QrCode) do
        let image: Option[Image] := qrToImage(&code, 8, 4);
        destroyQr(code);
        showImage(image);
    when None do
        reportTooLong();
end case;
```

## Standard.Raft

Raft consensus as a state machine of its own: messages and ticks go in, messages and committed entries come out.

- No network, no disk and no clock: the caller sends the messages, stores what must survive and ticks.
- One leader at most in a term; an entry once committed stays in the log of every later leader.
- An entry is committed when quorum of the member count have it and it is of the leader's term.
- quorum is the caller's; majority, more than half, keeps two quorums from missing each other.
- One change of the members at a time, one server added or removed, taking effect when it is in the log.
- A follower that is too far behind gets a snapshot of the state machine instead of the entries.
- The state machine is any type with an instance of StateMachine.

```
var node: Node := newNode(Config(id => 1, electionTicks => 10, heartbeatTicks => 2, seed => 7, quorum => majority), members);
tick(&!node);
let outgoing: Buffer[Message] := takeMessages(&!node);
```

## Standard.RaftTcp

The messages of Standard.Raft over TCP: each one as bytes behind a length of four bytes.

- Every number is written most significant byte first, in a fixed width.
- A frame holds at most frameLimit bytes; a longer length is refused before anything is read.
- decodeMessage takes only bytes that are one well-formed message and nothing after it.
- Every count and length read is checked against the bytes that are really there.
- The connections are Standard.File's: the caller listens, connects, accepts and closes.

```
let sent: Bool := sendMessage(&!socket, &message);
let next: Option[Message] := receiveMessage(&!socket);
```

## Standard.Regex

Regular expressions in linear time.

- Syntax as RE2; each thing it refuses or does differently has a test.
- Time is linear in the length of the input for every pattern.
- Backreferences and lookaround are refused, with a message that names Standard.Pcre.
- A pattern given to compile as a string literal is checked when the programme is compiled.
- A compiled Regex never changes: tasks may search one at once without a lock.
- Positions are byte offsets; matches start and end on UTF-8 boundaries.
- A dot and a class match one code point, not one byte.

```
case compile("^[0-9]+-[0-9]+$") of
    when Right(right as regex: Regex) do
        let isRange: Bool := match(&regex, asSpan(&text));
        destroyRegex(regex);
    when Left(left as message: String) do
        reportPattern(message);
end case;
```

## Standard.Resolve

Host names resolved to addresses through the hosts file and DNS, as the system sets them up.

- A literal address comes back as it is, without asking anyone.
- So does an IPv4 address in its mapped IPv6 form, ::ffff: and four groups.
- Anything else must be a host name by RFC 1123 before it is handed to the resolver.
- An answer holds every address once, in the order the resolver gave them, at most 64.
- The call waits until the resolver answers; a task that resolves keeps its worker meanwhile.

```
case resolveHost("mail.example.org", AnyFamily()) of
    when Right(right as addresses: Buffer[IpAddress]) do
        connectToFirst(addresses);
    when Left(left as failure: ResolveFailure) do
        reportFailure(failure);
end case;
```

## Standard.Resource

The resource limits of the process, what it has used, and how long the system has been up.

- A limit has a soft value, which the kernel enforces, and a hard one.
- The process may raise the soft value up to the hard one.
- Lowering a hard limit cannot be undone without privilege.
- No limit is written as unlimited, the largest Nat64, on every platform.
- A call the kernel refuses returns None or false.

```
let cores: Bool := disableCoreDumps();
case readLimit(OpenFiles()) of
    when Some(value as limit: Limit) do
        let wide: Limit := Limit(soft => limit.hard, hard => limit.hard);
        let raised: Bool := setLimit(OpenFiles(), wide);
    when None do
        skip;
end case;
```

## Standard.Sandbox

Confines the running process to what a policy allows, and says what really confines it.

- A policy names promises in the words of pledge, and paths in the permission letters of unveil.
- On OpenBSD the paths are unveiled, the view locked and the promises pledged, with execpromises.
- A list of paths unveil has no room for applies nothing at all.
- With allowFolding siblings are folded onto their parent and tried again; that widens the view.
- On Linux no new privileges is set and the paths become a Landlock ruleset.
- On Linux a seccomp filter refuses the calls a confined programme has no use for.
- On Linux the promises are checked and not enforced.
- On macOS the programme is started again under a Seatbelt profile of the paths, from its first line.
- On macOS everything before applyPolicy runs twice, the second time confined: apply it first.
- On macOS the promises allow the network, fork and exec as a whole; the rest are not enforced.
- On FreeBSD the paths are opened with their rights and the process enters capability mode.
- On FreeBSD that needs promises without network or exec; with others or none nothing is applied.
- On FreeBSD a path the runtime does not open itself, such as a database's file, is not reachable.
- On Android, on any other platform and in a library nothing is applied: not available.
- The report names each mechanism that took effect, and no other.
- Nothing here stops the programme: what an unconfined run means is the programme's decision.

```
let promised: Policy := allowPromises(makePolicy(), "stdio rpath inet");
let policy: Policy := allowPath(promised, "/var/www", "r");
let report: Report := applyPolicy(policy);
printLine(describeReport(report));
```

## Standard.Search

Full-text search in a database of Standard.Database, with the FTS5 module of SQLite.

- The index is the virtual table hilde_search: a key, a title and a body for each document.
- Only the backends SQLite and SQLCipher have FTS5; prepareSearch refuses the others.
- FTS5 must be built into that library; without it prepareSearch fails with SearchStorageFailed.
- The tokenizer unicode61 finds words without case and diacritics: cafe finds the accented word.
- Hits rank by bm25, a word in the title worth ten in the body, best first.
- A snippet is escaped for HTML, the words found between two markers the caller chooses.
- Typed text never reaches FTS5 as a query: its words become quoted strings that must all be found.
- So no input can name a column, ask for words near each other, use an operator or fail to parse.
- A word that ends in a star finds the words it begins.
- At most 16 words of at most 64 bytes each are taken; the rest is dropped.
- A key is the caller's name of a document, not empty; the table hilde_search_keys gives each key its row.
- So putting a document in and taking it out find its row by an index, in time logarithmic in the documents.
- Both tables are written only through this module: a row written past it has no key the module knows.

```
case search(&!db, asSpan(&typed), 10, 0, "<mark>", "</mark>") of
    when Right(right as hits: Buffer[SearchHit]) do
        renderHits(&hits);
        destroyHits(hits);
    when Left(left as error: SearchError) do
        showNoResults(error);
end case;
```

## Standard.Secret

Passwords and other secrets read from the terminal without echo, held in memory that is wiped when they go.

- readSecret reads from the terminal of the process, never from standard input or an argument.
- The echo is off while the line is typed and nothing is shown in its place.
- A signal that ends or stops the programme while the echo is off finds it switched back on first.
- Without a terminal the answer is NoTerminal at once; nothing waits.
- readSecretFromInput reads standard input, for a flag such as --password-stdin the programme names.
- A secret is linear; destroySecret wipes all its memory, and there is no other way to drop it.
- A secret holds at most 1024 bytes; a longer line is TooLong and is wiped.

```
case readNewSecret("New password: ", "Again: ") of
    when Right(right as secret: Secret) do
        store(secretBytes(&secret));
        destroySecret(secret);
    when Left(left as error: SecretError) do
        refuse(error);
end case;
```

## Standard.Semver

Release versions of the form vX.Y.Z, as git tags carry them, read, written and ordered.

- A version is a small v and three decimal numbers joined by dots, such as v1.12.0; nothing may follow.
- A number has no leading zero, except the number 0 itself, and at most nine digits.
- The order is by major, then minor, then patch, each as a number.
- Reading refuses rather than guesses: anything else gives None, and nothing aborts on bad input.
- A change of the major number is a break; within one major a greater version stays compatible.

```
case parseVersion("v1.4.2") of
    when Some(value as version: Version) do
        let text: String := formatVersion(version);
        printLn(asSpan(&text));
```

## Standard.Session

Server-side sessions in a database of Standard.Database, with an idle and an absolute time limit.

- A session is a row of the table hilde_sessions: digest of its token, times made and used, data.
- The table works on every backend: SQLite, SQLCipher, PostgreSQL and MariaDB.
- A token is 32 secure random bytes as 64 hexadecimal digits, given to the caller once.
- Only the SHA-256 of a token is stored, so a copy of the database opens no session.
- A session idle longer than the idle limit, or older than the absolute one, ends when loaded.
- rotateSession at login gives a new token, so one an attacker set before opens nothing after.
- Every time is seconds passed in by the caller, so a test can move the clock; below 0 is refused.
- A token in a cookie is read back with Standard.Cookie.

```
let limits: SessionLimits := defaultSessionLimits();
case loadSession(&!db, asSpan(&cookieToken), limits, now) of
    when Right(right as found: Option[String]) do
        serveWith(found);
    when Left(left as error: SessionError) do
        reportFailure(error);
end case;
```

## Standard.Setup

The subcommands setup and user of a programme: its vault of secrets, its completion and manual, and its users.

- setup has init, set, get, delete, list, rotate-key, rotate-pepper, completion and manual; user has add, del, passwd and list.
- A secret or a password is read from the terminal without echo, a new one twice; from standard input only with --password-stdin; never from an argument.
- Every read secret is wiped when it is no longer needed.
- runSetup and runUser give the exit status, 0 or 1, and write what went wrong to errors.
- Only a programme that imports this module carries the vault and its cryptography.

```
let setup: SetupKeys := addSetup(&!root);
case parse(&root, &arguments) of
    when Right(right as outcome: Outcome) do
        useOutcome(outcome);
    when Left(left as error: ArgumentError) do
        useError(error);
end case;
```

## Standard.Sftp

SFTP version 3 over the pipes of a child process.

- The child speaks SFTP on its standard input and output: ssh -s for a host, or sftp-server.
- There is no cryptography and no SSH here: OpenSSH keeps the connection, its keys and host checks.
- Every call waits for its reply and checks that the type and the request id are the ones asked for.
- A reply that does not parse or a server gone is a negative code, and spoils the session.
- A spoiled session answers every later call the same, without writing anything.
- The caller gives startSession the milliseconds one whole exchange may last; there is no default.
- An exchange not done in time ends as timedOut, even from a server that sends a byte at a time.
- A timed out session is spoiled and its child is sent SIGTERM, so endSession does not wait.
- Files move in pieces of 32768 bytes; a reply over 256 KiB is refused rather than allocated.

```
case startSession(command, 30000) of
    when Some(value as opened: Session) do
        var session: Session := opened;
        let content: Either[SftpError, String] := readFile(&!session, "/srv/data/report.csv");
        let status: ProcessStatus := endSession(session);
        store(content);
    when None do
        reportNoServer();
end case;
```

## Standard.Shared

State that tasks share: a mutex that guards a value, and an atomic word of 64 bits.

- Tasks reach a shared thing through a read reference lent by a lending scope of Standard.Task.
- A mutex holds one value of any type; acquire moves it out with a key, release takes both back.
- The key is linear: a task that acquired must give it back, and only its own mutex takes it.
- A task that waits for a mutex lets its thread run other tasks.
- A mutex that is never given back ends the programme with the deadlock message of Standard.Task.
- An atomic word is read and changed in one step each.
- Every task sees the changes of one atomic word in one order.

```
let { value as count: Int64, key: Key } := acquire(counter);
release(counter, count + 1, key);
let total: Int64 := atomicAdd(requests, 1);
```

## Standard.SharedCache

A Standard.Cache that tasks share, with one fill per key.

- When several tasks miss the same key at once, one runs the fill and the others wait for its value.
- Tasks reach it through a read reference lent by a lending scope of Standard.Task.
- While a fill runs, other keys stay usable.
- A task that waits for the fill of its key lets the other runnable tasks run meanwhile.
- A clear or flush during a fill keeps its value out, and the next miss fills again.
- A fill that makes no value stores nothing, and the next task that misses fills itself.
- Limits, lifetimes and which entry goes first are those of Standard.Cache.

```
case makeSharedCache(1000, 1048576, 60000000000) of
    when Some(value as cache: SharedCache[Nat64, Nat64]) do
        servePrices(cache);
    when None do
        reportNoMemory();
end case;

let price: Option[Nat64] := getWith(prices, item, nowNanos(), lookUpPrice);
```

## Standard.Signal

Signals taken as events, a time limit for shutting down, and PID files.

- A programme that watches a signal is not ended by it; it asks takeSignal or waits with waitSignal.
- No code of the programme runs when a signal arrives; it sees the signal only when it asks.
- A signal that is not watched keeps its default action.
- A process has one watch at a time; stopWatching gives the signals their default action back.
- After limitShutdown the kernel ends a process whose cleaning up takes longer than the limit.
- Hangup is what a rotation of log files sends; the answer is Standard.Log.reopenLog.

```
let wanted: Wanted := Wanted(hangup => true, interrupt => true, terminate => true,
                             user1 => false, user2 => false);
case watchSignals(wanted) of
    when Some(value as watch: Signals) do
        var signals: Signals := watch;
        while not shutdownRequested(&!signals) do
            let woken: Bool := waitSignal(&!signals, 1000);
        end while;
        let left: Nat32 := limitShutdown(10);
        let restored: Bool := stopWatching(signals);
    when None do
        reportNoWatch();
end case;
```

## Standard.Signify

Keys and signatures in the files of OpenBSD's signify(1): Ed25519, base64, one comment line.

- A file is a line untrusted comment: and the comment, then one line of base64; the key line alone is taken too.
- A public key is 42 bytes, a secret key 104 and a signature 74, each starting with the algorithm Ed.
- Only a secret key without a passphrase is read or written, as signify -G -n makes it; another is refused.
- A secret key's checksum is checked before it signs, and a signature names the key number it needs.
- A signature is over the bytes of the message, detached, as signify -S writes it without -e.
- Reading refuses rather than guesses: a bad file gives None or false, and nothing aborts on bad input.

```
case generateKeys("demo") of
    when Some(value as keys: KeyPair) do
        let { publicKey: String, secretKey: String } := keys;
        case signMessage(asSpan(&secretKey), "text", "verify with demo.pub") of
            when Some(value as signature: String) do
                let good: Bool := verifyMessage(asSpan(&publicKey), "text", asSpan(&signature));
```

## Standard.Smtp

Sending mail through a relay, by the dialogue of RFC 5321 over TLS, with plain messages of RFC 5322.

- TLS is required: from the first byte as RFC 8314 has it for port 465, or by STARTTLS.
- A relay that does not offer STARTTLS is refused, so nobody between the two can strip the offer.
- Cleartext is only for a relay on a loopback address, and never with a login.
- The login is AUTH PLAIN and is sent only over TLS.
- One time limit holds for the whole dialogue.
- Addresses are checked before anything is sent: nothing in them can end a line or a command.
- Addresses with bytes beyond ASCII are refused.
- A failure carries what the relay last said, never the password.

```
case makeRelay("mail.example.org", 587, StartTls(), "/etc/ssl/cert.pem", 30000) of
    when Some(value as relay: Relay) do
        let sent: Either[MailFailure, Unit] := sendMail(&relay, "app", asSpan(&password),
                                                        &envelope, asSpan(&message));
        reportMail(sent);
        destroyRelay(relay);
    when None do
        reportBadHost();
end case;
```

## Standard.Sort

Sorting and searching a buffer whose elements have a total order of Standard.Order.TotalOrder.

- sort takes O(n log n) comparisons in every case and O(n) extra memory.
- sort is stable: equal elements keep their order, so the result depends on the input alone.
- sort moves elements and never copies them, so it sorts linear elements as well as free ones.
- binarySearch takes O(log n) comparisons and does not check that the buffer is sorted.
- A module that sorts Strings or integers imports TotalOrder from Standard.Order, else H3061.

```
let sorted: Buffer[String] := sort(names);
case binarySearch(&sorted, &wanted) of
    when Found(position: Index) do
        showAt(position);
    when Missing(insertAt: Index) do
        offerToAdd(insertAt);
end case;
```

## Standard.Sperli

A job of ranks that send each other messages over TLS 1.3, with the semantics of message passing and none of its interface.

- Every connection is TLS 1.3 with a certificate on both sides from the CA of the job; there is no plain mode.
- The subject of a certificate must be the job and the rank of the peer, and the host must not be one that hostRefused of Standard.SperliWire refuses.
- Each peer shows a join token signed by the launcher, which is checked before any message is taken.
- A message is matched by the rank it comes from and its tag, in the order sent.
- send consumes the buffer; an open send or receive is a linear value that has to be finished.
- barrier, bcast, reduce, allreduce, gather and scatter are the same calls, in the same order, on every rank.
- A reduction runs over the ranks in ascending order, so a result does not depend on timing.
- checkpoint writes the state of every rank to disk with a COMMIT file signed by the launcher key, and resume reads it back after a restart.
- A checkpoint is refused while a send or receive is open, and a state whose type has no Checkpointable instance does not compile.
- Every refusal is a code of Standard.SperliError; the frames are those of Standard.SperliWire and Standard.SperliCollective.

```
let started: Either[Int32, Comm] := init(job);
let sent: Int32 := send(&!comm, 1, 7, message);
let arrived: Int32 := barrier(&!comm);
```

## Standard.SperliCkpt

The files and frame payloads of a Sperli checkpoint: rank files, signed COMMIT files and their place on disk.

- A rank file holds a header of 80 bytes and the state; the header names the job, epoch, rank, size and the SHA-256 of the state.
- A COMMIT file lists the SHA-256 of every rank file and is signed with Standard.CompositeSig; without a valid signature an epoch does not count.
- Every file is written to a temporary name, synced and renamed, so a reader finds a whole file or none.
- The path of a file is the directory, the job as hexadecimal digits, the epoch and the rank.
- A state goes in and out through the type class Checkpointable.
- Every refusal is a code of Standard.SperliError.

```
let file: Option[String] := rankFile(job, 1, 0, 2, asSpan(&state));
let verdict: Int32 := checkCommit(asSpan(&commit), publicKey, job, 1, 2);
```

## Standard.SperliCollective

The bytes of the collective frames of Sperli and the reduction of two arrays of numbers.

- The payload of a collective frame is a header of 16 bytes and the data, least significant byte first.
- checkCollective compares a payload with the call it should answer: operation, type, reduce operation, phase, root and sequence.
- combine reduces two arrays element by element; whole numbers wrap around at their width, and no call traps.
- Float numbers are added and multiplied by the rules of the machine; min and max take the second operand only when it is smaller or larger.
- Logical operations read a whole number as true when it is not 0 and give 0 or 1; bitwise operations work on the bits.
- The time of combine is linear in the length of the arrays.

```
let payload: String := collectivePayload(bcastOperation(), bytesType(), noReduction(), resultPhase(), 0, 1, "data");
let verdict: Int32 := checkCollective(asSpan(&payload), bcastOperation(), bytesType(), noReduction(), resultPhase(), 0, 1);
```

## Standard.SperliError

The codes with which a Sperli job refuses a peer, a frame or a token, and their words.

- A code is a number from 1601 on, written H1601, and names one kind of refusal.
- Zero is no refusal.
- A code is never given to another refusal.
- describe gives a short sentence for every code, and for no other number the empty one.

```
let why: Span[Nat8, Static] := describe(badToken());
```

## Standard.SperliExport

The calls of Standard.Sperli in the shape a C library can export: one session that holds the comm and the last result, and codes instead of Either.

- Every call is one session and plain numbers or bytes; nothing else crosses.
- A call that answers with data keeps it in the session until takeResult hands it on.
- Every call answers with 0 or a code of Standard.SperliError; notReady, resultPending and resultMissing are added.
- A session whose join failed holds the code of the failure and no comm.
- The calls only check what Standard.Sperli would refuse by a contract; the C library checks the rest first.

```
let session: Session := openSession(text);
let sent: Int32 := sessionSend(&!session, 1, 7, message);
```

## Standard.SperliLaunch

The launcher of a Sperli job: reads the host list, makes the keys and certificates of the job, and starts the ranks.

- A host list has one host a line, with an optional port; a line that starts with a hash is a comment.
- A host that hostRefused of Standard.SperliWire refuses is refused even if listed; a deny file only adds names.
- One CA and one pair of keys of Standard.CompositeSig are made for each job, and one certificate and one token for each rank.
- A rank on this machine is started directly, every other rank over ssh at port 62222.
- A rank is told its job on its standard input, as one line of hexadecimal digits.
- The ranks' output is shown, rank by rank, when they have ended.
- With a checkpoint directory the job is started again after a failure, at most restartMax times, and a lost rank goes to the next unused host of the list.

```
let hosts: Either[Int32, HostList] := parseHostList(text, "");
```

## Standard.SperliWire

The bytes of Sperli, the cluster layer: frame headers, hello payloads and join tokens.

- Every number is written least significant byte first, in a fixed width.
- A header is 52 bytes and a payload at most maxPayload bytes; the length is checked before a payload is read.
- checkHeader gives 0 for a frame to take, a code of Standard.SperliError for a frame to refuse.
- A frame of an older incarnation gives staleIncarnation: the caller reads its payload and drops it.
- Only the checkpoint frames carry an epoch; they carry no tag.
- A join token holds the job, rank, size, incarnation, host and expiry, signed with Standard.CompositeSig.
- verifyJoinToken checks the signature first, then the job, the rank, size, incarnation and host, then the expiry.

```
let header: String := frameHeader(dataKind(), 5, job, 1, 0, 0, 1, 7);
let verdict: Int32 := checkHeader(asSpan(&header), job, 1, 1, 0);
```

## Standard.SqlCipher

SQLCipher through the system's libsqlcipher: Standard.Sqlite with the database file encrypted.

- Everything but the key is generated from Standard.Sqlite and keeps its guarantees.
- A programme imports this module or Standard.Sqlite; one that imports both does not compile (H2044).
- The key is a linear Key, consumed by the open and wiped once SQLCipher holds it.
- A wrong key is a Left from the open itself; an empty key is refused.
- openPlainWriter and openPlainReader open a file in SQLite's own format and set no key.

```
case openWriter("app.db", makeKey(secret)) of
    when Right(right as db: Connection[Writing]) do
        closeDatabase(db);
    when Left(left as error: SqlError) do
        printLn(describe(error));
end case;
```

## Standard.Sqlite

SQLite through the system's libsqlite3, with every query checked against the schema at compile time.

- @query and @execute are checked when the programme is compiled, against the migrations' schema.
- SQL outside the accepted forms does not compile, rather than run unchecked.
- The files migrations/1-*.sql, 2-*.sql and on are the schema; migrate applies the new ones.
- migrate runs each file in a transaction of its own and counts in pragma user_version.
- Every table is strict, so SQLite refuses a value of a type the compiler did not assume.
- Writing needs a Connection[Writing]; a write through a Connection[Reading] does not compile.
- In WAL mode one writing and several reading connections work side by side, each in its own task.
- Connection, Transaction and Cursor are linear; a transaction ends only by commit or rollback.
- Text and blob columns are spans into SQLite's memory, valid for one row; copyText copies.
- Prepared statements are kept per connection, keyed by the text of the query, until it closes.
- The functions below Cursor, called by hand with SQL of one's own, run it unchecked.

```
@query(&!db, "SELECT id, name FROM users WHERE age > ?", age)
    for row: User[R] do
        printLn(row.name);
    else error do
        printLn(describe(error));
    end for;
```

## Standard.SqliteReplica

SQLite replicated through Standard.Raft: every write is an entry of the log, applied by every node in the same order.

- A write is one statement whose values are all bound parameters; a quoted literal in it is refused.
- random, randomblob, the current time and date, and a time function given now are refused.
- attach, detach, pragma, vacuum and the statements of transactions are refused; each write is its own.
- A write is checked against the leader's database before it enters the log, as far as that is current.
- The result of a write, its changed rows or SQLite's code, is kept for the last resultLimit entries.
- A local read sees what the node applied; a linearizable read waits for a barrier of the leader's term.
- A snapshot is the database copied with SQLite's online backup.

```
case proposeWrite(&!node, &store, "INSERT INTO kv (k, v) VALUES (?, ?)", &values) of
    when Right(right as index: Nat64) do
        skip;
    when Left(left as refusal: Nat8) do
        skip;
end case;
```

## Standard.SqliteUsers

A store for Standard.Users in an SQLite database of Standard.Sqlite.

- The users are kept in the table hilde_users, the failed attempts in hilde_user_failures.
- openSqliteUsers makes the two tables and their index when they are missing.
- The store holds the connection; closeSqliteUsers gives it back.

```
case openSqliteUsers(db) of
    when Right(right as opened: SqliteUsers) do
        var users: SqliteUsers := opened;
        let added: Either[UserError, Bool] := addUser(&!users, "alice", asSpan(&password));
        closeDatabase(closeSqliteUsers(users));
    when Left(left as failed: SqliteUsersFailed) do
        let { db: Connection[Writing], error: UserError } := failed;
        closeDatabase(db);
end case;
```

## Standard.Ssh

Commands run on another host by the ssh client of OpenSSH, and any child run within a time and size.

- There is no SSH here: the connection, its keys and the check of the host key are left to OpenSSH.
- sshCommand runs ssh in batch mode, with a limit to connect and no terminal: no password is asked.
- The host's key must already be known, so that a new key is a failure and not a question.
- Host and user are checked before they reach ssh, so that neither can be an option of it.
- Each remote word is single-quoted for the remote shell: no word reads as more than one or as code.
- A child that runs longer or writes more than allowed is sent SIGTERM and waited for, and fails.
- Nothing is written to the child: a SIGPIPE would end the programme, not the call.

```
case sshCommand("/usr/bin/ssh", "backup.example.org", "deploy", 22, 10) of
    when Right(right as base: Command) do
        let command: Command := addRemoteWord(addRemoteWord(base, "df"), "-h");
        case runCommand(command, 30000, 65536) of
            when Right(right as result: CommandResult) do
                showResult(result);
            when Left(left as error: SshError) do
                reportFailure(error);
        end case;
    when Left(left as error: SshError) do
        reportFailure(error);
end case;
```

## Standard.String

The String type, a linear byte string on the heap that owns its bytes.

- A String is bytes; nothing here checks that they are UTF-8.
- It is linear: destroyString gives it back.
- Every position is checked, and one out of range stops the programme.
- Making a string aborts when the memory cannot be had.
- A function that only reads text takes a span; asSpan gives all the bytes, even of an empty string.
- A span keeps the reference to its string; fromSpan copies the bytes into a string of their own.

```
var line: String := fromLiteral("hello, world");
storeNth(&!line, 0, 72);
let head: String := fromSpan(getSpan(&line, 0, 4));
let size: Index := length(&line);
destroyString(head);
destroyString(line);
```

## Standard.StringBuilder

A builder that collects bytes at its end and hands them over as one String.

- Each write appends at the end; growing aborts when the memory cannot be had.
- writeString copies the bytes of a span, and an empty span adds nothing.
- finalize hands the collected bytes over as a String without copying them.
- A builder is linear: finalize is the only way to end it.
- Nothing here checks that the bytes are UTF-8.

```
var builder: StringBuilder := makeStringBuilder();
writeString(&!builder, "id=");
writeByte(&!builder, 52);
let line: String := finalize(builder);
```

## Standard.Task

Structured concurrency: tasks that belong to a scope, and channels with two linear ends.

- Tasks run on the threads of the process and may run at the same time.
- spawn moves its argument into the task; it may not hold a reference or a span (H3002).
- A lending scope lets its tasks read what one borrow lends them, checked at the call.
- join is the only thing that consumes a task, and every task must be joined.
- closeScope returns only when every task of the scope has ended.
- A value left in a channel when its receiver closes ends the programme with a message.
- A programme in which every task waits for another ends with a message.
- abort in a task ends the process.

```
var scope: Scope := opened;
case spawn(&!scope, work, 21) of
    when Right(right as task: Task[Int32]) do
        printLn(join(task));
    when Left(left as unused: Int32) do
        printLn(-1);
end case;
closeScope(scope);
```

## Standard.TaskArena

A task that is handed an arena of its own, which ends with the task.

- spawnWithArena makes an arena of at least the capacity asked for and starts the task with it.
- Only arenaAllocate and arenaSpan on that arena take from it; all else is allocated as usual.
- The arena is Linear: the task hands it back with its result and cannot drop it.
- The arena is freed as the task ends, before join sees the result; its used part is overwritten.
- The argument is checked as spawn's is: no reference or span in it, at any depth (H3002).
- Left hands the argument back, untouched, when the arena or the task could not be made.

```
case spawnWithArena(&!scope, work, request, 65536) of
    when Right(right as task: Task[Reply]) do
        answer(join(task));
    when Left(left as unused: Request) do
        refuse(unused);
end case;
```

## Standard.Template

Jinja2 templates, checked when the programme is compiled, and what their generated code calls.

- The syntax is Jinja2's, apart from what is refused or done differently.
- @template reads the file beside the module and writes Hilde code that writes into out.
- Every name comes from page, a reference to one record type; a name it lacks does not compile.
- A value that cannot be printed, or an Option printed unasked, is an error at the template's line.
- Each value is escaped for where it lands: HTML text, attributes, URL parts, JavaScript, CSS.
- A value in a place no escaping makes safe, such as a comment or a tag name, does not compile.
- Only |safe writes a value unescaped, and it can be found with a grep.
- A module that uses @template imports this one, since the instances come with the import.

```
var out: StringBuilder := makeStringBuilder();
@template("page.jinja", page, out);
return finalize(out);
```

## Standard.Testing

Assertions for tests run by hilde test.

- Each assertion prints a line that names what it checks and ends it with ok when it holds.
- A check that fails ends the programme with a message on standard error, and with it the test.
- assertFailure marks a step the test must not reach; assertSuccess one it reached.
- underValgrind is true only under hilde test --valgrind, to allow for its slowdown.

```
assertTrue(isLeapYear(2024), "2024 is a leap year");
assertFalse(isLeapYear(1900), "1900, divided by 100 but not by 400, is not");
```

## Standard.Text

What one does with text: parse it, encode it, compare it and take it apart.

- Standard.String is the container; this module reads text through a Span[Nat8, R].
- Every error is an Option, never a sentinel: nothing here returns -1.
- Nothing traps on bad input: a string that is not a number, or does not fit, is None.
- What is taken apart comes back as spans of the same bytes: nothing is copied.
- What is built is a fresh String that the caller owns.
- Case changes touch ASCII letters only, so they are safe on UTF-8.
- equal stops at the first difference; for secrets use constantTimeEqual.
- A search for a part takes time linear in the lengths of the text and the part.

```
let port: Option[Nat64] := parseNat(trim(asSpan(&field)));
let parts: Buffer[Span[Nat8, Static]] := split("a,b,c", ",");
```

## Standard.Time

A wall clock that says what time it is, and a monotonic clock that says how much time has passed.

- Both clocks read in nanoseconds, as a Nat64.
- The wall clock counts from the epoch and can be set backwards: it is for a time a person reads.
- wallNanos gives zero when the wall clock could not be read.
- The monotonic clock never goes backwards; only the difference of two readings means anything.
- A build without a monotonic clock says so through hasMonotonic, and monotonicNanos gives None.

```
let stamp: Nat64 := wallNanos();
case monotonicNanos() of
    when Some(value as start: Nat64) do
        work();
        report(start);
    when None do
        work();
end case;
```

## Standard.Tls

A TLS client and server, through libtls on OpenBSD and libretls on Debian.

- A client always verifies the server's certificate, against a file of certificates and the host.
- Nothing turns that verification off.
- The forms ending in Tls13 allow TLS 1.3 and nothing older.
- A server of makeServer asks no certificate of its peer.
- A server of makeVerifyingServer refuses every client without a certificate its CA verifies.
- Every failure is a Left with the library's own words after the prefix Standard.Tls and a colon.
- Those words differ between the two libraries.
- The forms with a time limit keep it only on a connection made by connectOver or acceptOver.
- One receive takes at most 16 MiB, whatever count it is asked for.

```
let made: Either[String, Client] := connect("example.org", "443", "/etc/ssl/cert.pem");
let sent: Either[String, Unit] := send(&!client, asSpan(&request));
```

## Standard.Toml

TOML as version 1.0.0 of its specification defines it, read strictly and then asked by path.

- A document is checked from its first byte to its last before any value is read from it.
- A path is the keys from the top down, joined by dots as in TOML, and an array index in brackets.
- The empty path is the whole document; a path that leads nowhere or to another kind gives None.
- Reading refuses rather than guesses: the Left is a TomlFault with its line and column.
- Nothing here aborts on bad input.
- Arrays and inline tables may be nested mostDepth deep, which is 128.
- Integers are kept as Int64, floats and dates and times as the text they were written in.

```
case readToml(asSpan(&text)) of
    when Right(right as parsed: Toml) do
        let port: Option[Int64] := integerAt(&parsed, "servers[1].port");
        destroyToml(parsed);
    when Left(left as error: TomlError) do
        report(error.line, error.column);
end case;
```

## Standard.Tuples

Records of two to six values of any types, with fields named by their position.

- Pair holds two values, Triple three, and Tuple4, Tuple5 and Tuple6 four to six.
- The fields are first, second, third, fourth, fifth and sixth, in that order.
- Every field is public: a tuple is made with named arguments and taken apart with a let.
- A field may be of a Linear type, such as String.

```
let old: Pair[String, Nat64] := Pair(first => word, second => seen);
let { first: String, second: Nat64 } := old;
```

## Standard.Unicode

Upper and lower case of UTF-8 text, and comparison without regard to case.

- The tables are those of the Unicode Character Database, version 17.0.0.
- The mappings are the full ones: the German sharp s maps to two capital letters s.
- A code point maps alone, without rules that look at its neighbours or at a language.
- So the Greek capital sigma always maps to the small sigma, never to the final one.
- The dotted and dotless i of Turkish are not special.
- Text that is not well-formed UTF-8 is refused, not repaired.

```
let shout: Option[String] := toUpper("Gruesse aus Koeln");
let same: Bool := equalIgnoringCase("STRASSE", asSpan(&street));
```

## Standard.UnicodeProperties

Properties of code points from the Unicode Character Database, version 17.0.0.

- It gives the general category, the script, and the orbits of simple case folding.
- An orbit is the code points that fold to the same one.
- Standard.Regex reads its Unicode classes and its case folding from here.
- A code point is an Index; one past U+10FFFF has no property.
- Categories and scripts come back as static text: nothing is allocated for them.

```
let category: Span[Nat8, Static] := generalCategory(65);
var ranges: Buffer[Index] := allocateEmpty();
let known: Bool := appendProperty("Greek", &!ranges);
```

## Standard.Users

User accounts with Argon2id passwords, locks and a limit on failed attempts, over a store the programme chooses.

- A store is any type with an instance of UserStore; Standard.SqliteUsers and Standard.DatabaseUsers are finished ones.
- A name is 1 to 64 bytes of letters, digits, dot, underscore and hyphen, and starts with a letter or digit.
- A password is 1 to 1024 bytes; only its hash from Standard.Password is stored.
- verify answers Rejected alike for an unknown name and a wrong password, and spends a hash on both.
- Locked is answered only to the right password, so a lock tells nothing to who does not know it.
- Failed attempts are counted per client, at most limits.attempts within limits.windowSeconds.
- Every time is seconds passed in by the caller; below 0 is refused.
- No HTTP and no cookie inside; once verify gives Accepted, Standard.Session opens the login.

```
case verify(&!users, "alice", asSpan(&typed), asSpan(&address), limits, now) of
    when Right(right as verdict: Verdict) do
        answer(verdict);
    when Left(left as error: UserError) do
        reportFailure(error);
end case;
```

## Standard.Utf8

UTF-8: decoding it, validating it and building it.

- A CodePoint that exists is a valid scalar value, and makeCodePoint is the only way to make one.
- makeCodePoint refuses a surrogate and anything above U+10FFFF.
- Invalid input is None, never the replacement character: substituting is the caller's to do.
- A stray continuation byte, a cut sequence, a byte from 0xF8 up and an overlong form are refused.
- So an overlong encoding of a slash cannot get past a path check.
- Encoding cannot fail, since every CodePoint is encodable.

```
case makeCodePoint(233) of
    when Some(value as point: CodePoint) do
        appendCodePoint(&!builder, point);
    when None do
        skip;
end case;
let count: Option[Index] := countCodePoints(asSpan(&text));
```

## Standard.Vault

Encrypted secrets in a .env file, readable only with the key in that file and a pepper in a file of its own.

- Each value is sealed with XChaCha20-Poly1305 and signed with HMAC-SHA3-512, in the format of version 0xCC.
- The cipher keys are derived from the key of the .env and the pepper; neither alone reads a value.
- The pepper is exactly 32 bytes; a pepper file of another size is refused.
- Every write replaces the .env atomically with mode 0600, owner and group of the old file kept.
- An open vault holds its cipher keys in a linear value; closeVault overwrites them with zeros.
- A secret's name is A to Z, 0 to 9 and _, not starting with a digit, at most 128 bytes.

```
case openVault("/etc/app/secret/.app.env", "/var/lib/app/.app.pepper", "VAULT_KEY") of
    when Right(right as opened: Vault) do
        var vault: Vault := opened;
        let stored: Either[VaultError, Unit] := setSecret(&!vault, "DB_PASSWORD", "s3cret");
        closeVault(vault);
    when Left(left as error: VaultError) do
        skip;
end case;
```

## Standard.Watch

Watching files and directories for changes: inotify on Linux, kqueue on OpenBSD and FreeBSD.

- A watcher holds any number of watches, numbered from 0 in the order they were added.
- A watch of a directory sees a name made, removed or moved in or out of it.
- A watch of a file sees it written, its attributes changed, and it removed or renamed.
- Replacing a watched file with a rename is seen as well, and a symbolic link is followed.
- A wait says which watch changed, within a time limit, and says less than happened, never more.
- Changes that come together may be reported once: look at what is watched, do not count reports.
- On other platforms watchAvailable is false and makeWatcher gives None.

```
var watcher: Watcher := made;
let config: Option[Index] := watchFile(&!watcher, "/etc/app.conf");
case waitForChange(&!watcher, 5000) of
    when Changed(watch as changed: Index) do
        reload();
    when WaitedOut do
        skip;
    when WatchFailed do
        skip;
end case;
destroyWatcher(watcher);
```

## Standard.X509

Keys and X.509 certificates: made, written, read, signed and verified.

- A key is NIST P-256, P-384 or P-521 with ECDSA, Ed25519, RSA, or ML-DSA of FIPS 204.
- RSA keys have 2048, 3072 or 4096 bits and sign with PKCS 1 v1.5 over SHA-256.
- ML-DSA keys come from Standard.MlDsa on every system, written as PKCS 8 with the seed and the expanded key.
- A certificate or a request with an ML-DSA key is not made: those functions give None.
- A certificate made here has version 3 and a serial number of 127 random bits.
- Its basic constraints and key usage are marked critical, and it carries the key identifiers.
- A leaf made here has the extended key usages of a server and of a client.
- DNS names are one text separated by commas, and a text isDnsNameList refuses is refused.
- A private key is written as unencrypted PEM: whoever holds the text holds the key.

```
let key: Option[PrivateKey] := generateKey(EcP256());
let made: Option[Certificate] := selfSigned(&signer, "web", "example.org", 90, false);
```

## Standard.Xml

XML 1.0 read into tokens, without a document type, and text escaped for it.

- A document must be well formed and valid UTF-8; nothing is repaired.
- Each element gives a start, with its attributes, and an end, an empty one too; text is a token.
- The five predefined entities and every character reference are decoded; CDATA is text.
- Comments, processing instructions and the XML declaration are read and dropped.
- A document type declaration is refused, so no external entity (XXE) and no expansion exists.
- A reference to any entity but the five is refused, and so is nesting deeper than 256.
- Every refusal names the byte offset where reading stopped.

```
case parseXml(asSpan(&text)) of
    when Right(right as parsed: XmlDocument) do
        let feed: Option[Index] := xmlFindStart(&parsed, 0, "feed");
        destroyXmlDocument(parsed);
    when Left(left as error: XmlError) do
        report(error.offset);
end case;
```

## Standard.Yaml

The part of YAML that configuration files use, read into the values of Standard.Json.

- Block mappings, block sequences, plain and quoted scalars and block scalars are read.
- A flow sequence or a flow mapping is read when it ends on its line.
- A plain scalar is null, a boolean, a number as JSON writes one, or else a string, as yes is.
- Anchors, aliases, tags, directives and a second document are refused, not ignored.
- So no small text can expand through aliases into a huge value.
- A tab in the indentation, a scalar over several lines and a key twice in a mapping are refused.
- Nesting deeper than 64 is refused; every refusal names the line where reading stopped.

```
case readYaml(asSpan(&text)) of
    when Right(right as config: Json) do
        apply(config);
    when Left(left as error: YamlError) do
        report(error.line);
end case;
```
