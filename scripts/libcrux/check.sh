#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Holds vendor/libcrux/libcrux_internal.h to the file scripts/libcrux/fetch.sh
# fetches, without a network: its sha256, the revision of libcrux it names,
# and lib/mldsa.c including it exactly once.  Run from the top of the tree.
#
#     sh scripts/libcrux/check.sh
#
# Exit 0 when all three hold, 1 when one does not, 9 when it could not run.
WANT_SHA256=4e5d912e00ac0f585f29d7735fc547d0b7d2ceb134129c1074d3bc4892f79290
WANT_REVISION=c46481ce3cd1cc8315e90db114581d8c992c3d7d
F=vendor/libcrux/libcrux_internal.h
[ -r "$F" ] && [ -r lib/mldsa.c ] || { echo "libcrux-check: NOT RUN -- $F or lib/mldsa.c missing"; exit 9; }
command -v python3 > /dev/null 2>&1 || { echo "libcrux-check: NOT RUN -- no python3"; exit 9; }
got=$(python3 -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$F") || exit 9
good=0
[ "$got" = "$WANT_SHA256" ] && good=$((good+1)) || echo "libcrux-check: BAD sha256 $got, want $WANT_SHA256"
grep -q "Extracted from libcrux revision $WANT_REVISION" "$F" && good=$((good+1)) || echo "libcrux-check: BAD the file names no revision $WANT_REVISION"
n=$(grep -c '^#include "libcrux_internal.h"$' lib/mldsa.c)
[ "$n" = 1 ] && good=$((good+1)) || echo "libcrux-check: BAD lib/mldsa.c includes it $n times"
echo "libcrux-check: held=$good of 3 sha256=$got revision=$WANT_REVISION"
[ "$good" = 3 ] || exit 1
exit 0
