#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The tests of libsperli, from the root of the tree:
#
#     sh scripts/libsperli/check-libsperli.sh [hilde]
#
# Builds the library (scripts/libsperli/build.sh), builds the tool that
# prints the description of a job of one rank, and runs
# libsperli/test/test_sperli.c against the library: every function with
# wrong input must answer its code and the process must live through it.
# A control then removes the check of the tag from a copy of sperli.c and
# demands that the same test fails.  The files made below
# libsperli/c/<target>/ are removed, each by its name, except the library
# and the header.  Exit 0 when every check held, 1 when one failed, 9 when it
# could not run.  POSIX sh.
set -u
HILDE=${1:-./hilde}
[ -x "$HILDE" ] || HILDE=$(command -v hilde) || { echo "check-libsperli: NOT RUN -- no hilde"; exit 9; }
case $(uname -s) in
Linux) T=linux ;;
OpenBSD) T=openbsd ;;
FreeBSD) T=freebsd ;;
Darwin) T=darwin ;;
*) echo "check-libsperli: NOT RUN -- no target for $(uname -s)"; exit 9 ;;
esac
OUT=libsperli/c/$T
W=$OUT/work
ulimit -c 0
failed=0

LIBSPERLI_KEEP_CORE_HEADER=1 sh scripts/libsperli/build.sh "$HILDE" || { echo "check-libsperli: FAIL the build"; exit 1; }
LIBS="-lpthread -ltls -lcrypto -lm"

"$HILDE" compile libsperli/test/Describe.hiq --modules=standard/src:bindings/generated \
	--entrypoint=Libsperli.Describe:main --output="$W/describe" > "$W/describe.log" 2>&1 || { cat "$W/describe.log"; echo "check-libsperli: FAIL the description tool"; exit 1; }
"$W/describe" > "$W/job.txt" || { echo "check-libsperli: FAIL the description tool ran badly"; exit 1; }
cc -std=c11 -Wall -Wextra -Werror -Ilibsperli/include libsperli/test/test_sperli.c "$OUT/libsperli.a" $LIBS -o "$W/test_sperli" \
	|| { echo "check-libsperli: FAIL the test did not compile"; exit 1; }
mkdir "$W/ckpt" || { echo "check-libsperli: NOT RUN -- cannot make the checkpoint directory"; exit 9; }

"$W/test_sperli" "$W/job.txt" "$PWD/$W/ckpt" > "$W/test.out" 2>&1
rc=$?
cat "$W/test.out"
if [ "$rc" = 0 ] && grep -q ' 0 failed' "$W/test.out"; then
	echo "check-libsperli: held the codes of every function, and the process lived"
else
	echo "check-libsperli: FAIL the test (exit $rc)"
	failed=1
fi

# The control: without the check of the tag, the test must fail.
sed 's/tag > SPERLI_MAX_TAG/0/' libsperli/src/sperli.c > "$W/mutant.c"
if cmp -s "$W/mutant.c" libsperli/src/sperli.c; then
	echo "check-libsperli: FAIL the control did not change the source"
	failed=1
else
	cc -std=c11 -w -Ilibsperli/include -I"$W" -c "$W/mutant.c" -o "$W/mutant.o" || { echo "check-libsperli: FAIL the mutant did not compile"; exit 1; }
	cc -std=c11 -Ilibsperli/include libsperli/test/test_sperli.c "$W/mutant.o" "$OUT/libsperli.a" $LIBS -o "$W/test_mutant" \
		|| { echo "check-libsperli: FAIL the control did not link"; exit 1; }
	rm -rf "$W/ckpt-mutant"
	mkdir "$W/ckpt-mutant"
	"$W/test_mutant" "$W/job.txt" "$PWD/$W/ckpt-mutant" > "$W/mutant.out" 2>&1
	rc=$?
	if [ "$rc" = 1 ] && grep -q 'BAD_TAG\|answered' "$W/mutant.out"; then
		echo "check-libsperli: held the control, the test fails without the check of the tag"
	else
		echo "check-libsperli: FAIL the control: the test did not fail (exit $rc)"
		failed=1
	fi
fi

# The files made here, each by its name.
for d in ckpt ckpt-mutant; do
	test -e "$W/$d" && rm -rf "$W/$d"
done
for f in describe describe.log job.txt test_sperli test.out mutant.c mutant.o test_mutant mutant.out libsperli_core.h; do
	test -e "$W/$f" && rm -f "$W/$f"
done
test -e "$W" && rmdir "$W"
exit $failed
