#!/bin/sh
# UBSan in trap mode: undefined behaviour stops the programme with a trap,
# with no runtime library.
#
#     sh scripts/check-ubsan-trap.sh <scratch directory> [<not-run file>]
#
# 1. The two controls under scripts/ubsan, built with the flags: each must
#    end with SIGILL (exit status 132).  SIGSEGV (139) is a failure, and so
#    is a normal end: the check did not fire.
# 2. Every end-to-end suite, built with the same flags through
#    HILDE_TEST_CFLAGS; every test must pass.  The not-run file is the
#    platform's, as in the plain run.
#
# On OpenBSD the programmes are linked with --no-execute-only: the function
# check reads the bytes in front of the function it calls, and OpenBSD maps
# code execute-only, so without the flag every indirect call ends in
# SIGSEGV instead of being checked (measured on OpenBSD 7.9 amd64 with a
# hello programme).
#
# Exit 0  all held.  Exit 1  a control or a test failed.  Exit 9  did not
# run.  POSIX sh (SH-002).
set -u
[ $# -ge 1 ] || { echo "usage: sh scripts/check-ubsan-trap.sh <scratch> [<not-run file>]"; exit 9; }
scratch=$1
not_run=${2:-}
[ -d "$scratch" ] || { echo "ubsan-trap: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "ubsan-trap: NOT RUN -- no cc"; exit 9; }
[ -x ./hilde ] || { echo "ubsan-trap: NOT RUN -- ./hilde is not built"; exit 9; }
flags="-fsanitize=undefined -fsanitize-trap=undefined -g -O1"
if [ "$(uname -s)" = OpenBSD ]; then
	flags="$flags -Wl,--no-execute-only"
fi
echo "ubsan-trap: flags=$flags"
bad=0
held=0
for c in trap-overflow trap-function; do
	src=scripts/ubsan/$c.c
	[ -r "$src" ] || { echo "ubsan-trap: NOT RUN -- $src missing"; exit 9; }
	# shellcheck disable=SC2086
	cc -std=c17 $flags "$src" -o "$scratch/$c" > "$scratch/$c.log" 2>&1
	rc=$?
	if [ "$rc" != 0 ]; then
		echo "ubsan-trap: control $c did not build, cc exit $rc:"
		head -5 "$scratch/$c.log"
		bad=$((bad+1))
		continue
	fi
	"$scratch/$c" > /dev/null 2>&1
	rc=$?
	case "$rc" in
		132) echo "ubsan-trap: control $c exit=132 SIGILL (held)"; held=$((held+1)) ;;
		139) echo "ubsan-trap: control $c exit=139 SIGSEGV -- the check crashed instead of trapping"; bad=$((bad+1)) ;;
		*) echo "ubsan-trap: control $c exit=$rc -- no trap"; bad=$((bad+1)) ;;
	esac
	rm -f "$scratch/$c" "$scratch/$c.log"
done
echo "ubsan-trap: controls held=$held of 2"
if [ -n "$not_run" ]; then
	HILDE_TEST_NOT_RUN=$not_run HILDE_TEST_CFLAGS=$flags python3 test-programs/runner.py > "$scratch/ubsan-trap-e2e.log" 2>&1
else
	HILDE_TEST_CFLAGS=$flags python3 test-programs/runner.py > "$scratch/ubsan-trap-e2e.log" 2>&1
fi
rc=$?
pass=$(grep -c ' PASS$' "$scratch/ubsan-trap-e2e.log")
fail=$(grep -c ' FAIL$' "$scratch/ubsan-trap-e2e.log")
echo "ubsan-trap: e2e exit=$rc pass=$pass fail=$fail"
grep ' FAIL$' "$scratch/ubsan-trap-e2e.log" | head -20
[ "$rc" = 0 ] || bad=$((bad+1))
[ "$pass" -gt 0 ] || { echo "ubsan-trap: e2e passed no test"; bad=$((bad+1)); }
if [ "$bad" = 0 ]; then
	echo "ubsan-trap: OK"
	exit 0
fi
echo "ubsan-trap: FAIL ($bad)"
exit 1
