#!/bin/sh
# Hold bindings/fixtures/libpq.h against a REAL libpq-fe.h.
#
#     sh scripts/postgres/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real libpq-fe.h: /usr/include/postgresql on Debian
# with libpq-dev, /usr/local/include/postgresql on OpenBSD with the
# postgresql-client package.  <scratch-dir> is where the small C files of
# the check are written; it must exist, and nothing else in it is touched.
#
# The copy is compiled together with <libpq-fe.h>.  C takes a function
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

[ $# -eq 2 ] || { echo "usage: sh scripts/postgres/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/libpq.h"
[ -r "$inc/libpq-fe.h" ] || { echo "check-header: NOT RUN -- $inc/libpq-fe.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

version=$(sed -n 's/^#define[[:space:]]*PG_VERSION[[:space:]]*"\(.*\)".*$/\1/p' "$inc/pg_config.h" 2> /dev/null)
echo "check-header: header $inc/libpq-fe.h, PostgreSQL ${version:-unknown}"
echo "check-header: copy $copy"

good="$scratch/check-libpq-good.c"
bad="$scratch/check-libpq-bad.c"
badcopy="$scratch/check-libpq-bad.h"

printf '#include <libpq-fe.h>\n#include "%s"\nint main(void) { return 0; }\n' "$copy" > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: PQclear made to return an int.
sed 's/^extern void PQclear(PGresult \*res);$/extern int PQclear(PGresult *res);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <libpq-fe.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (PQclear returning int), cc-exit=$nrc"
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
