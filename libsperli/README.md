# libsperli

Sperli (Simple Parallel Execution over Remote Links Interface) is the cluster
layer of Hilde: a job of ranks, each a process on a listed host, that send each
other messages with a tag over TLS 1.3.  libsperli is its C library, for
programmes that are not written in Hilde.

- `include/sperli.h` is the public header: the calls, the handle and the codes.
- `src/sperli.c` is the C layer.  It checks every argument and answers a wrong
  one with a code, then calls the core, the Hilde module
  `Standard.SperliExport`.
- `test/` holds the tests: `test_sperli.c` feeds every function wrong input,
  `test_ranks.c` runs ranks against each other, and the Hilde files describe
  jobs for them.

Build and test from the root of the tree:

    sh scripts/libsperli/build.sh
    sh scripts/libsperli/check-libsperli.sh

The library and the header land in `libsperli/c/<target>/`, where `<target>`
is linux, openbsd, freebsd or darwin.  The calls, the codes and the launcher
are described in [docs/sperli.en.md](../docs/sperli.en.md), the bytes on the
wire in [docs/sperli-protocol.md](../docs/sperli-protocol.md).

Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>

SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
