#!/bin/sh
# Hold bindings/fixtures/tls.h against a REAL tls.h.
#
#     sh scripts/tls/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real tls.h: /usr/include on Debian with
# libtls-dev, /usr/include on OpenBSD, where libtls is in the base system.
# <scratch-dir> is where the small C files of the check are written; it must
# exist, and nothing else in it is touched.
#
# The copy is compiled together with <tls.h>.  C
# takes a function declaration, a typedef and a macro twice only when both
# say the same, so every line of the copy that differs from the header --
# a type, a `const', a `void' return, a constant's value -- stops the
# compile.  The check then proves it CAN stop: a copy of the copy with one
# return type changed must fail (TEST-011).
#
# Exit 0   the copy agrees with the header, and the negative control failed
#          as it must.
# Exit 1   the copy differs from the header.
# Exit 9   did not run: no header, no compiler, or a negative control that
#          passed.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/tls/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/tls.h"
[ -r "$inc/tls.h" ] || { echo "check-header: NOT RUN -- $inc/tls.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

api=$(sed -n 's/^#define[[:space:]]*TLS_API[[:space:]]*\([0-9]*\).*$/\1/p' "$inc/tls.h")
echo "check-header: header $inc/tls.h, TLS_API ${api:-?}"
echo "check-header: copy $copy"

good="$scratch/check-tls-good.c"
bad="$scratch/check-tls-bad.c"
badcopy="$scratch/check-tls-bad.h"

printf '#include <tls.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: tls_free made to return an int.
sed 's/^void tls_free(tls_t \*_ctx);$/int tls_free(tls_t *_ctx);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <tls.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (tls_free returning int), cc-exit=$nrc"
rm -f "$good" "$bad" "$badcopy"

if [ "$nrc" = 0 ]; then
	echo "check-header: NOT RUN -- the negative control compiled, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ]; then
	echo "check-header: FAIL -- the copy differs from the header"
	exit 1
fi
echo "check-header: OK"
exit 0
