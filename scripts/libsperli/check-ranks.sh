#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# A job of three ranks through libsperli, from the root of the tree:
#
#     sh scripts/libsperli/check-ranks.sh [hilde]
#
# Builds the library (scripts/libsperli/build.sh) and the tool that prints
# the descriptions of a job of three ranks on this host, and runs
# libsperli/test/test_ranks.c against the library: three processes, rank 0
# first and each rank above one second later, join the job through
# sperli_init, pass a barrier and an allreduce, and each must get the sum
# 60.  Rank 0 finds the ranks above not listening yet and waits between its
# tries with the task runtime of the library, which a library could not
# use before; this run shows that it can.  While rank 0 waits in
# sperli_recv on a second thread, a call of its main thread must answer
# SPERLI_E_BUSY.  The files made below
# libsperli/c/<target>/ are removed, each by its name, except the library
# and the header.  Exit 0 when every rank held, 1 when one failed, 9 when it
# could not run.  POSIX sh.
set -u
HILDE=${1:-./hilde}
[ -x "$HILDE" ] || HILDE=$(command -v hilde) || { echo "check-ranks: NOT RUN -- no hilde"; exit 9; }
case $(uname -s) in
Linux) T=linux ;;
OpenBSD) T=openbsd ;;
FreeBSD) T=freebsd ;;
Darwin) T=darwin ;;
*) echo "check-ranks: NOT RUN -- no target for $(uname -s)"; exit 9 ;;
esac
OUT=libsperli/c/$T
W=$OUT/work
umask 077
ulimit -c 0

sh scripts/libsperli/build.sh "$HILDE" || { echo "check-ranks: FAIL the build"; exit 1; }
mkdir -p "$W" || { echo "check-ranks: NOT RUN -- cannot make $W"; exit 9; }
LIBS="-lpthread -ltls -lcrypto -lm"

"$HILDE" compile libsperli/test/mixed/MixedDescribe.hiq --modules=standard/src:bindings/generated \
	--entrypoint=Mixed.Describe:main --output="$W/describe-ranks" > "$W/describe-ranks.log" 2>&1 \
	|| { cat "$W/describe-ranks.log"; echo "check-ranks: FAIL the description tool"; exit 1; }
"$W/describe-ranks" 3 > "$W/job-ranks.txt" || { echo "check-ranks: FAIL the description tool ran badly"; exit 1; }
cc -std=c11 -Wall -Wextra -Werror -D_POSIX_C_SOURCE=200809L -Ilibsperli/include libsperli/test/test_ranks.c \
	"$OUT/libsperli.a" $LIBS -o "$W/test_ranks" || { echo "check-ranks: FAIL the test did not compile"; exit 1; }

"$W/test_ranks" "$W/job-ranks.txt" > "$W/ranks.out" 2>&1
rc=$?
cat "$W/ranks.out"
failed=0
if [ "$rc" = 0 ] && grep -q '^test_ranks: 3 of 3 ranks held$' "$W/ranks.out"; then
	echo "check-ranks: held a job of 3 ranks, each with the allreduce sum 60"
else
	echo "check-ranks: FAIL the job of 3 ranks (exit $rc)"
	failed=1
fi
if grep -q '^rank 0: a call while sperli_recv waited answered -12 ' "$W/ranks.out"; then
	echo "check-ranks: held SPERLI_E_BUSY for a call while another waited"
else
	echo "check-ranks: FAIL no SPERLI_E_BUSY for a call while another waited"
	failed=1
fi

# The files made here, each by its name.  The descriptions hold secret keys.
for f in describe-ranks describe-ranks.log job-ranks.txt test_ranks ranks.out; do
	test -e "$W/$f" && rm -f "$W/$f"
done
test -e "$W" && rmdir "$W"
exit $failed
