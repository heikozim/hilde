#!/bin/sh
# Hold bindings/fixtures/libcrypto.h against REAL OpenSSL headers.
#
#     sh scripts/crypto/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real headers: /usr/include on Debian with
# libssl-dev.  <scratch-dir> is where the two small C files of the check are
# written; it must exist, and nothing else in it is touched.
#
# The copy is compiled together with <openssl/evp.h>,
# <openssl/obj_mac.h>, <openssl/rand.h> and <openssl/hmac.h>.  C takes a function declaration, a typedef and a
# macro twice only when both say the same, so every line of the copy that
# differs from the headers stops the compile.  The check then proves it CAN
# stop: a copy of the copy with one return type changed must fail
# (TEST-011).
#
# Exit 0   the copy agrees with the headers, and the negative control failed
#          as it must.
# Exit 1   the copy differs from the headers.
# Exit 9   did not run: no headers, no compiler, or a negative control that
#          passed.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/crypto/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/libcrypto.h"
[ -r "$inc/openssl/evp.h" ] || { echo "check-header: NOT RUN -- $inc/openssl/evp.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

# LibreSSL defines OPENSSL_VERSION_TEXT as LIBRESSL_VERSION_TEXT, a macro,
# not a string, so both names are read -- the form the gates of Linux and
# OpenBSD use; with the OpenSSL one alone the version would print as
# "unknown" on LibreSSL.
version=$(sed -n -e 's/^#[[:space:]]*define[[:space:]]*LIBRESSL_VERSION_TEXT[[:space:]]*"\(.*\)"$/\1/p' \
	-e 's/^#[[:space:]]*define[[:space:]]*OPENSSL_VERSION_TEXT[[:space:]]*"\(.*\)"$/\1/p' \
	"$inc/openssl/opensslv.h")
echo "check-header: headers $inc/openssl, ${version:-unknown}"
echo "check-header: copy $copy"

good="$scratch/check-header-good.c"
bad="$scratch/check-header-bad.c"
badcopy="$scratch/check-header-bad.h"

printf '#include <openssl/evp.h>\n#include <openssl/obj_mac.h>\n#include <openssl/rand.h>\n#include <openssl/hmac.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against headers, cc-exit=$rc"

# The negative control: EVP_PKEY_free made to return an int.
sed 's/^void EVP_PKEY_free(EVP_PKEY \*pkey);$/int EVP_PKEY_free(EVP_PKEY *pkey);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <openssl/evp.h>\n#include <openssl/obj_mac.h>\n#include <openssl/rand.h>\n#include <openssl/hmac.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (EVP_PKEY_free returning int), cc-exit=$nrc"
rm -f "$good" "$bad" "$badcopy"

if [ "$nrc" = 0 ]; then
	echo "check-header: NOT RUN -- the negative control compiled, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ]; then
	echo "check-header: FAIL -- the copy differs from the headers"
	exit 1
fi
echo "check-header: OK"
exit 0
