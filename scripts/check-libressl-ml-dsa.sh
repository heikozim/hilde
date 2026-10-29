#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Whether the libcrypto of this system offers ML-DSA-44: a name of it in
# the headers of the library, or a symbol of it in the library.  ML-DSA
# comes from the libcrux code the compiler carries as long as LibreSSL
# has none; once it has, the backend of Standard.MlDsa is to move to
# libcrypto and the libcrux code is to go, and the OpenBSD gate turns red
# here until that is done.
#
#     sh scripts/check-libressl-ml-dsa.sh [<include-dir> <library>]
#     sh scripts/check-libressl-ml-dsa.sh --self-test
#
# The defaults are /usr/include/openssl and the newest /usr/lib/libcrypto.so.*.
# Exit 0 when there is no ML-DSA, 1 when there is, 9 when it could not look.
PATTERN='NID_ML_DSA_44|EVP_PKEY_ML_DSA|ML_DSA_44|MLDSA44|mldsa44|ML-DSA-44|ml_dsa_44'

# look <include-dir> <library>: prints what it found, returns 0, 1 or 9.
look() {
	inc=$1
	lib=$2
	[ -d "$inc" ] || { echo "check-libressl-ml-dsa: NOT RUN -- no directory $inc"; return 9; }
	headers=0
	hits=0
	for h in "$inc"/*.h; do
		[ -f "$h" ] || continue
		headers=$((headers+1))
		if grep -E -q "$PATTERN" "$h"; then
			hits=$((hits+1))
			echo "check-libressl-ml-dsa: $h names ML-DSA-44: $(grep -E -m 1 "$PATTERN" "$h")"
		fi
	done
	symbols=0
	if [ -n "$lib" ]; then
		[ -r "$lib" ] || { echo "check-libressl-ml-dsa: NOT RUN -- no library $lib"; return 9; }
		command -v nm > /dev/null 2>&1 || { echo "check-libressl-ml-dsa: NOT RUN -- no nm"; return 9; }
		symbols=$(nm -g "$lib" 2> /dev/null | grep -E -c -i 'ml_?dsa')
	fi
	echo "check-libressl-ml-dsa: headers=$headers header-hits=$hits library=${lib:-none} ml-dsa-symbols=$symbols"
	if [ "$hits" -gt 0 ] || [ "$symbols" -gt 0 ]; then
		echo "LibreSSL kann ML-DSA: Backend auf libcrypto umstellen, libcrux entfernen"
		echo "check-libressl-ml-dsa: libcrypto offers ML-DSA-44; move Standard.MlDsa to libcrypto and remove vendor/libcrux"
		return 1
	fi
	[ "$headers" -gt 0 ] || { echo "check-libressl-ml-dsa: NOT RUN -- no header in $inc"; return 9; }
	return 0
}

if [ "${1:-}" = "--self-test" ]; then
	t=$(mktemp -d "${TMPDIR:-/tmp}/libressl-ml-dsa.XXXXXX") || exit 9
	mkdir "$t/with" "$t/without" || exit 9
	printf '#define NID_ML_DSA_44 1457\n' > "$t/with/obj_mac.h"
	printf '#define NID_ED25519 1087\n' > "$t/without/obj_mac.h"
	look "$t/with" "" > /dev/null; with=$?
	look "$t/without" "" > /dev/null; without=$?
	rm -rf "$t"
	echo "check-libressl-ml-dsa self-test: with=$with (want 1) without=$without (want 0)"
	[ "$with" = 1 ] && [ "$without" = 0 ] || exit 9
	exit 0
fi
inc=${1:-/usr/include/openssl}
if [ $# -ge 2 ]; then
	lib=$2
else
	lib=$(ls /usr/lib/libcrypto.so.* 2> /dev/null | tail -1)
fi
look "$inc" "$lib"
exit $?
