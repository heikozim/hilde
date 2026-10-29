#!/bin/sh
# Hold bindings/fixtures/pcre2.h against a REAL pcre2.h.
#
#     sh scripts/pcre/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real pcre2.h: /usr/include on Debian with
# libpcre2-dev, /usr/local/include on OpenBSD with the pcre2 package.
# <scratch-dir> is where the small C files of the check are written; it must
# exist, and nothing else in it is touched.
#
# The copy is compiled together with <pcre2.h>, PCRE2_CODE_UNIT_WIDTH 8.  C
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

[ $# -eq 2 ] || { echo "usage: sh scripts/pcre/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/pcre2.h"
[ -r "$inc/pcre2.h" ] || { echo "check-header: NOT RUN -- $inc/pcre2.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

major=$(sed -n 's/^#define[[:space:]]*PCRE2_MAJOR[[:space:]]*\([0-9]*\).*$/\1/p' "$inc/pcre2.h")
minor=$(sed -n 's/^#define[[:space:]]*PCRE2_MINOR[[:space:]]*\([0-9]*\).*$/\1/p' "$inc/pcre2.h")
echo "check-header: header $inc/pcre2.h, PCRE2 ${major:-?}.${minor:-?}"
echo "check-header: copy $copy"

good="$scratch/check-pcre2-good.c"
bad="$scratch/check-pcre2-bad.c"
badcopy="$scratch/check-pcre2-bad.h"

printf '#define PCRE2_CODE_UNIT_WIDTH 8\n#include <pcre2.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: pcre2_code_free_8 made to return an int.
sed 's/^void pcre2_code_free_8(pcre2_code_8 \*code);$/int pcre2_code_free_8(pcre2_code_8 *code);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#define PCRE2_CODE_UNIT_WIDTH 8\n#include <pcre2.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (pcre2_code_free_8 returning int), cc-exit=$nrc"
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
