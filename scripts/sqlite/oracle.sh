#!/bin/sh
# The oracle for the end-to-end tests of Standard.Sqlite: the sqlite3
# command-line shell runs a test's migrations and then its oracle.sql, the
# same statements the test's Hilde programme runs, with the values written
# in.  Its output is compared line by line with the programme's.
#
#     sh scripts/sqlite/oracle.sh <test-dir> <out-file>
#
# Runs where the sqlite3 shell is -- on a host, not in the gate
# image, which has only the library.  An in-memory database; nothing is
# written but <out-file>.
#
# Exit 0 the shell ran (its own errors are part of the output, on purpose:
# a statement that fails is a line to compare), 9 did not run.  POSIX sh,
# no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/sqlite/oracle.sh <test-dir> <out-file>" >&2; exit 9; }
dir=$1
out=$2
command -v sqlite3 > /dev/null 2>&1 || { echo "oracle: NOT RUN -- no sqlite3 shell" >&2; exit 9; }
[ -r "$dir/oracle.sql" ] || { echo "oracle: NOT RUN -- no $dir/oracle.sql" >&2; exit 9; }
[ -d "$dir/migrations" ] || { echo "oracle: NOT RUN -- no $dir/migrations" >&2; exit 9; }

script="$out.script"
{
	echo ".bail off"
	echo ".headers off"
	echo ".mode list"
	# The migrations in the order of their numbers, as @migrations takes
	# them: 1-..., 2-..., 10-... after 9-....
	for f in $(ls "$dir/migrations" | grep '^[0-9][0-9]*-.*\.sql$' | sort -n); do
		echo ".read $dir/migrations/$f"
	done
	echo ".read $dir/oracle.sql"
} > "$script"
sqlite3 :memory: < "$script" > "$out" 2>&1
rc=$?
rm -f "$script"
echo "oracle: sqlite3 $(sqlite3 --version | cut -d' ' -f1) exit=$rc lines=$(wc -l < "$out" | tr -d ' ') -> $out"
exit 0
