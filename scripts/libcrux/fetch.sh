#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Fetches libcrux_internal.h again from openssh-portable at the commit
# below, into vendor/libcrux, and holds it to the sha256 scripts/libcrux/check.sh
# keeps.  OpenSSH extracts the file from libcrux with its mlkem_mldsa.sh;
# this script takes OpenSSH's file as it is.  To move to another commit,
# change OPENSSH_COMMIT here and WANT_SHA256 and WANT_REVISION in check.sh
# in the same commit, after reading the difference.  It needs git and the
# network; nothing else of the tree uses either.
#
#     sh scripts/libcrux/fetch.sh
#
# Exit 0 when the fetched file is the one check.sh holds, 1 when it differs
# (it is left beside the vendored one as .fetched), 9 when it could not run.
OPENSSH_REPO=https://github.com/openssh/openssh-portable.git
OPENSSH_COMMIT=26b1363c7cbf5d01c730f45fc0b4abc5686beaf7
[ -r scripts/libcrux/check.sh ] || { echo "libcrux-fetch: NOT RUN -- run from the top of the tree"; exit 9; }
command -v git > /dev/null 2>&1 || { echo "libcrux-fetch: NOT RUN -- no git"; exit 9; }
t=$(mktemp -d "${TMPDIR:-/tmp}/libcrux-fetch.XXXXXX") || exit 9
git -C "$t" init -q && git -C "$t" fetch -q --depth 1 "$OPENSSH_REPO" "$OPENSSH_COMMIT" \
	&& git -C "$t" show "FETCH_HEAD:libcrux_internal.h" > "$t/libcrux_internal.h" \
	|| { rm -rf "$t"; echo "libcrux-fetch: NOT RUN -- the fetch failed"; exit 9; }
if cmp -s "$t/libcrux_internal.h" vendor/libcrux/libcrux_internal.h; then
	rm -rf "$t"
	echo "libcrux-fetch: the file of $OPENSSH_COMMIT is the vendored one"
	sh scripts/libcrux/check.sh
	exit $?
fi
cp "$t/libcrux_internal.h" vendor/libcrux/libcrux_internal.h.fetched
rm -rf "$t"
echo "libcrux-fetch: the file of $OPENSSH_COMMIT differs; it is vendor/libcrux/libcrux_internal.h.fetched"
exit 1
