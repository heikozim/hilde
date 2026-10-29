# Hilde

Hilde is a small, strict systems language that compiles to C.

It takes its form from Ada: readable keywords, strong types, and a
program that stops rather than carries on in a broken state.

It takes its safety from Rust, but with a simpler rule. Hilde uses linear
types: a value that holds a resource must be used exactly once. Using it
twice is a compile error. Forgetting it is a compile error too.

It takes its size from Go: the whole language is meant to fit in one
person's head.

Hilde is built on Austral by Fernando Borretti, which laid this
foundation. Hilde adds what makes Go pleasant to use every day:
concurrency that is easy to write, and a standard library with regular
expressions, maps, SQLite and SQLCipher, and TLS. There is no garbage
collector, and nothing happens silently.

Hilde is an experiment with one aim: to make coding with AI assistants
safer. The mistakes an AI typically makes are the ones a strict compiler
can catch: a resource that is never closed, a value used after it is
gone, a case that is not handled, a number that silently overflows, an
error that is ignored. In Hilde each of these is a compile error with a
clear message, so the assistant sees its mistake and fixes it. Whether
this works as well as we hope is still to be shown.

## Serving the web

A Hilde programme that serves the web speaks FastCGI on a Unix socket;
it does not face the network itself. The web server in front of it is
[Hiawatha](https://hiawatha.leisink.net/), our preferred web server: it
takes the connections, holds TLS, serves the static files and hands
every other request to the socket. `docs/hiawatha.md` explains what
Hiawatha is and lists the settings a Hilde service needs, with the
reason for each.

[github.com/heikozim/hilde-wolly](https://github.com/heikozim/hilde-wolly) builds on Hilde.
A web framework in Hilde: Web-ready, OpenBSD-first, Linear, Lean, Yours.

## Where Hilde is developed

Hilde is developed in a repository of its own.  This repository is its public
mirror, refreshed from there; it carries the compiler, the standard library, the
tests, the examples and the documentation for the user.  Issues, questions
and patches go to code@heiko-zimmermann.com.

## The name

HILDE stands for High-Integrity, Linear, Deterministic, Explicit. A module
is written as a body in a `.hiq` file and an interface in a `.hih` file,
and the compiler command is `hilde`.

More in `docs/name.md`.

## Documentation

* `docs/syntax.en.md` -- the syntax of Hilde as the compiler reads it.
* `docs/syntax.de.md` -- the same, in German.
* `docs/errors.en.md` -- every error code of the compiler, with its
  message, what it means, a module that fails with it and the correct
  form.
* `docs/errors.de.md` -- the same, in German.
* `docs/standard-library.md` -- every module of the standard library, with
  what it is for and what it guarantees.
* `docs/learning-hilde.md` -- a guide from the first programme on.
* `docs/hilde-traps.md` -- the traps met in writing Hilde, with the wrong
  and the right code.
* `docs/error-codes.md` -- the list of the error codes.
* `docs/differences-from-austral.md` -- where the language Hilde accepts
  differs from the language Austral accepts.
* `docs/unsafe.md` -- the modules of the standard library that may be
  unsafe, and why each one is.
* `docs/hiawatha.md` -- Hiawatha, the web server in front of a Hilde
  service, and the settings it needs.
* `docs/package-manager.en.md` -- packages: hilde get, update, verify,
  export, new, install and doc.
* `docs/package-manager.de.md` -- the same, in German.
* `docs/sperli.en.md` -- Sperli, ranks of one job that send each other
  messages, and its launcher.
* `docs/sperli.de.md` -- the same, in German.
* `docs/sperli-protocol.md` -- the bytes Sperli sends.
* `docs/sperli-protocol.de.md` -- the same, in German.
* `docs/name.md` -- where the name comes from.

## Release archives

A release is `hilde-X.Y.Z.tar.gz`, the tree of this repository at the
release, with `hilde-X.Y.Z.tar.gz.sig`, its signature made by signify(1)
with the key `hilde-1.0.pub` in the root of the repository:

```
signify -V -p hilde-1.0.pub -m hilde-1.0.0.tar.gz
```

## Building

The compiler is written in OCaml.  The steps below build and test it on
Linux, on OpenBSD and on FreeBSD.

On Linux (Debian 13): OCaml 5.5.1 with the packages `hilde.opam` lists,
a C compiler, Python 3 and bash; for the standard library the
development packages `libssl-dev`, `libsqlite3-dev`, `libsqlcipher-dev`,
`libtls-dev` and `libargon2-dev`, and PCRE2.  The tests are run with
PCRE2 10.45 built from its release with the JIT and the allocator that never maps
a page writable and executable at once, which `Standard.PcreJit` needs on a
system that forbids such pages; `libpcre2-dev` serves
`Standard.Pcre` and `Standard.PcreJit` too, with a JIT that maps such pages.

```
make
make test
python3 test-programs/runner.py
bash run-examples.sh
./hilde test standard/src lib/builtin
```

`make` builds the compiler `./hilde`, `make test` runs its unit tests,
`test-programs/runner.py` the end-to-end tests, `run-examples.sh` the
examples, and `hilde test` the standard library's tests: test files named
`*.test.hiq` beside the modules they test, each test in a process of its
own.  `hilde test --memory` runs them under AddressSanitizer and
UndefinedBehaviorSanitizer, `--race` under ThreadSanitizer, `--valgrind`
under valgrind.  The project's checks run every end-to-end suite and the
standard library's tests once under the sanitizers and once under valgrind, and
cppcheck over the generated C, each after controls that it must fail
(`scripts/check-runtime.sh`).

On OpenBSD: OCaml 5.5.1 with the packages `hilde.opam` lists, `gmake`,
Python 3, bash, and the packages `sqlite3`, `pcre2` and `sqlcipher`;
LibreSSL, with libcrypto and libtls, is part of the base system.  Use
`gmake`: `make` is BSD make there, and both Makefiles are GNU make files.

```
gmake
gmake test
python3 test-programs/runner.py
bash run-examples.sh
./hilde test standard/src lib/builtin
```

OpenBSD's C compiler builds no sanitizer and the system has no valgrind,
so `hilde test` refuses `--memory`, `--race` and `--valgrind` there with
the error H1021.

On FreeBSD: the packages `ocaml-opam`, `gmake`, `bash`, `python3`,
`pcre2`, `sqlite3`, `sqlcipher`, `libargon2` and `libretls` (libtls over
the base OpenSSL).  The OCaml of the package catalog is 4.14 and
`hilde.opam` needs 5.1 or later, so opam builds the switch with OCaml
5.5.1 from source, as on OpenBSD.  Use `gmake` here too, and the same five
commands as on OpenBSD.  FreeBSD's C compiler searches `/usr/include` and
`/usr/lib` only and the packages stand under `/usr/local`: hilde finds the
libraries through pkg-config, and the checks name `/usr/local`
for the compilers they start.  The sanitizers, valgrind and cppcheck run
there; LeakSanitizer does not exist on FreeBSD, so valgrind is the leak
check.

### Building a library

Hilde code can be built as a C library for another programme to call: the
functions marked `pragma Foreign_Export(External_Name => "c_name");` are
what it offers.

```
./hilde compile <modules...> --target-type=static --output=libname.a
./hilde compile <modules...> --target-type=shared --output=libname.so
./hilde compile <modules...> --target-type=wasm --output=name.wasm
```

Each writes the header beside the library under its name ending in `.h`.
A module for wasm32-wasi, for a browser or another host of WebAssembly, is
built by zig cc (`HILDE_ZIG`, or `zig` from `PATH`), links no C library,
and exports as well `hilde_wasm_alloc(size)` and `hilde_wasm_free(bytes)`,
with which the host puts what it passes into the module's memory: a span
crosses as an address and a length there.  A static archive
needs the C libraries its header names when it is linked; a shared object
carries them and shows only the exported functions and the runtime's
three: the caller calls `hilde_start()` before the first export and
`hilde_end()` after the last, and may set a handler with
`hilde_set_abort_handler` that is told why the runtime stops, before it
calls abort(3).  A record or union crosses as a handle: one returned
belongs to the caller until it is passed by value to an export that takes
it over.  Tasks and signal handlers are not available in a library.  The tests build
one and call it from C.

For another machine, Android for one, the library starts from its C:

```
./hilde compile <modules...> --target-type=c --no-entrypoint --output=name.c
```

Compiled by that machine's C compiler with `-DHILDE_LIBRARY=1`, `-fPIC`
and `-fvisibility=hidden`, it is the library `shared` builds; the header
comes from a `static` or `shared` build.  It has been built so for Android
arm64 with the NDK, with a Kotlin test that calls every export through JNI,
and on a Mac with Xcode as static libraries for iOS devices and for the
simulator in an XCFramework, with the C caller run in a simulator.

## Origin

Hilde is a fork of [Austral](https://github.com/austral/austral) at
[the commit of 2025-07-29](https://github.com/austral/austral/commit/0962d2a8a5d77f7daacd7f696819520733f4897d). The
license is unchanged: Apache 2.0 with LLVM exception, see `LICENSE`. The
original README is in `docs/austral-README.md`. What differs:
`docs/differences-from-austral.md`.

## Credits

Credits to Fernando Borretti for Austral, the language Hilde is built on.

Austral's design is the foundation of everything here: linear types that
make resource leaks and use-after-free compile errors, capability-based
security, a small and readable specification, and a working compiler that
turned these ideas into running code. Designing a language this carefully,
alone, is a rare piece of work. Hilde would not exist without it.

Thank you for publishing it under a license that lets the work live on.

## License

Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>

Hilde is licensed under the Apache License 2.0 with LLVM exception; see LICENSE.

Austral, on which Hilde is built, is copyright Fernando Borretti, under the
same license.
