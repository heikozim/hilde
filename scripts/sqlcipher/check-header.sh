#!/bin/sh
# Hold bindings/fixtures/sqlcipher.h -- SQLite's copy and sqlite3_key -- against
# a REAL SQLCipher header.
#
#     sh scripts/sqlcipher/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds SQLCipher's sqlite3.h: /usr/include/sqlcipher on
# Debian with libsqlcipher-dev, /usr/local/include/sqlcipher on OpenBSD with
# the sqlcipher package.  <scratch-dir> is where the small C files of the
# check are written; it must exist, and nothing else in it is touched.
#
# SQLCipher declares sqlite3_key only under SQLITE_HAS_CODEC, which its
# pkg-config flags do not set; the check sets it so that the declaration is
# there to be compared.  C accepts a declaration twice only when both say
# the same, so a line of the copy that differs from the header stops the
# compile.  The negative control changes sqlite3_key to return long long
# and must fail (TEST-011).
#
# Exit 0 the copy agrees, the negative control failed as it must; 1 the
# copy differs; 9 did not run.  POSIX sh (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/sqlcipher/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/sqlcipher.h"
[ -r "$inc/sqlite3.h" ] || { echo "check-header: NOT RUN -- $inc/sqlite3.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }
grep -q 'sqlite3_key(' "$inc/sqlite3.h" || { echo "check-header: NOT RUN -- $inc/sqlite3.h declares no sqlite3_key: not SQLCipher's"; exit 9; }

version=$(sed -n 's/^#define SQLITE_VERSION  *"\(.*\)"$/\1/p' "$inc/sqlite3.h")
echo "check-header: header $inc/sqlite3.h, SQLite ${version:-unknown} (SQLCipher)"
echo "check-header: copy $copy"

good="$scratch/check-sqlcipher-good.c"
bad="$scratch/check-sqlcipher-bad.c"
badcopy="$scratch/check-sqlcipher-bad.h"

printf '#define SQLITE_HAS_CODEC 1\n#include <sqlite3.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" -I"$here/bindings/fixtures" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: sqlite3_key made to return a long long.  The copy
# of the copy lies in the fixtures directory's place, so it has to find
# "sqlite3.h" there: -I of the fixtures directory is given above and below.
sed 's/^SQLITE_API int sqlite3_key($/SQLITE_API long long sqlite3_key(/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#define SQLITE_HAS_CODEC 1\n#include <sqlite3.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" -I"$here/bindings/fixtures" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (sqlite3_key returning long long), cc-exit=$nrc"
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
