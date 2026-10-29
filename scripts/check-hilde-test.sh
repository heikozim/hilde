#!/bin/sh
# The controls of hilde test:
# the fixtures of test-programs/hilde-test, each run with the outcome it must
# have, so that a green run of the standard library's tests means something.
#
#     sh scripts/check-hilde-test.sh required|optional <log-directory>
#
# Run from the root of the tree, after the compiler is built (./hilde).
#
# required  every instrument must run (the Linux gate); a refusal is a fault.
# optional  an instrument this system refuses (H1021) is reported NOT RUN with
#           the refusal's words (the OpenBSD gate); one that runs is held to
#           the same controls as on Linux.
#
# What each control holds:
#   pass            both forms of a test pass: exit 0, 2 tests.
#   fail            one test aborts and the other still runs: exit 1,
#                   1 of 2 failed.
#   *-under-*       the clean fixture passes under every instrument, and the
#                   companion test of every fixture below passes beside the
#                   one that must fail -- no instrument reports what is not
#                   there.
#   bounds-memory   a read one element past a buffer: AddressSanitizer, or
#                   where the C compiler is clang, the object-size check of
#                   UndefinedBehaviorSanitizer, which reports a read past a
#                   block of a size it knows before AddressSanitizer is asked.
#   bounds-valgrind the same read: valgrind's invalid read.
#   leak-memory     a buffer never freed: LeakSanitizer.  Where the system
#                   does not support it (FreeBSD says "detect_leaks is not
#                   supported on this platform" and reports nothing), a
#                   programme that loses a buffer is built and run first to
#                   find out, and the control is NOT RUN with that reason: a
#                   green run under AddressSanitizer there is not a leak
#                   check.
#   leak-valgrind   the same buffer: valgrind's definitely lost.
#   race-race       two tasks and one cell without a lock: ThreadSanitizer,
#                   on four workers (HILDE_TASK_THREADS).
#   refused-race, refused-memory
#                   a C compiler that refuses every -fsanitize option with
#                   the words OpenBSD's cc uses, put first on PATH: hilde
#                   test must refuse --race and --memory with H1021 and
#                   those words, run no test and write no result line --
#                   neither a quiet run without the instrument nor a bare
#                   compiler error.
#                   It runs on every system, since the refusal is the
#                   refusing compiler's and not the system's.
#   contracts       hilde test --contracts on a module whose bodies keep
#                   their contracts: exit 0, 3 functions, and the function
#                   that takes a Float64 passed by with its reason.
#   contracts-broken, contracts-rejected
#                   a module with three broken functions: all three fail;
#                   the one broken only at the least Int32 is found in the
#                   boundary round that tries it, and the one whose requires
#                   no drawn input meets fails with that reason.
#   contracts-seed  the same seed finds the same input in the same round,
#                   another seed another input, and a run without a seed
#                   prints the one the clock chose and draws from it.
# The fixtures bounds, leak and race also run without an instrument; their
# exit is printed and not judged, because what a plain run makes of a fault
# depends on the system.
#
# The last line counts the controls that held, did not run and failed.
# Exit 0 no control failed, 1 one failed, 9 the check did not run.
# POSIX sh, no bashisms (SH-002): the OpenBSD guest runs it as ksh.
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/check-hilde-test.sh required|optional <log-directory>" >&2; exit 9; }
mode=$1
L=$2
case "$mode" in
	required|optional) ;;
	*) echo "hilde-test-controls: NOT RUN -- the mode is [$mode], not required or optional"; exit 9;;
esac
[ -d "$L" ] || { echo "hilde-test-controls: NOT RUN -- $L is not a directory"; exit 9; }
[ -x ./hilde ] || { echo "hilde-test-controls: NOT RUN -- ./hilde is not built"; exit 9; }
H=test-programs/hilde-test
[ -d "$H" ] || { echo "hilde-test-controls: NOT RUN -- $H is missing"; exit 9; }
HILDE_TASK_THREADS=4
export HILDE_TASK_THREADS

held=0
notrun=0
bad=0

# check <label> <want-exit> <line the output must hold> <text the output must
# hold, or -> <arguments of hilde test...>
check() {
	label=$1
	want=$2
	line=$3
	text=$4
	shift 4
	out=$L/hilde-test-$label.out
	err=$L/hilde-test-$label.err
	./hilde test "$@" > "$out" 2> "$err"
	rc=$?
	if grep -q 'Error code: H1021' "$err"; then
		why=$(sed -n '/^  Description:/{n;p;}' "$err" | head -1 | sed 's/^ *//')
		if [ "$mode" = optional ]; then
			echo "hilde-test-$label=NOT-RUN refused with H1021: $why"
			notrun=$((notrun+1))
		else
			echo "hilde-test-$label=BAD refused with H1021: $why"
			bad=$((bad+1))
		fi
		return
	fi
	ok=yes
	[ "$rc" = "$want" ] || ok=no
	grep -Eq "$line" "$out" || ok=no
	if [ "$text" != - ]; then
		if ! grep -Fq "$text" "$out"; then
			# alt, when set, is a second text that holds as well.
			if [ -z "${alt:-}" ] || ! grep -Fq "$alt" "$out"; then
				ok=no
			fi
		fi
	fi
	if [ "$ok" = yes ]; then
		echo "hilde-test-$label=ok exit=$rc"
		held=$((held+1))
	else
		echo "hilde-test-$label=BAD exit=$rc (want $want, a line matching [$line] and [$text])"
		head -20 "$out"
		head -20 "$err"
		bad=$((bad+1))
	fi
}

plain() {
	label=$1
	shift
	./hilde test "$@" > "$L/hilde-test-$label-plain.out" 2>&1
	echo "hilde-test-$label-plain-exit=$? (printed, not judged)"
}

check pass 0 '^ok    Example\.Counter\.Test  2 tests$' - $H/pass
check fail 1 '^FAIL  Fail\.Test  1 of 2 tests failed$' 'this test fails on purpose' $H/fail
# Two tests that each make marker.txt: in one working directory the second
# fails, with --fresh-dirs both pass, one after the other and at once.  The
# file the shared run leaves in this directory is removed.
check fresh-shared 1 '^FAIL  Fresh\.Test  1 of 2 tests failed$' 'marker.txt was there before this test' --modules=standard/src $H/fresh
rm -f marker.txt
test -e marker.txt && { echo "hilde-test-fresh-shared=BAD marker.txt is still there"; bad=$((bad+1)); }
check fresh-dirs 0 '^ok    Fresh\.Test  2 tests$' - --modules=standard/src --fresh-dirs $H/fresh
check fresh-dirs-at-once 0 '^ok    Fresh\.Test  2 tests$' - --modules=standard/src --fresh-dirs --test-jobs=2 $H/fresh
test -e marker.txt && { echo "hilde-test-fresh-dirs=BAD marker.txt was made here"; bad=$((bad+1)); }
check pass-test-jobs 0 '^ok    Example\.Counter\.Test  2 tests$' - --test-jobs=2 $H/pass
plain bounds $H/bounds
plain leak $H/leak
plain race --modules=standard/src $H/race
for i in memory valgrind race; do
	check pass-under-$i 0 '^ok    Example\.Counter\.Test  2 tests$' - --$i $H/pass
done
alt='runtime error: load of address'
check bounds-memory 1 '^FAIL  Bounds\.Test  1 of 2 tests failed$' 'ERROR: AddressSanitizer: heap-buffer-overflow' --memory $H/bounds
alt=
check bounds-valgrind 1 '^FAIL  Bounds\.Test  1 of 2 tests failed$' 'Invalid read of size 4' --valgrind $H/bounds

# Whether LeakSanitizer works here: yes, no or unknown, asked of a programme
# that loses a buffer (scripts/lsan-supported.sh).
lsan=$(sh scripts/lsan-supported.sh "$L")
echo "hilde-test-lsan=$lsan (yes: a lost buffer is reported; no: LeakSanitizer is not supported on this system)"
if [ "$lsan" = no ]; then
	if [ "$mode" = optional ]; then
		echo "hilde-test-leak-memory=NOT-RUN LeakSanitizer is not supported on this system: detect_leaks is not supported on this platform, so a run under AddressSanitizer is not a leak check"
		notrun=$((notrun+1))
	else
		echo "hilde-test-leak-memory=BAD LeakSanitizer is not supported on this system"
		bad=$((bad+1))
	fi
else
	check leak-memory 1 '^FAIL  Leak\.Test  1 of 2 tests failed$' 'ERROR: LeakSanitizer: detected memory leaks' --memory $H/leak
fi
check leak-valgrind 1 '^FAIL  Leak\.Test  1 of 2 tests failed$' 'definitely lost' --valgrind $H/leak
check race-race 1 '^FAIL  Race\.Test  1 of 1 test failed$' 'WARNING: ThreadSanitizer: data race' --race --modules=standard/src $H/race
check contracts 0 '^ok    Example\.Gauge \(contracts\)  3 functions$' 'skip  Example.Gauge.scale (its parameter value is not an integer, Index or Bool)' --contracts --seed=1 $H/contracts
check contracts-broken 1 '^FAIL  Example\.Edge \(contracts\)  3 of 3 functions failed$' 'contract-input seed=7 function=Example.Edge.wrap round=3 value=-2147483648' --contracts --seed=7 $H/contracts-broken
check contracts-rejected 1 '^FAIL  Example\.Edge \(contracts\)  3 of 3 functions failed$' 'no input satisfied the requires of exact' --contracts --seed=7 $H/contracts-broken

# contracts-seed: the input edge failed on, in the first drawn round, under
# two runs with seed 7, one with seed 8 and one with the clock's seed.
edge_input() {
	sed -n 's/^ *contract-input seed=\([0-9]*\) function=Example\.Edge\.edge round=3 x=\([0-9]*\)$/\1 \2/p' "$1" | head -1
}
for run in a:7 b:7 c:8 d:; do
	name=${run%%:*}
	seed=${run#*:}
	if [ -n "$seed" ]; then
		./hilde test --contracts "--seed=$seed" $H/contracts-broken > "$L/hilde-test-seed-$name.out" 2>&1
	else
		./hilde test --contracts $H/contracts-broken > "$L/hilde-test-seed-$name.out" 2>&1
	fi
done
a=$(edge_input "$L/hilde-test-seed-a.out")
b=$(edge_input "$L/hilde-test-seed-b.out")
c=$(edge_input "$L/hilde-test-seed-c.out")
d=$(edge_input "$L/hilde-test-seed-d.out")
clock=$(sed -n 's/^hilde test --contracts: seed=\([0-9]*\) .*$/\1/p' "$L/hilde-test-seed-d.out")
if [ -n "$a" ] && [ "$a" = "$b" ] && [ -n "$c" ] && [ "${c#* }" != "${a#* }" ] &&
	[ -n "$clock" ] && [ "${d%% *}" = "$clock" ]; then
	echo "hilde-test-contracts-seed=ok seed 7: [$a] twice, seed 8: [$c], clock: [$d]"
	held=$((held+1))
else
	echo "hilde-test-contracts-seed=BAD seed 7: [$a] [$b], seed 8: [$c], clock seed [$clock]: [$d]"
	bad=$((bad+1))
fi

# refused <label> <flag>: hilde test under a C compiler that refuses the
# sanitizers.  Held: a non-zero exit, H1021 on standard error with the
# compiler's own words as its answer, and not one result line on standard
# output.
realcc=$(command -v cc)
R=$L/hilde-test-refusing-cc
mkdir -p "$R" || { echo "hilde-test-controls: NOT RUN -- cannot make $R"; exit 9; }
{
	echo '#!/bin/sh'
	echo 'for a in "$@"; do'
	echo '	case "$a" in'
	echo "	-fsanitize=*) echo \"cc: error: unsupported option '\$a' for target 'amd64-unknown-openbsd7.9'\" >&2; exit 1;;"
	echo '	esac'
	echo 'done'
	echo "exec $realcc \"\$@\""
} > "$R/cc"
chmod 755 "$R/cc"
refused() {
	label=$1
	flag=$2
	out=$L/hilde-test-$label.out
	err=$L/hilde-test-$label.err
	PATH=$R:$PATH ./hilde test "$flag" $H/pass > "$out" 2> "$err"
	rc=$?
	lines=$(grep -c -E '^(ok|FAIL)  ' "$out")
	why=$(sed -n '/^  Description:/{n;p;}' "$err" | head -1 | sed 's/^ *//')
	answer=$(grep -o "unsupported option '[^']*'" "$err" | head -1)
	if [ "$rc" != 0 ] && grep -q 'Error code: H1021' "$err" &&
		[ -n "$answer" ] && [ "$lines" = 0 ]; then
		echo "hilde-test-$label=ok exit=$rc result-lines=0 said: $why answer: $answer"
		held=$((held+1))
	else
		echo "hilde-test-$label=BAD exit=$rc result-lines=$lines (want non-zero, H1021 with the compiler's words, 0 result lines)"
		head -20 "$out"
		head -20 "$err"
		bad=$((bad+1))
	fi
}
refused refused-race --race
refused refused-memory --memory
echo "hilde-test-controls held=$held not-run=$notrun bad=$bad"
[ "$bad" = 0 ] || exit 1
[ "$held" -gt 0 ] || exit 1
exit 0
