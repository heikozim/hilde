#!/bin/sh
# Hold bindings/fixtures/sqlite3.h against a REAL sqlite3.h.
#
#     sh scripts/sqlite/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real header: /usr/include on Debian with
# libsqlite3-dev, /usr/local/include on OpenBSD after `pkg_add sqlite3'.
# <scratch-dir> is where the two small C files of the check are written; it
# must exist, and nothing else in it is touched.
#
# The copy is compiled together with the real header.  C takes a function
# declaration, a typedef and a macro twice only when both say the same, so
# every line of the copy that differs from the header stops the compile.
# The check then proves it CAN stop: a copy of the copy with one return type
# changed must fail (TEST-011) -- a check that passes a wrong copy as well
# checks nothing.
#
# Exit 0   the copy agrees with the header, and the negative control failed
#          as it must.
# Exit 1   the copy differs from the header.
# Exit 9   did not run: no header, no compiler, or a negative control that
#          passed.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/sqlite/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/sqlite3.h"
[ -r "$inc/sqlite3.h" ] || { echo "check-header: NOT RUN -- $inc/sqlite3.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

version=$(sed -n 's/^#define SQLITE_VERSION  *"\(.*\)"$/\1/p' "$inc/sqlite3.h")
echo "check-header: header $inc/sqlite3.h, SQLite ${version:-unknown}"
echo "check-header: copy $copy"

good="$scratch/check-header-good.c"
bad="$scratch/check-header-bad.c"
badcopy="$scratch/check-header-bad.h"

printf '#include <sqlite3.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: sqlite3_step made to return a long long.
sed 's/^SQLITE_API int sqlite3_step(sqlite3_stmt\*);$/SQLITE_API long long sqlite3_step(sqlite3_stmt*);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <sqlite3.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (sqlite3_step returning long long), cc-exit=$nrc"
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
