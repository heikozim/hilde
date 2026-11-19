# Building Hilde

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
under valgrind, and `--cppcheck` lets cppcheck read the C of each test
programme first, in the configuration the C compiler builds.  The project's checks run every end-to-end suite and the
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

## Building a library

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
it over.  The host may call from several threads at once.  A library
that uses tasks runs them on worker threads of its own, started at the
first use and joined by `hilde_end` or when the library is unloaded.
Signal handlers are not available in a library.  The tests build one and
call it from C.

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
