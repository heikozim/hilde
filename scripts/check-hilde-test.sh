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
#   contracts-bindings
#                   the same driver on a module that binds C, an unsafe
#                   one: its contracts are drawn and checked, which only
#                   the generated programme may reach.
#   bindings-import a test file imports a Bindings.* module, which ordinary
#                   code may not: its programme is not built, refused with
#                   H2045.  The generated contract programme is the one
#                   exception.
#   contracts-broken, contracts-rejected
#                   a module with three broken functions: all three fail;
#                   the one broken only at the least Int32 is found in the
#                   boundary round that tries it, and the one whose requires
#                   no drawn input meets fails with that reason.
#   contracts-seed  the same seed finds the same input in the same round,
#                   another seed another input, and a run without a seed
#                   prints the one the clock chose and draws from it.
#   contracts-module
#                   --contracts-module narrows the run to the module named:
#                   one result line where the run without the flag has two,
#                   and no line of the module left out.
#   contracts-module-order
#                   the modules are checked in the order the flags name
#                   them, and a name given twice is checked once.
#   contracts-module-unknown
#                   a name that no module with a contract under the paths
#                   holds is refused with H1054, which names the module.
# The fixtures bounds, leak and race also run without an instrument; their
# exit is printed and not judged, because what a plain run makes of a fault
# depends on the system.
#
# The last line counts the controls that held, did not run and failed, and
# the number of controls this file declares.  A run that leaves one out is a
# fault too: a file that lost a control checks less than it says, and what
# it does not check cannot fail.
# Exit 0 no control failed and none is missing, 1 one failed or is missing,
# 9 the check did not run.
# POSIX sh, no bashisms (SH-002): the OpenBSD guest runs it as ksh.
set -u

# How many controls this file runs.  A conflict resolved here by taking one
# side whole keeps the fixtures and drops the controls that read them, and
# the run would then be green while it checks less than this file says.  The
# two guards below are what makes such a run red: the count of the controls
# that ran, and the agreement of the controls with the fixtures.  The number
# changes with every control added or taken out.
EXPECT=27

# The controls that ran -- held, not run and failed -- against the number
# this file declares.  Exit 0 when they are the same number.
count_controls() {
	[ "$(( $1 + $2 + $3 ))" = "$EXPECT" ]
}

# The controls and the fixtures agree: every directory under the fixture
# root is read by a control of <script>, and every fixture a control names
# is there.  One line per fixture that no control reads or that is missing;
# exit 0 when the two sets agree, 1 when they do not.
inventory() {
	root=$1
	script=$2
	faults=0
	for d in "$root"/*/; do
		[ -d "$d" ] || continue
		f=${d%/}
		f=${f##*/}
		grep -Fq -- "\$H/$f" "$script" ||
			{ echo "the fixture $f is read by no control"; faults=$((faults+1)); }
	done
	# A fixture name has no blank in it, and $H is matched as the literal
	# text a control writes, not as this shell's variable.
	# shellcheck disable=SC2013,SC2016
	for f in $(grep -o '\$H/[a-z0-9][a-z0-9-]*' "$script" | sed 's/^\$H\///' | sort -u); do
		[ -d "$root/$f" ] ||
			{ echo "a control reads the fixture $f, which is not there"; faults=$((faults+1)); }
	done
	[ "$faults" = 0 ]
}

# --- the self-test: both guards answer as they must ------------------------
if [ "${1:-}" = --self-test ]; then
	S=${2:-}
	[ -n "$S" ] || { echo "usage: sh scripts/check-hilde-test.sh --self-test <scratch-directory>" >&2; exit 9; }
	case "$S" in /*) ;; *) S=$(pwd)/$S ;; esac
	W=$S/hilde-test-self-test
	[ ! -e "$W" ] || { echo "hilde-test-controls: NOT RUN -- $W exists already"; exit 9; }
	mkdir -p "$W/fixtures/a" "$W/fixtures/b" ||
		{ echo "hilde-test-controls: NOT RUN -- cannot make $W"; exit 9; }
	held=0
	failed=0
	# <label> <exit of the case>: held when that exit is 0.
	case_() {
		if [ "$2" = 0 ]; then
			held=$((held+1))
			echo "hilde-test-self-test: held $1"
		else
			failed=$((failed+1))
			echo "hilde-test-self-test: FAIL $1"
		fi
	}
	# The count: one control fewer than this file declares is refused, the
	# declared number is accepted.
	if count_controls "$((EXPECT-1))" 0 0; then r=1; else r=0; fi
	case_ "one control fewer than the file declares is refused" $r
	count_controls "$EXPECT" 0 0
	case_ "the declared number of controls is accepted" $?
	# The fixtures are named through a variable here, so that no literal
	# "$H/<name>" written in this self-test is read as a fixture of the tree.
	F="\$H"
	# A script that reads both fixtures agrees with them.
	printf '%s\n' "check a 0 - - $F/a" "check b 0 - - $F/b" > "$W/both.sh"
	inventory "$W/fixtures" "$W/both.sh" > "$W/both.out" 2>&1
	case_ "both fixtures are read" $?
	# The same script with the line that reads b taken out leaves b unread:
	# this is what a conflict resolution that drops a control block makes.
	printf '%s\n' "check a 0 - - $F/a" > "$W/one.sh"
	inventory "$W/fixtures" "$W/one.sh" > "$W/one.out" 2>&1
	rc=$?
	[ "$rc" = 1 ] && grep -q 'the fixture b is read by no control' "$W/one.out"
	case_ "a fixture no control reads is named" $?
	# And a control whose fixture is gone is named.
	rmdir "$W/fixtures/b" || exit 9
	inventory "$W/fixtures" "$W/both.sh" > "$W/missing.out" 2>&1
	rc=$?
	[ "$rc" = 1 ] && grep -q 'a control reads the fixture b, which is not there' "$W/missing.out"
	case_ "a fixture a control reads but which is gone is named" $?
	# A fixture whose name holds a digit is read like any other: the names are
	# found in the script's text, and one that a narrower form of the search
	# would miss would be a control the agreement never looks at.
	mkdir -p "$W/fixtures/v2" || exit 9
	printf '%s\n' "check a 0 - - $F/a" "check c 0 - - $F/v2" > "$W/digit.sh"
	inventory "$W/fixtures" "$W/digit.sh" > "$W/digit.out" 2>&1
	case_ "a fixture whose name holds a digit is read" $?
	echo "hilde-test-self-test held=$held failed=$failed"
	[ "$failed" = 0 ] || exit 1
	exit 0
fi

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

# The controls and the fixtures agree.  A control whose fixture a conflict
# resolution dropped takes the fault here, named by the fixture, before any
# control runs and before the count at the end has to stand in for it.
if inventory "$H" "$0" > "$L/hilde-test-inventory.out" 2>&1; then
	echo "hilde-test-inventory=ok every fixture is read and every one named is there"
	held=$((held+1))
else
	echo "hilde-test-inventory=BAD the controls and the fixtures do not agree"
	head -20 "$L/hilde-test-inventory.out"
	bad=$((bad+1))
fi

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

# contracts-bindings: the driver draws the contracts of a Bindings.* module
# too, an unsafe one, whose import ordinary code is refused with H2045.
check contracts-bindings 0 '^ok    Bindings\.Fixture \(contracts\)  1 function$' - --contracts --seed=1 $H/contracts-bindings

# contracts-module: both fixtures hold a module with contracts, so the run
# without the flag checks two modules; the one with the flag checks the
# module it names alone, and no line names the module left out.
check contracts-module-both 0 '^hilde test --contracts: seed=1 rounds=100, 2 module with contracts' - --contracts --seed=1 $H/contracts $H/contracts-bindings
out=$L/hilde-test-contracts-module.out
err=$L/hilde-test-contracts-module.err
./hilde test --contracts --seed=1 --contracts-module=Example.Gauge $H/contracts $H/contracts-bindings > "$out" 2> "$err"
rc=$?
if [ "$rc" = 0 ] && grep -q '^ok    Example\.Gauge (contracts)  3 functions$' "$out" &&
	grep -q '^hilde test --contracts: seed=1 rounds=100, 1 module with contract$' "$out" &&
	! grep -q 'Bindings\.Fixture (contracts)' "$out"; then
	echo "hilde-test-contracts-module=ok exit=$rc"
	held=$((held+1))
else
	echo "hilde-test-contracts-module=BAD exit=$rc (want 0, the line of Example.Gauge, one module, and none of Bindings.Fixture)"
	head -20 "$out"
	head -20 "$err"
	bad=$((bad+1))
fi

# contracts-module-order: the modules are checked in the order the flags
# name them, not in the order the files are found; a name given twice is
# checked once.
out=$L/hilde-test-contracts-module-order.out
err=$L/hilde-test-contracts-module-order.err
./hilde test --contracts --seed=1 --contracts-module=Bindings.Fixture \
	--contracts-module=Example.Gauge --contracts-module=Bindings.Fixture \
	$H/contracts $H/contracts-bindings > "$out" 2> "$err"
rc=$?
if [ "$rc" = 0 ] &&
	[ "$(grep -E '^(ok|FAIL)  .* \(contracts\)' "$out")" = \
	  "$(printf 'ok    Bindings.Fixture (contracts)  1 function\nok    Example.Gauge (contracts)  3 functions')" ] &&
	grep -q '^hilde test --contracts: seed=1 rounds=100, 2 module with contracts' "$out"; then
	echo "hilde-test-contracts-module-order=ok exit=$rc"
	held=$((held+1))
else
	echo "hilde-test-contracts-module-order=BAD exit=$rc (want 0, Bindings.Fixture before Example.Gauge, twice named once)"
	head -20 "$out"
	head -20 "$err"
	bad=$((bad+1))
fi

# contracts-module-unknown: a name that no module with a contract under the
# paths holds is refused, with H1054 and the name, and nothing is checked.
out=$L/hilde-test-contracts-module-unknown.out
err=$L/hilde-test-contracts-module-unknown.err
./hilde test --contracts --seed=1 --contracts-module=Example.Nosuch $H/contracts > "$out" 2> "$err"
rc=$?
if [ "$rc" != 0 ] && grep -q 'Error code: H1054' "$err" && grep -q 'Example\.Nosuch' "$err"; then
	echo "hilde-test-contracts-module-unknown=ok exit=$rc"
	held=$((held+1))
else
	echo "hilde-test-contracts-module-unknown=BAD exit=$rc (want non-zero, H1054 with the name)"
	head -20 "$out"
	head -20 "$err"
	bad=$((bad+1))
fi

# bindings-import: a test file imports a Bindings.* module, ordinary code
# may not, so its programme is not built and the refusal is H2045.
out=$L/hilde-test-bindings-import.out
err=$L/hilde-test-bindings-import.err
./hilde test $H/bindings-import --modules=standard/src:lib/builtin > "$out" 2> "$err"
rc=$?
if [ "$rc" = 1 ] && grep -q 'the test programme did not build' "$out" &&
	grep -q 'Error code: H2045' "$err"; then
	echo "hilde-test-bindings-import=ok exit=$rc"
	held=$((held+1))
else
	echo "hilde-test-bindings-import=BAD exit=$rc (want 1, a not-built line, H2045)"
	head -20 "$out"
	head -20 "$err"
	bad=$((bad+1))
fi

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

# Every control this file declares ran.  A control that is not here any
# more is a fault of the same weight as one that failed: the run checks
# less than it says, and what it does not check cannot fail.
if count_controls "$held" "$notrun" "$bad"; then
	echo "hilde-test-controls held=$held not-run=$notrun bad=$bad of $EXPECT"
else
	echo "hilde-test-controls=BAD $((held+notrun+bad)) controls ran, this file declares $EXPECT"
	bad=$((bad+1))
	echo "hilde-test-controls held=$held not-run=$notrun bad=$bad of $EXPECT"
fi
[ "$bad" = 0 ] || exit 1
[ "$held" -gt 0 ] || exit 1
exit 0
