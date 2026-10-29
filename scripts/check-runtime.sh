#!/bin/sh
# The runtime checks of the gates: every end-to-end
# suite once under AddressSanitizer and UndefinedBehaviorSanitizer and once
# under valgrind, the standard library's tests under both through hilde
# test, and cppcheck over the generated C -- each after the controls that
# show it can see what it is there to see.
#
#     sh scripts/check-runtime.sh required|optional <log-directory> [<not-run file>]
#
# Run from the root of the tree, after the compiler is built (./hilde).
#
# required  every check must run (the Linux gate); one that cannot is a fault.
# optional  a check this system cannot run is reported NOT RUN with the
#           reason the system gives (the OpenBSD gate); one that runs is held
#           to the same rules as on Linux.
#
# What is held:
#   e2e-memory        the suites under the sanitizers: exit 0, no test fails,
#                     the tests of test-programs/not-run-memory.txt NOT RUN
#                     and no other.
#   e2e-memory-sandbox  the sandbox suite again with detect_leaks=0: the
#                     leak check cannot run inside the programme's sandbox.
#   controls-memory   test-programs/controls under the sanitizers: the clean
#                     control passes; the read past a buffer, the lost buffer,
#                     the misaligned load and the buffer given back twice
#                     each fail with the report that names its fault.
#   e2e-valgrind      the suites under valgrind, with
#                     test-programs/not-run-valgrind.txt.
#   controls-valgrind the clean control passes; the read past a buffer, the
#                     lost buffer and the buffer given back twice each fail
#                     with valgrind's report.  The
#                     misaligned load is printed and not judged: valgrind does
#                     not look at alignment.
#   lib-memory, lib-valgrind  hilde test --memory and --valgrind over the
#                     library: exit 0, every test file built and passed.
#   examples-memory, examples-valgrind  the programmes of the example lines
#                     of run-examples.sh through
#                     scripts/check-examples.py, built with the same
#                     flags as the suites: each ends as its line says, with
#                     its output, an empty standard error, and nothing left
#                     in its directory.
#   examples-memory-sandbox  the examples that confine themselves,
#                     learn-sandbox, learn-files, learn-arguments, learn-log
#                     and learn-poller, under the sanitizers with
#                     detect_leaks=0, as for e2e-memory-sandbox and for the
#                     same reason; their leaks are held by examples-valgrind.
#   e2e-ubsan-trap    the suites under UndefinedBehaviorSanitizer in trap
#                     mode (-fsanitize-trap=undefined), which needs no
#                     runtime library: exit 0, no test fails, the tests of
#                     test-programs/not-run-ubsan-trap.txt NOT RUN.
#   controls-ubsan-trap  the clean control passes; the misaligned load ends
#                     by the trap's signal, SIGILL or SIGTRAP.
#   e2e-malloc, lib-malloc  only on OpenBSD: the suites and the library's
#                     tests with MALLOC_OPTIONS=S, every check of malloc(3).
#   controls-malloc   the clean control passes; the buffer given back twice
#                     fails with malloc's report of a double free.
#   e2e-optimised     only where the sanitizers cannot run: the suites once
#                     with -O1, the optimisation the sanitizer run carries,
#                     so that the generated C is still built optimised there.
#                     The tests of the third argument, the system's own
#                     not-run file, are NOT RUN and no other: a test the
#                     system's plain run leaves out cannot run here either.
#   cppcheck          cppcheck over the frame of scripts/count-warnings.sh,
#                     in the configuration the C compiler sees, with the
#                     suppressions of scripts/cppcheck-suppressions.xml and
#                     their reasons, and the inline ones around the text of
#                     ML-DSA in lib/mldsa.c: no finding.  Its controls: a file with a
#                     read past an array must be reported, a clean one not.
#
# The last line counts the checks that held, did not run and failed.
# Exit 0 no check failed, 1 one failed, 9 the checks did not run.
# POSIX sh, no bashisms (SH-002): the OpenBSD guest runs it as ksh.
set -u

[ $# -eq 2 ] || [ $# -eq 3 ] || { echo "usage: sh scripts/check-runtime.sh required|optional <log-directory> [<not-run file>]" >&2; exit 9; }
mode=$1
L=$2
system_not_run=${3:--}
case "$mode" in
	required|optional) ;;
	*) echo "runtime-checks: NOT RUN -- the mode is [$mode], not required or optional"; exit 9;;
esac
[ -d "$L" ] || { echo "runtime-checks: NOT RUN -- $L is not a directory"; exit 9; }
[ -x ./hilde ] || { echo "runtime-checks: NOT RUN -- ./hilde is not built"; exit 9; }
[ "$system_not_run" = - ] || [ -r "$system_not_run" ] ||
	{ echo "runtime-checks: NOT RUN -- the not-run file $system_not_run cannot be read"; exit 9; }
for f in test-programs/runner.py test-programs/not-run-memory.txt test-programs/not-run-valgrind.txt test-programs/not-run-ubsan-trap.txt \
	test-programs/controls scripts/cppcheck-suppressions.xml scripts/count-warnings.sh \
	scripts/check-examples.py run-examples.sh; do
	[ -e "$f" ] || { echo "runtime-checks: NOT RUN -- $f is missing"; exit 9; }
done
for t in python3 cc; do
	command -v "$t" >/dev/null 2>&1 || { echo "runtime-checks: NOT RUN -- $t is not on PATH"; exit 9; }
done

MEM="-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -g -O1"
# The tests that expect a fault die by the signal itself, not by a report of
# the sanitizer.  A write to a page without access is SIGSEGV on Linux and
# the BSDs and SIGBUS on macOS; both are left to the system.
AO="exitcode=66 handle_segv=0 handle_sigbus=0"
# valgrind runs one thread at a time.  Without --fair-sched=yes a thread
# that computes in a loop can keep that turn, and the runtime's monitor
# thread, which asks it to let other tasks run, never gets one: the
# preemption test then fails whenever the machine is otherwise idle.
VG="valgrind --fair-sched=yes --quiet --error-exitcode=66 --leak-check=full --errors-for-leak-kinds=definite --show-leak-kinds=definite"
# valgrind on FreeBSD refuses the option ("fair scheduling is not supported
# on this system") and runs nothing; there it is left out.
if [ "$(uname -s)" = FreeBSD ]; then
	VG="valgrind --quiet --error-exitcode=66 --leak-check=full --errors-for-leak-kinds=definite --show-leak-kinds=definite"
fi
# The flags of a programme built for valgrind.  Where the build of PCRE2 for
# valgrind is there, it is linked in place of the other: its JIT leaves out
# the vector search, whose aligned loads past the end of a text valgrind
# reports, and it tells valgrind which memory it defines.
VGC="-g -DHILDE_VALGRIND"
VGPCRE=/usr/local/pcre2-valgrind/lib
if [ -r "$VGPCRE/libpcre2-8.a" ]; then
	VGC="$VGC -L$VGPCRE"
	echo "runtime-valgrind-pcre2=$VGPCRE"
else
	echo "runtime-valgrind-pcre2=none (the system's PCRE2)"
fi
CONTROLS=test-programs/controls
S=102-runtime-checks

held=0
notrun=0
bad=0

good() {
	echo "runtime-$1=ok $2"
	held=$((held+1))
}

fault() {
	echo "runtime-$1=BAD $2"
	bad=$((bad+1))
}

# unavailable <label> <reason>: NOT RUN when optional, a fault when required.
unavailable() {
	if [ "$mode" = optional ]; then
		echo "runtime-$1=NOT-RUN $2"
		notrun=$((notrun+1))
	else
		fault "$1" "cannot run here: $2"
	fi
}

# The number of entries of a not-run file: lines that are neither blank nor
# a comment.
entries() {
	grep -c -v -E '^(#|[[:space:]]*$)' "$1"
}

# merge_not_run <not-run file or -> <suite or ->: sets NR to the not-run file
# of a run that happens on this system -- the check's own file and the
# entries of the system's file (the third argument) that belong to the suite,
# or all of them for a run of every suite.  A test the system's plain run
# leaves out cannot run under an instrument either.  Without a system file NR
# is the check's own file, as it always was; with nothing to leave out it is -.
mergeno=0
merge_not_run() {
	NR=$1
	[ "$system_not_run" = - ] && return 0
	mergeno=$((mergeno+1))
	merged=$L/runtime-not-run-$mergeno.txt
	: > "$merged"
	[ "$1" = - ] || cat "$1" >> "$merged"
	if [ "$2" = - ]; then
		grep -v -E '^(#|[[:space:]]*$)' "$system_not_run" > "$merged.system"
	else
		grep -E "^$2/" "$system_not_run" > "$merged.system"
	fi
	# A name the check's own file holds already stays with its own reason:
	# the runner refuses a name that is listed twice.  The first file is told
	# by its name: when it is empty, NR == FNR would hold for the lines of the
	# second as well and none of them would be kept.
	awk 'FILENAME == ARGV[1] { if ($0 !~ /^(#|[[:space:]]*$)/) seen[$1] = 1; next } !($1 in seen)' "$merged" "$merged.system" >> "$merged"
	rm -f "$merged.system"
	if [ "$(entries "$merged")" = 0 ]; then
		NR=-
	else
		NR=$merged
	fi
	return 0
}

# suite_left_out <suite>: true when the system's not-run file names every test
# of the suite, so that a run of the suite alone would run nothing.
suite_left_out() {
	[ "$system_not_run" = - ] && return 1
	named=$(grep -c -E "^$1/" "$system_not_run")
	there=0
	for d in test-programs/suites/$1/*; do
		[ -d "$d" ] && there=$((there+1))
	done
	[ "$there" -gt 0 ] && [ "$named" = "$there" ]
}

# e2e <label> <not-run file or -> <suite or -> [NAME=value ...]: one run of
# the end-to-end runner; sets rc, pass, fail, left and secs, and keeps the
# log and FAILURES.txt under the label.
e2e() {
	label=$1
	nr=$2
	suite=$3
	shift 3
	[ "$nr" = - ] || set -- "$@" "HILDE_TEST_NOT_RUN=$nr"
	rm -f FAILURES.txt
	s=$(date +%s)
	if [ "$suite" = - ]; then
		env "$@" python3 test-programs/runner.py > "$L/runtime-$label.log" 2>&1
	else
		env "$@" python3 test-programs/runner.py "$suite" > "$L/runtime-$label.log" 2>&1
	fi
	rc=$?
	secs=$(( $(date +%s) - s ))
	pass=$(grep -c ' PASS$' "$L/runtime-$label.log")
	fail=$(grep -c ' FAIL$' "$L/runtime-$label.log")
	left=$(grep -c '  NOT RUN  ' "$L/runtime-$label.log")
	if [ -f FAILURES.txt ]; then
		mv FAILURES.txt "$L/runtime-$label-failures.txt"
	else
		: > "$L/runtime-$label-failures.txt"
	fi
}

# suites <label> <not-run file or -> <suite or -> [NAME=value ...]: a run of
# the suites, held to exit 0, no failure, at least one pass and exactly the
# not-run file's tests left out.
suites() {
	label=$1
	nr=$2
	e2e "$@"
	want=0
	[ "$nr" = - ] || want=$(entries "$nr")
	line="exit=$rc pass=$pass fail=$fail not-run=$left (want $want) seconds=$secs"
	# The tests left out, with their reasons, and every failure: the lines a
	# reader of the gate has to see.
	grep '  NOT RUN  ' "$L/runtime-$label.log"
	grep ' FAIL$' "$L/runtime-$label.log" | head -20
	if [ "$rc" = 0 ] && [ "$fail" = 0 ] && [ "$pass" -gt 0 ] && [ "$left" = "$want" ]; then
		good "$label" "$line"
	else
		fault "$label" "$line"
	fi
}

# control <label> <test> PASS|FAIL <text or -> [<second text>]: one control of
# the last run of the controls, read from its log and its FAILURES.txt.  A
# control that must fail is held only when its report carries the text; the
# line it prints quotes the first report line with that text, so the log
# shows which fault came and not only that the control failed.  The second
# text holds as well: clang's UndefinedBehaviorSanitizer reports a read past
# a block of a size it knows before AddressSanitizer is asked.
control() {
	label=$1
	test=$2
	want=$3
	text=$4
	second=${5:-}
	log=$L/runtime-$label.log
	got=$(grep -E "^$S +$test +(PASS|FAIL)\$" "$log" | awk '{print $NF}')
	seen=yes
	report=none
	if [ "$text" != - ]; then
		report=$(awk -v t="$test" '/^Test: /{on=($2==t)} on' "$L/runtime-$label-failures.txt" |
			grep -F "$text" | head -1 | sed -e 's/^[[:space:]]*//' -e 's/==[0-9]*== *//' | cut -c1-140)
		if [ -z "$report" ] && [ -n "$second" ]; then
			report=$(awk -v t="$test" '/^Test: /{on=($2==t)} on' "$L/runtime-$label-failures.txt" |
				grep -F "$second" | head -1 | sed -e 's/^[[:space:]]*//' -e 's/==[0-9]*== *//' | cut -c1-140)
		fi
		[ -n "$report" ] || { seen=no; report=none; }
	fi
	if [ "$got" = "$want" ] && [ "$seen" = yes ]; then
		good "$label-$test" "$got report: $report"
	else
		fault "$label-$test" "got [$got] report-seen=$seen (want $want and [$text])"
	fi
}

# lib <label> <flag or -> [NAME=value ...]: the library's tests through hilde
# test under an instrument, or with the environment given and no flag; a
# refusal (H1021) is the system's answer and says why.
lib() {
	label=$1
	flag=$2
	shift 2
	s=$(date +%s)
	if [ "$flag" = - ]; then
		env "$@" ./hilde test "--jobs=${HILDE_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1)}" --modules=bindings/generated standard/src lib/builtin > "$L/runtime-$label.log" 2> "$L/runtime-$label-err.log"
	else
		env "$@" ./hilde test "$flag" "--jobs=${HILDE_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1)}" --modules=bindings/generated standard/src lib/builtin > "$L/runtime-$label.log" 2> "$L/runtime-$label-err.log"
	fi
	rc=$?
	secs=$(( $(date +%s) - s ))
	if grep -q 'Error code: H1021' "$L/runtime-$label-err.log"; then
		why=$(sed -n '/^  Description:/{n;p;}' "$L/runtime-$label-err.log" | head -1 | sed 's/^ *//')
		unavailable "$label" "hilde test $flag refused with H1021: $why"
		return
	fi
	last=$(tail -1 "$L/runtime-$label.log")
	tests=$(echo "$last" | sed -n 's/^hilde test: [0-9]* test files, \([0-9]*\) tests, .*/\1/p')
	line="exit=$rc tests=${tests:-NONE} seconds=$secs [$last]"
	if [ "$rc" = 0 ] && [ -n "$tests" ] && [ "$tests" -gt 0 ] &&
		echo "$last" | grep -q ', 0 failed, 0 not built$'; then
		good "$label" "$line"
	else
		fault "$label" "$line"
		grep -E '^(FAIL|    FAIL)  ' "$L/runtime-$label.log" | head -10
		head -5 "$L/runtime-$label-err.log"
	fi
}

# examples <label> <arguments or -> [NAME=value ...]: the examples through
# scripts/check-examples.py; its last line is the count.
examples() {
	label=$1
	args=$2
	shift 2
	[ "$args" = - ] && args=
	s=$(date +%s)
	# shellcheck disable=SC2086
	env "$@" python3 scripts/check-examples.py memory "$label" $args > "$L/runtime-$label.log" 2>&1
	rc=$?
	last=$(tail -1 "$L/runtime-$label.log")
	grep ' BAD ' "$L/runtime-$label.log" | cut -c1-600 | head -20
	line="exit=$rc seconds=$(( $(date +%s) - s )) [$last]"
	if [ "$rc" = 0 ]; then
		good "$label" "$line"
	else
		fault "$label" "$line"
	fi
}

# The sanitizers: a programme that does nothing, built with their flags and
# run, as hilde test asks.
printf 'int main(void) { return 0; }\n' > "$L/runtime-probe.c"
if cc -std=c17 $MEM "$L/runtime-probe.c" -o "$L/runtime-probe" > "$L/runtime-probe-memory.log" 2>&1 &&
	"$L/runtime-probe" >> "$L/runtime-probe-memory.log" 2>&1; then
	merge_not_run test-programs/not-run-memory.txt -
	suites e2e-memory "$NR" - "HILDE_TEST_CFLAGS=$MEM" "ASAN_OPTIONS=$AO" UBSAN_OPTIONS=print_stacktrace=1
	# On macOS a programme confines itself by starting again under
	# sandbox-exec, and dyld then loads the sanitizers' runtime under its
	# policy, which does not grant the directory of the C compiler.
	if [ "$(uname -s)" = Darwin ]; then
		unavailable e2e-memory-sandbox "a confined programme starts again under sandbox-exec, whose policy keeps dyld from loading the sanitizers' runtime from the directory of the C compiler"
	elif suite_left_out 035-sandbox; then
		unavailable e2e-memory-sandbox "every test of 035-sandbox is in the not-run file of this system"
	else
		suites e2e-memory-sandbox - 035-sandbox "HILDE_TEST_CFLAGS=$MEM" "ASAN_OPTIONS=$AO detect_leaks=0" UBSAN_OPTIONS=print_stacktrace=1
	fi
	e2e controls-memory - - HILDE_TEST_SUITES=$CONTROLS "HILDE_TEST_CFLAGS=$MEM" "ASAN_OPTIONS=$AO" UBSAN_OPTIONS=print_stacktrace=1
	control controls-memory 001-clean PASS -
	control controls-memory 002-read-past-the-end FAIL 'ERROR: AddressSanitizer: heap-buffer-overflow' 'runtime error: load of address'
	# LeakSanitizer is asked first (scripts/lsan-supported.sh): where the
	# system does not support it, the lost buffer is not reported by it.
	if [ "$(sh scripts/lsan-supported.sh "$L")" = no ]; then
		unavailable controls-memory-003-lost-buffer "LeakSanitizer is not supported on this system: detect_leaks is not supported on this platform"
	else
		control controls-memory 003-lost-buffer FAIL 'ERROR: LeakSanitizer: detected memory leaks'
	fi
	control controls-memory 004-misaligned-load FAIL 'runtime error: load of misaligned address'
	control controls-memory 005-double-free FAIL 'ERROR: AddressSanitizer: attempting double-free'
	examples examples-memory "--except=examples/learn-sandbox --except=examples/learn-files --except=examples/learn-arguments --except=examples/learn-log --except=examples/learn-poller" "HILDE_TEST_CFLAGS=$MEM" "ASAN_OPTIONS=$AO" UBSAN_OPTIONS=print_stacktrace=1
	if [ "$(uname -s)" = Darwin ]; then
		unavailable examples-memory-sandbox "the examples confine themselves, and on macOS a confined programme cannot load the sanitizers' runtime, as for e2e-memory-sandbox"
	else
		examples examples-memory-sandbox "--only=examples/learn-sandbox --only=examples/learn-files --only=examples/learn-arguments --only=examples/learn-log --only=examples/learn-poller" "HILDE_TEST_CFLAGS=$MEM" "ASAN_OPTIONS=$AO detect_leaks=0" UBSAN_OPTIONS=print_stacktrace=1
	fi
	memory=yes
else
	unavailable e2e-memory "cc does not build and run a programme with $MEM: $(head -1 "$L/runtime-probe-memory.log")"
	unavailable examples-memory "cc does not build and run a programme with $MEM, as for e2e-memory"
	memory=no
fi

# valgrind: it starts, and its header, which the runtime reads under
# -DHILDE_VALGRIND, is found.
printf '#include <valgrind/valgrind.h>\nint main(void) { return RUNNING_ON_VALGRIND; }\n' > "$L/runtime-probe-vg.c"
if ! command -v valgrind > /dev/null 2>&1; then
	unavailable e2e-valgrind "valgrind is not on PATH"
	unavailable examples-valgrind "valgrind is not on PATH"
elif ! cc -std=c17 -g -DHILDE_VALGRIND "$L/runtime-probe-vg.c" -o "$L/runtime-probe-vg" > "$L/runtime-probe-valgrind.log" 2>&1; then
	unavailable e2e-valgrind "cc does not find valgrind/valgrind.h: $(head -1 "$L/runtime-probe-valgrind.log")"
	unavailable examples-valgrind "cc does not find valgrind/valgrind.h, as for e2e-valgrind"
else
	merge_not_run test-programs/not-run-valgrind.txt -
	suites e2e-valgrind "$NR" - "HILDE_TEST_CFLAGS=$VGC" "HILDE_TEST_WRAPPER=$VG"
	e2e controls-valgrind - - HILDE_TEST_SUITES=$CONTROLS "HILDE_TEST_CFLAGS=$VGC" "HILDE_TEST_WRAPPER=$VG"
	control controls-valgrind 001-clean PASS -
	control controls-valgrind 002-read-past-the-end FAIL 'Invalid read of size 4'
	control controls-valgrind 003-lost-buffer FAIL 'definitely lost'
	echo "runtime-controls-valgrind-004-misaligned-load=$(grep -E "^$S +004-misaligned-load +(PASS|FAIL)\$" "$L/runtime-controls-valgrind.log" | awk '{print $NF}') (printed, not judged)"
	control controls-valgrind 005-double-free FAIL 'Invalid free()'
	examples examples-valgrind - "HILDE_TEST_CFLAGS=$VGC" "HILDE_TEST_WRAPPER=$VG"
fi

# UndefinedBehaviorSanitizer in trap mode: no runtime library, a fault runs a
# trap instruction and the programme ends by a signal with nothing printed.
# It needs nothing the system's compiler lacks, so it runs where the full
# sanitizers have no runtime too, and both gates hold the same pass.
TRAP="-fsanitize=undefined -fsanitize-trap=undefined -g -O1"
# The function check reads the bytes in front of the function it calls
# through a pointer, and OpenBSD maps code execute-only: without this flag
# every such call ends in a segmentation fault instead of being checked, as
# scripts/check-ubsan-trap.sh says for its own pass.
if [ "$(uname -s)" = OpenBSD ]; then
	TRAP="$TRAP -Wl,--no-execute-only"
fi
if cc -std=c17 $TRAP "$L/runtime-probe.c" -o "$L/runtime-probe-trap" > "$L/runtime-probe-trap.log" 2>&1 &&
	"$L/runtime-probe-trap" >> "$L/runtime-probe-trap.log" 2>&1; then
	merge_not_run test-programs/not-run-ubsan-trap.txt -
	suites e2e-ubsan-trap "$NR" - "HILDE_TEST_CFLAGS=$TRAP"
	e2e controls-ubsan-trap - - HILDE_TEST_SUITES=$CONTROLS "HILDE_TEST_CFLAGS=$TRAP"
	control controls-ubsan-trap 001-clean PASS -
	control controls-ubsan-trap 004-misaligned-load FAIL 'signal SIGILL' 'signal SIGTRAP'
	for t in 002-read-past-the-end 003-lost-buffer 005-double-free; do
		echo "runtime-controls-ubsan-trap-$t=$(grep -E "^$S +$t +(PASS|FAIL)\$" "$L/runtime-controls-ubsan-trap.log" | awk '{print $NF}') (printed, not judged: not undefined behaviour of C that UBSan sees)"
	done
else
	unavailable e2e-ubsan-trap "cc does not build and run a programme with $TRAP: $(head -1 "$L/runtime-probe-trap.log")"
fi

# The checking options of OpenBSD's malloc(3): S switches on every check
# that costs, among them canaries, junk on free and guard pages.  Other
# systems have no MALLOC_OPTIONS; there the pass is not the system's and is
# named, not counted.
if [ "$(uname -s)" = OpenBSD ]; then
	merge_not_run - -
	suites e2e-malloc "$NR" - MALLOC_OPTIONS=S
	e2e controls-malloc - - HILDE_TEST_SUITES=$CONTROLS MALLOC_OPTIONS=S
	control controls-malloc 001-clean PASS -
	control controls-malloc 005-double-free FAIL 'double free'
	lib lib-malloc - MALLOC_OPTIONS=S
else
	echo "runtime-e2e-malloc=not this system's pass: MALLOC_OPTIONS is the interface of OpenBSD's malloc(3), uname -s is $(uname -s)"
fi

lib lib-memory --memory
lib lib-valgrind --valgrind

# Where the sanitizers cannot run, the optimisation they carry is run alone.
if [ "$memory" = no ]; then
	suites e2e-optimised "$system_not_run" - HILDE_TEST_CFLAGS=-O1
fi

# cppcheck, in ONE configuration, the one the C compiler builds: -D for
# each macro naming the compiler, the system and the processor that cc
# predefines.  With -D cppcheck checks that configuration and no other;
# without it every combination of the runtime's #if lines is tried, which
# took 240 seconds instead of 87 over the frame of 2026-09-26, and the
# compiler's whole list of macros given with --include took longer still.
if ! command -v cppcheck > /dev/null 2>&1; then
	unavailable cppcheck "cppcheck is not on PATH"
else
	jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1)
	cc -dM -E -x c /dev/null > "$L/runtime-cppcheck-predef.h"
	defs=
	for m in __GNUC__ __clang__ __linux__ __OpenBSD__ __FreeBSD__ __APPLE__ __x86_64__ __aarch64__; do
		v=$(sed -n "s/^#define $m \(.*\)\$/\1/p" "$L/runtime-cppcheck-predef.h")
		[ -n "$v" ] && defs="$defs -D$m=$v"
	done
	echo "runtime-cppcheck-configuration=[$defs ]"
	run_cppcheck() {
		# shellcheck disable=SC2086
		cppcheck -q -j "$jobs" --std=c11 --enable=warning,portability --error-exitcode=1 \
			--inline-suppr --suppress=missingIncludeSystem --suppress-xml=scripts/cppcheck-suppressions.xml \
			$defs "$@"
	}
	findings() {
		grep -c -E ': (error|warning|portability|performance|style): ' "$1"
	}
	printf 'int main(void) {\n  int a[4] = { 0, 1, 2, 3 };\n  return a[4];\n}\n' > "$L/runtime-cppcheck-fault.c"
	printf 'int main(void) {\n  int a[4] = { 0, 1, 2, 3 };\n  return a[3];\n}\n' > "$L/runtime-cppcheck-clean.c"
	run_cppcheck "$L/runtime-cppcheck-fault.c" > "$L/runtime-cppcheck-fault.log" 2>&1
	frc=$?
	run_cppcheck "$L/runtime-cppcheck-clean.c" > "$L/runtime-cppcheck-clean.log" 2>&1
	crc=$?
	if [ "$frc" = 1 ] && grep -q 'arrayIndexOutOfBounds' "$L/runtime-cppcheck-fault.log" &&
		[ "$crc" = 0 ] && [ "$(findings "$L/runtime-cppcheck-clean.log")" = 0 ]; then
		good cppcheck-controls "fault exit=$frc clean exit=$crc report: $(grep 'arrayIndexOutOfBounds' "$L/runtime-cppcheck-fault.log" | head -1 | sed 's|.*/||' | cut -c1-140)"
	else
		fault cppcheck-controls "fault exit=$frc clean exit=$crc (want 1 with arrayIndexOutOfBounds, and 0)"
	fi
	F=$L/runtime-cppcheck-frame
	sh scripts/count-warnings.sh --emit-only "$F" > "$L/runtime-cppcheck-emit.log" 2>&1
	n=0
	for f in "$F"/*.c; do
		[ -f "$f" ] && n=$((n+1))
	done
	s=$(date +%s)
	run_cppcheck "$F"/*.c > "$L/runtime-cppcheck.log" 2>&1
	rc=$?
	k=$(findings "$L/runtime-cppcheck.log")
	line="exit=$rc files=$n findings=$k jobs=$jobs seconds=$(( $(date +%s) - s )) $(cppcheck --version 2>&1)"
	if [ "$rc" = 0 ] && [ "$k" = 0 ] && [ "$n" -gt 0 ]; then
		good cppcheck "$line"
	else
		fault cppcheck "$line"
		grep -E ': (error|warning|portability|performance|style): ' "$L/runtime-cppcheck.log" | head -20
	fi
fi

echo "runtime-checks held=$held not-run=$notrun bad=$bad"
[ "$bad" = 0 ] || exit 1
[ "$held" -gt 0 ] || exit 1
exit 0
