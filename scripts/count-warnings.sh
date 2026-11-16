#!/bin/sh
# Count the C compiler's warnings over the C files of ONE run, under both
# yardsticks:
#
#     normal   cc -std=c17 -Wall -Wextra                 target: zero
#     strict   normal plus -Wpedantic                    target: zero
#     optimised  normal plus -O1                        target: zero
#
# The optimised yardstick is there because gcc 14 warns at -O1 where it
# does not at -O0, -Wmaybe-uninitialized after a switch.
#
# The script reports, it does not judge. The gates judge all three numbers
# with scripts/check-normal-warnings.sh.
#
#     sh scripts/count-warnings.sh --base <dir> [file ...]
#     COUNT_BASE=<dir> sh scripts/count-warnings.sh [file ...]
#     sh scripts/count-warnings.sh --emit-only <dir>
#
# --emit-only emits the frame described below into <dir>, which must not
# exist yet, prints how many C files it holds and counts nothing: the frame
# cppcheck is run over (scripts/check-runtime.sh) is this frame,
# written in one place.
#
# The base directory is NOT optional and is never guessed. Earlier versions
# put the run directory wherever mktemp pointed, which on a Linux host is
# /tmp -- a place the repository keeps free of such files, and a place the
# caller never saw. The caller now names it, and both gate paths do.
#
# Without file arguments the script emits the whole frame itself, into a
# directory created fresh under the base for this run: every end-to-end test
# that is expected to compile, every example of run-examples.sh, and the
# programme of every test file of the standard library (hilde test --emit-c).
# It emits them rather than collecting them because the examples and the
# standard library's tests compile straight to a binary and leave no C behind,
# and because a file left by an earlier run must not be able to enter this
# count. The run directory and the file count are printed.
#
# The counting form: a warning line is a line that says "warning:", and the
# classes are read from its [-Wclass] tag, never classified by hand. A line
# without a tag counts as well and is reported separately as untagged: gcc
# gives some warnings without one, such as a pragma once in the main file,
# and a count of tagged lines alone would not see them.
#
# POSIX sh, no bashisms (SH-002): in the OpenBSD guest /bin/sh is ksh.
# Exit 9 means "did not run". Otherwise the exit is 0, whatever the counts.
set -u

CC=${CC:-cc}
NORMAL_FLAGS="-std=c17 -Wall -Wextra"
STRICT_FLAGS="-std=c17 -Wall -Wextra -Wpedantic"
OPTIMISED_FLAGS="-std=c17 -Wall -Wextra -O1"

# The frame and the yardsticks are many independent runs of the compiler
# and of cc, one per file.  They run on all processors at once through
# xargs -P, each into a file of its own; the files are put together in the
# order of the list afterwards, so the frame and the logs hold the same
# bytes as one run after the other.  HILDE_JOBS sets the number, 1 runs
# them one after the other.
jobs=${HILDE_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}
case "$jobs" in '' | *[!0-9]* | 0) jobs=1 ;; esac

# The include directories of the libraries a file names in its link
# manifest, its last line /* hilde link libraries: ... */, found as the
# end-to-end runner finds its link flags: pkg-config under the name, then
# under lib and the name.  On OpenBSD
# a library of ports keeps its header in /usr/local/include, which the base
# cc does not search; without these directories such a file is not
# compiled at all and its warnings go uncounted.  They are passed as
# -isystem, not -I: the header of a foreign library is not code Hilde
# emits, and on Linux the same header under /usr/include is a system
# header whose warnings the compiler does not report.
include_flags() {
	command -v pkg-config >/dev/null 2>&1 || return 0
	names=$(sed -n 's|^/\* hilde link libraries:\(.*\)\*/$|\1|p' "$1" | tail -1)
	for name in $names; do
		for known in "$name" "lib$name"; do
			if pkg-config --exists "$known" 2>/dev/null; then
				pkg-config --cflags-only-I "$known" | sed 's/-I\([^ ]*\)/-isystem \1/g'
				break
			fi
		done
	done
}

# One end-to-end test into the frame <out>, as the runner compiles it.
emit_one() {
	out=$1
	d=$2
	suite=$(basename "$(dirname "$d")")
	tcase=$(basename "$d")
	cpath="$out/e2e_${suite}_${tcase}.c"
	if [ -f "$d/cli.txt" ]; then
		cli=$(sed -e "s|\$DIR|$d|g" -e "s|\$C_PATH|$cpath|g" "$d/cli.txt")
		# shellcheck disable=SC2086
		set -- $cli
		"$@" > /dev/null 2>&1
	else
		./hilde compile "$d/Test.hiq" --entrypoint=Test:main \
			--target-type=c "--output=$cpath" --error-format=hilde-json \
			> /dev/null 2>&1
	fi
	return 0
}

# One file of a yardstick, its compiler output into <logdir>/<n>.log.
compile_one() {
	case "$1" in
	normal) flags=$NORMAL_FLAGS ;;
	strict) flags=$STRICT_FLAGS ;;
	optimised) flags=$OPTIMISED_FLAGS ;;
	*) echo "ABORT: no yardstick [$1]" >&2; return 9 ;;
	esac
	incs=$(include_flags "$4" | tr '\n' ' ')
	# shellcheck disable=SC2086
	"$CC" $flags $incs -c "$4" -o /dev/null > "$2/$3.log" 2>&1
	return 0
}

case "${1:-}" in
--emit-one)
	emit_one "$2" "$3"
	exit $?
	;;
--compile-one)
	compile_one "$2" "$3" "$4" "$5"
	exit $?
	;;
esac

base=""
emit_only=""
while [ "$#" -gt 0 ]; do
	case "$1" in
	--emit-only)
		shift
		[ "$#" -gt 0 ] || { echo "ABORT: --emit-only needs a directory" >&2; exit 9; }
		emit_only=$1
		shift
		;;
	--base)
		shift
		[ "$#" -gt 0 ] || { echo "ABORT: --base needs a directory" >&2; exit 9; }
		base=$1
		shift
		;;
	--base=*)
		base=${1#--base=}
		shift
		;;
	*)
		break
		;;
	esac
done
[ -n "$base" ] || base=${COUNT_BASE:-}
if [ -z "$base" ] && [ -z "$emit_only" ]; then
	echo "ABORT: no base directory for the run directory." >&2
	echo "       Pass --base <dir> or set COUNT_BASE=<dir>." >&2
	echo "       It is not guessed, and never placed in /tmp unasked." >&2
	exit 9
fi
if [ -z "$emit_only" ]; then
	mkdir -p "$base" 2>/dev/null || true
	[ -d "$base" ] && [ -w "$base" ] ||
		{ echo "ABORT: base directory $base is not a writable directory" >&2; exit 9; }
fi

# PIT-054: every tool is assured before anything runs, and a missing one says
# "did not run" rather than passing with zero.
for t in "$CC" grep sed sort uniq mktemp; do
	command -v "$t" >/dev/null 2>&1 ||
		{ echo "ABORT: $t not on PATH -- the warning count did NOT run" >&2; exit 9; }
done

if [ -z "$emit_only" ]; then
	W=$(mktemp -d "$base/count-warnings.XXXXXX") ||
		{ echo "ABORT: mktemp -d under $base failed" >&2; exit 9; }
	trap 'rm -rf "$W"' EXIT
	RUN=$W/c
	mkdir -p "$RUN" || exit 9
fi

emit_frame() {
	out=$1
	[ -x ./hilde ] || { echo "ABORT: ./hilde is not built -- nothing emitted" >&2; return 9; }
	# A programme that reads Standard.BuildInfo carries the time of its build
	# and the commit and state of the work tree it was built in.  The frame
	# is to be the same bytes wherever and whenever it is emitted, so the
	# time is fixed and git finds no repository: the commit is then empty
	# and the tree clean, on every host and in a tree unpacked from a tar.
	SOURCE_DATE_EPOCH=1
	GIT_DIR=$out/no-repository
	GIT_CEILING_DIRECTORIES=/
	export SOURCE_DATE_EPOCH GIT_DIR GIT_CEILING_DIRECTORIES
	[ ! -e "$GIT_DIR" ] || { echo "ABORT: $GIT_DIR exists -- the frame would read it as a repository" >&2; return 9; }

	: > "$out.tests"
	for d in test-programs/suites/*/*; do
		[ -d "$d" ] || continue
		[ -f "$d/hilde-stderr.txt" ] && continue
		echo "$d" >> "$out.tests"
	done
	xargs -P "$jobs" -n 1 sh "$0" --emit-one "$out" < "$out.tests"
	rm -f "$out.tests"

	# The examples of the compile lines of run-examples.sh, with the standard
	# modules that script's compile function names, in its order.  A module
	# left out makes the compiler refuse the example, and since its output
	# goes nowhere the example would be missing from the count without a
	# word: so every one is counted and a missing one stops the frame.
	std=""
	for m in Buffer String StringBuilder IO/IO Bindings/Terminal IO/Terminal; do
		std="$std ./standard/src/$m.hih,./standard/src/$m.hiq"
	done
	listed=0
	emitted_examples=0
	for pair in "examples/ffi FFI" "examples/fib Fibonacci" \
		"examples/generic-record GenericRecord" \
		"examples/generic-union GenericUnion" \
		"examples/haversine Haversine" "examples/hello-world HelloWorld" \
		"examples/identity Identity" "examples/memory Memory" \
		"examples/named-argument NamedArgument" "examples/record Record" \
		"examples/union Union" "examples/greet Greet" \
		"examples/learn-linear LearnLinear" "examples/learn-borrow LearnBorrow" \
		"examples/learn-errors LearnErrors" "examples/learn-text LearnText"; do
		# shellcheck disable=SC2086
		set -- $pair
		dir=$1
		mod=$2
		listed=$((listed+1))
		# shellcheck disable=SC2086
		./hilde compile $std "$dir/$mod.hih,$dir/$mod.hiq" \
			"--entrypoint=Example.$mod:main" --target-type=c \
			"--output=$out/ex_$mod.c" > /dev/null 2>&1
		if [ -f "$out/ex_$mod.c" ]; then
			emitted_examples=$((emitted_examples+1))
		else
			echo "count-warnings: example $dir did not compile" >&2
		fi
	done

	# The examples of the example lines of run-examples.sh
	#: each directory writes its
	# programmes as C with its own Makefile, target c, which is the one place
	# its module list stands.  The C files are taken out of the directory and
	# the directory is cleaned.
	make_tool=make
	command -v gmake >/dev/null 2>&1 && make_tool=gmake
	for dir in $(sed -n 's/^example[a-z_]* \(examples\/[a-z0-9-]*\) .*/\1/p' run-examples.sh | sort -u); do
		"$make_tool" -C "$dir" c > /dev/null 2>&1 || echo "count-warnings: make c failed in $dir" >&2
		for prog in $(sed -n "s|^example[a-z_]* $dir \([A-Za-z0-9_]*\) .*|\1|p" run-examples.sh); do
			listed=$((listed+1))
			name=ex_$(basename "$dir")_$prog.c
			if [ -f "$dir/$prog.c" ]; then
				mv "$dir/$prog.c" "$out/$name"
				emitted_examples=$((emitted_examples+1))
			else
				echo "count-warnings: example $dir $prog did not compile" >&2
			fi
		done
		"$make_tool" -C "$dir" clean > /dev/null 2>&1
	done
	echo "count-warnings: examples-emitted=$emitted_examples of $listed"
	if [ "$emitted_examples" != "$listed" ] || [ "$listed" = 0 ]; then
		echo "ABORT: $((listed - emitted_examples)) of $listed examples were not emitted -- the frame is not whole" >&2
		return 9
	fi

	# The standard library's tests, one programme per test file, as hilde test
	# builds them.  Its last line
	# counts what it emitted; a count of none is said, not passed over.
	./hilde test --emit-c="$out" "--jobs=$jobs" --modules=bindings/generated standard/src lib/builtin > "$out.stdlib.log" 2>&1
	emitted=$(sed -n 's/^hilde test: .*, \([0-9]*\) emitted, .*/\1/p' "$out.stdlib.log")
	echo "count-warnings: stdlib-test-programmes=${emitted:-NONE}"
	rm -f "$out.stdlib.log"
	return 0
}

if [ -n "$emit_only" ]; then
	[ ! -e "$emit_only" ] || { echo "ABORT: $emit_only exists -- nothing emitted" >&2; exit 9; }
	mkdir -p "$emit_only" || exit 9
	emit_frame "$emit_only" || exit 9
	n=0
	for f in "$emit_only"/*.c; do
		[ -f "$f" ] && n=$((n+1))
	done
	echo "count-warnings: emitted=$n into $emit_only"
	exit 0
fi

: > "$W/files.txt"
if [ "$#" -gt 0 ]; then
	source_of_files="arguments"
	for f in "$@"; do
		[ -f "$f" ] && echo "$f" >> "$W/files.txt"
	done
else
	source_of_files="emitted by this run into $RUN"
	emit_frame "$RUN" || exit 9
	for f in "$RUN"/*.c; do
		[ -f "$f" ] && echo "$f" >> "$W/files.txt"
	done
fi
files=$(wc -l < "$W/files.txt" | tr -d ' ')

# The frame hash: one hash over the per-file hashes of the emitted C, in
# LC_ALL=C order of the base names.  It is here, beside the frame, because
# the frame is here -- on 2026-09-21 the cross-platform comparison was made
# with a probe that lifted emit_frame out of this script and hashed the
# result in a form nobody wrote down, and that form could not be reproduced
# afterwards (the value was 07b3c6af...).  A value with no written form is a
# value with no second opinion.
#
# The form, in words, so that it can be checked without reading the code:
# hash each file, take only the hex digest, sort those digests is NOT what
# happens -- the files are sorted by base name first and the digests are
# hashed in that order, so a file that changes name changes the frame hash.
# Only the base names enter, never the directory, so the run directory does
# not reach the value.
#
# Platform note: `sha256sum' is GNU, `sha256 -q' is OpenBSD and FreeBSD,
# `shasum -a 256' is macOS.  One of them is picked and the choice is printed,
# because a frame hash from two different tools would be two values.
if command -v sha256sum >/dev/null 2>&1; then
	hash_tool="sha256sum"
	hash_of() { sha256sum "$1" | cut -d' ' -f1; }
	hash_stdin() { sha256sum | cut -d' ' -f1; }
elif command -v sha256 >/dev/null 2>&1; then
	hash_tool="sha256 -q"
	hash_of() { sha256 -q "$1"; }
	hash_stdin() { sha256 -q; }
elif command -v shasum >/dev/null 2>&1; then
	hash_tool="shasum -a 256"
	hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
	hash_stdin() { shasum -a 256 | cut -d' ' -f1; }
else
	hash_tool="none"
fi

if [ "$hash_tool" = none ]; then
	frame_hash="NOT-MEASURED-no-sha256-tool-on-PATH"
else
	: > "$W/byname.txt"
	while IFS= read -r f; do
		printf '%s\t%s\n' "$(basename "$f")" "$f" >> "$W/byname.txt"
	done < "$W/files.txt"
	frame_hash=$(
		LC_ALL=C sort "$W/byname.txt" | cut -f2 |
		while IFS= read -r f; do hash_of "$f"; done |
		hash_stdin
	)
fi

run_yardstick() {
	label=$1
	log="$W/$label.log"
	: > "$log"
	rm -rf "$W/$label.d"
	mkdir -p "$W/$label.d" || exit 9
	i=0
	while IFS= read -r f; do
		i=$((i+1))
		printf '%06d %s\n' "$i" "$f"
	done < "$W/files.txt" > "$W/$label.list"
	xargs -P "$jobs" -n 2 sh "$0" --compile-one "$label" "$W/$label.d" < "$W/$label.list"
	while read -r k f; do
		cat "$W/$label.d/$k.log" >> "$log" || exit 9
	done < "$W/$label.list"
	rm -rf "$W/$label.d" "$W/$label.list"
	tagged=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$log")
	saidwarning=$(grep -c ' warning: ' "$log")
	errors=$(grep -c ' error: ' "$log")
	untagged=$((saidwarning - tagged))
	grep -o -E '\[-W[A-Za-z0-9=_-]+\]' "$log" | sort | uniq -c | sort -rn \
		> "$W/$label.classes"
	sum=0
	while read -r cnt cls; do
		sum=$((sum + cnt))
		echo "count-warnings: $label-class $cnt $cls"
	done < "$W/$label.classes"
	echo "count-warnings: $label-tagged=$tagged untagged=$untagged errors=$errors"
	echo "count-warnings: $label-class-sum=$sum matches-tagged=$([ "$sum" = "$tagged" ] && echo yes || echo NO)"
	# Every line that says warning counts, with a tag or without: gcc says
	# some warnings, such as a pragma once in the main file, without one.
	eval "${label}_total=$saidwarning"
}

echo "count-warnings: cc=$($CC --version 2>&1 | head -1)"
echo "count-warnings: run-dir=$RUN (created for this run)"
echo "count-warnings: jobs=$jobs"
echo "count-warnings: files-from=$source_of_files"
echo "count-warnings: normal-flags=$NORMAL_FLAGS"
echo "count-warnings: strict-flags=$STRICT_FLAGS"
echo "count-warnings: optimised-flags=$OPTIMISED_FLAGS"
run_yardstick normal "$NORMAL_FLAGS"
run_yardstick strict "$STRICT_FLAGS"
run_yardstick optimised "$OPTIMISED_FLAGS"

# Controls of the counting form itself, in the same run and with the same
# tool: without them a zero says nothing (PIT-012, TEST-011).
printf 'int main(void){int x;return 0;}\n' > "$W/ctl-warn.c"
"$CC" $NORMAL_FLAGS -c "$W/ctl-warn.c" -o /dev/null > "$W/ctl-warn.log" 2>&1
pos=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$W/ctl-warn.log")
printf 'int main(void){return 0;}\n' > "$W/ctl-clean.c"
"$CC" $NORMAL_FLAGS -c "$W/ctl-clean.c" -o /dev/null > "$W/ctl-clean.log" 2>&1
neg=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$W/ctl-clean.log")
# The control of the optimised yardstick: a variable set in two cases of a
# switch only, which gcc reports at -O1 and not at -O0.
printf 'int f(int c){int x;switch(c){case 0:x=1;break;case 1:x=2;break;}return x;}\n' > "$W/ctl-o1.c"
"$CC" $OPTIMISED_FLAGS -c "$W/ctl-o1.c" -o /dev/null > "$W/ctl-o1.log" 2>&1
opt=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$W/ctl-o1.log")
# clang decides its warnings before it optimises and reports this switch at
# no level, so the control wants what the compiler at hand does: one
# warning from gcc, none from clang.
case "$($CC --version 2>&1 | head -1)" in
	*clang*) opt_want=0 ;;
	*) opt_want=1 ;;
esac
# The control of the strict yardstick: a struct without members, which C17
# does not have and both compilers accept as an extension.  -Wpedantic
# reports it once; the normal flags do not, so the strict count sees what
# the normal one cannot.
printf 'struct hilde_ctl {};\nint main(void){return 0;}\n' > "$W/ctl-strict.c"
"$CC" $STRICT_FLAGS -c "$W/ctl-strict.c" -o /dev/null > "$W/ctl-strict.log" 2>&1
st=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$W/ctl-strict.log")
"$CC" $NORMAL_FLAGS -c "$W/ctl-strict.c" -o /dev/null > "$W/ctl-strict-normal.log" 2>&1
stn=$(grep -c -E '\[-W[A-Za-z0-9=_-]+\]' "$W/ctl-strict-normal.log")

# The control the frame hash needs: without it, "the two platforms agree" is
# also what two broken runs that both emit nothing would say.  One file of
# the frame is copied with one byte changed, and the hash is taken again over
# the same list; it must differ.
if [ "$hash_tool" = none ]; then
	hash_ctl="NOT-MEASURED"
else
	mkdir -p "$W/ctl-frame"
	first=$(LC_ALL=C sort "$W/byname.txt" | cut -f2 | head -1)
	cp "$first" "$W/ctl-frame/changed.c"
	printf '/* one byte more */\n' >> "$W/ctl-frame/changed.c"
	changed_hash=$(
		{ hash_of "$W/ctl-frame/changed.c"
		  LC_ALL=C sort "$W/byname.txt" | cut -f2 | tail -n +2 |
		  while IFS= read -r f; do hash_of "$f"; done
		} | hash_stdin
	)
	if [ "$changed_hash" = "$frame_hash" ]; then
		hash_ctl="NO -- a changed byte gave the same hash"
	else
		hash_ctl="yes -- a changed byte gives a different hash"
	fi
fi

# The control of the untagged count: a pragma once in the main file, which
# gcc reports as a warning without a tag and clang with one; a count of
# tagged lines alone would not see the first.
printf '#pragma once\nint main(void){return 0;}\n' > "$W/ctl-once.c"
"$CC" $NORMAL_FLAGS -c "$W/ctl-once.c" -o /dev/null > "$W/ctl-once.log" 2>&1
once=$(grep -c ' warning: ' "$W/ctl-once.log")

# The last five lines are the summary, because the Linux gate shows the tail
# of this log and nothing more.
echo "count-warnings: files=$files"
echo "count-warnings: frame-hash=$frame_hash ($hash_tool)"
echo "count-warnings: frame-hash-control $hash_ctl"
echo "count-warnings: normal-total=$normal_total"
echo "count-warnings: strict-total=$strict_total"
echo "count-warnings: optimised-total=$optimised_total"
echo "count-warnings: controls positive=$pos (want 1) negative=$neg (want 0) optimised=$opt (want $opt_want)"
echo "count-warnings: strict-control strict=$st (want 1) normal=$stn (want 0)"
echo "count-warnings: untagged-control said=$once (want 1)"
echo "count-warnings: DONE"
exit 0
