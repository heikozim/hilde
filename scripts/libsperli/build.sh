#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Builds libsperli for the system it runs on, from the root of the tree:
#
#     sh scripts/libsperli/build.sh [hilde]
#
# The core, Standard.SperliExport, is compiled by hilde as a static library;
# libsperli/src/sperli.c is compiled with warnings as errors; both go into
# libsperli/c/<target>/libsperli.a, and the header libsperli/include/sperli.h
# is copied beside it as libsperli/c/<target>/sperli.h.  <target> is linux,
# openbsd, freebsd or darwin.  The work files are made in a directory below
# the target directory and removed, each by its name.  Exit 0 when built, 1
# when a step failed, 9 when it could not run.  With LIBSPERLI_KEEP_CORE_HEADER
# set, the header hilde wrote for the core stays in the work directory, for
# the check that builds a changed copy of sperli.c; that check removes it.
# POSIX sh.
set -u
HILDE=${1:-./hilde}
[ -x "$HILDE" ] || HILDE=$(command -v hilde) || { echo "libsperli: NOT RUN -- no hilde"; exit 9; }
for tool in cc ar; do
	command -v "$tool" > /dev/null 2>&1 || { echo "libsperli: NOT RUN -- $tool is not on PATH"; exit 9; }
done
[ -f libsperli/src/sperli.c ] || { echo "libsperli: NOT RUN -- run it from the root of the tree"; exit 9; }
case $(uname -s) in
Linux) T=linux ;;
OpenBSD) T=openbsd ;;
FreeBSD) T=freebsd ;;
Darwin) T=darwin ;;
*) echo "libsperli: NOT RUN -- no target for $(uname -s)"; exit 9 ;;
esac
OUT=libsperli/c/$T
W=$OUT/work
mkdir -p "$W/objects" || { echo "libsperli: NOT RUN -- cannot make $W"; exit 9; }

fail() {
	echo "libsperli: FAIL $1"
	exit 1
}

"$HILDE" compile standard/src/SperliExport.hih,standard/src/SperliExport.hiq \
	--modules=standard/src:bindings/generated --target-type=static \
	--output="$W/libsperli_core.a" > "$W/core.log" 2>&1 || { cat "$W/core.log"; fail "the core did not compile"; }
cc -std=c11 -O2 -fPIC -Wall -Wextra -Werror -Ilibsperli/include -I"$W" \
	-c libsperli/src/sperli.c -o "$W/sperli_api.o" || fail "sperli.c did not compile"
(cd "$W/objects" && ar x ../libsperli_core.a) || fail "the core archive did not unpack"
rm -f "$OUT/libsperli.a"
ar rcs "$OUT/libsperli.a" "$W"/objects/*.o "$W/sperli_api.o" || fail "the archive was not made"
cp libsperli/include/sperli.h "$OUT/sperli.h" || fail "the header was not copied"

# The work files, each by its name.
for f in "$W"/objects/*.o; do
	test -e "$f" && rm -f "$f"
done
for f in libsperli_core.a core.log sperli_api.o; do
	test -e "$W/$f" && rm -f "$W/$f"
done
test -e "$W/objects" && rmdir "$W/objects"
if [ -z "${LIBSPERLI_KEEP_CORE_HEADER:-}" ]; then
	test -e "$W/libsperli_core.h" && rm -f "$W/libsperli_core.h"
	test -e "$W" && rmdir "$W"
fi
echo "libsperli: built $OUT/libsperli.a and $OUT/sperli.h"
