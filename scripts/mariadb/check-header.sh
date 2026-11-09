#!/bin/sh
# Hold bindings/fixtures/mariadb.h against the REAL mysql.h and
# mariadb_stmt.h.
#
#     sh scripts/mariadb/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real mysql.h: /usr/include/mariadb on Debian
# with libmariadb-dev, /usr/local/include/mysql on OpenBSD with the
# mariadb-client package.  <scratch-dir> is where the small C files of
# the check are written; it must exist, and nothing else in it is touched.
#
# The copy is compiled together with <mysql.h>.  C takes a function
# declaration and a typedef twice only when both say the same, so every
# line of the copy that differs from the header stops the compile.  The
# check then proves it CAN stop: a copy of the copy with one return type
# changed must fail.
#
# Exit 0   the copy agrees with the header, and the negative control failed
#          as it must.
# Exit 1   the copy differs from the header.
# Exit 9   did not run: no header, no compiler, or a negative control that
#          passed.  POSIX sh, no bashisms.
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/mariadb/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/mariadb.h"
[ -r "$inc/mysql.h" ] || { echo "check-header: NOT RUN -- $inc/mysql.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

version=$(sed -n 's/^#define[[:space:]]*MARIADB_PACKAGE_VERSION[[:space:]]*"\(.*\)".*$/\1/p' "$inc/mariadb_version.h" 2> /dev/null)
echo "check-header: header $inc/mysql.h, Connector/C ${version:-unknown}"
echo "check-header: copy $copy"

good="$scratch/check-mariadb-good.c"
bad="$scratch/check-mariadb-bad.c"
badcopy="$scratch/check-mariadb-bad.h"

printf '#include <mysql.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: mysql_close made to return an int.
sed 's/^void\([[:space:]]*\)STDCALL mysql_close(MYSQL \*sock);$/int\1STDCALL mysql_close(MYSQL *sock);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <mysql.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (mysql_close returning int), cc-exit=$nrc"
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
