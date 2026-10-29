#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Shared by mixed-test.sh and bench.sh, which source it from the root of the
# tree.  It builds the Hilde programmes and the Go rank program into a
# private work directory and starts jobs of ranks on localhost.  Every job
# is TLS 1.3 with certificates on both sides; there is no way to switch that
# off.  The Go repository is read, never changed: it is copied to the work
# directory, and the library of this tree is put into the copy.
#
# SPERLI_REPO names the Go repository (default /repos/sperli).  Exit 9 from
# a script that sources this means it could not run.

SPERLI_REPO=${SPERLI_REPO:-/repos/sperli}
umask 077

not_run() {
	echo "sperli: NOT RUN -- $1"
	exit 9
}

# make_work sets W to a new private directory and removes it on exit.
make_work() {
	W=$(mktemp -d "${TMPDIR:-/tmp}/sperli-run.XXXXXX") || not_run "no work directory"
	trap 'if test -e "$W"; then rm -rf "$W"; fi' EXIT
	mkdir "$W/bin" || not_run "cannot make $W/bin"
}

# build_all compiles the Hilde programmes and the Go rank into $W/bin.
build_all() {
	HILDE=${HILDE:-$(command -v hilde)} || not_run "no hilde"
	command -v go > /dev/null 2>&1 || not_run "no go"
	command -v cc > /dev/null 2>&1 || not_run "no C compiler"
	[ -d "$SPERLI_REPO" ] || not_run "no Go repository at $SPERLI_REPO"
	[ -f libsperli/src/sperli.c ] || not_run "run it from the root of the tree"
	if [ ! -f libsperli/c/linux/libsperli.a ]; then
		sh scripts/libsperli/build.sh "$HILDE" > "$W/libsperli.log" 2>&1 || { cat "$W/libsperli.log"; not_run "libsperli did not build"; }
	fi
	compile examples/sperli-sum/SperliSum.hih,examples/sperli-sum/SperliSum.hiq Example.SperliSum SperliSum
	compile examples/sperli-bench/SperliBench.hih,examples/sperli-bench/SperliBench.hiq Example.SperliBench SperliBench
	compile libsperli/test/mixed/MixedReject.hiq Mixed.Reject MixedReject
	compile libsperli/test/mixed/MixedDescribe.hiq Mixed.Describe MixedDescribe
	mkdir "$W/go" || not_run "cannot make $W/go"
	cp -R "$SPERLI_REPO/." "$W/go/" || not_run "cannot copy the Go repository"
	rm -rf "$W/go/.git"
	mkdir -p "$W/go/c/linux"
	cp libsperli/c/linux/libsperli.a libsperli/c/linux/sperli.h "$W/go/c/linux/" || not_run "no libsperli"
	(cd "$W/go" && CGO_ENABLED=1 go build -o "$W/bin/sperli-rank" ./cmd/sperli-rank) || not_run "the Go rank did not build"
}

# compile files module name: one programme into $W/bin/name.
compile() {
	"$HILDE" compile "$1" --modules=standard/src:bindings/generated --entrypoint="$2:main" \
		--output="$W/bin/$3" > "$W/compile-$3.log" 2>&1 || { cat "$W/compile-$3.log"; not_run "$3 did not compile"; }
}

# describe n: writes the descriptions of a job of n ranks to $W/job.N.rank.R,
# one file for each rank, readable by the user only.
describe() {
	"$W/bin/MixedDescribe" "$1" > "$W/job.$1" || not_run "no job description"
	local rank=0
	while read -r line; do
		printf '%s\n' "$line" > "$W/job.$1.rank.$rank"
		rank=$((rank + 1))
	done < "$W/job.$1"
	rm -f "$W/job.$1"
	[ "$rank" -eq "$1" ] || not_run "the description has $rank lines, not $1"
}

# start_rank job rank name program args...: starts a rank in the background
# with its description on the standard input; its output goes to
# $W/name.out and $W/name.err, its status to $W/name.status.
start_rank() {
	local job=$1 rank=$2 name=$3
	shift 3
	(
		timeout 120 "$@" < "$W/job.$job.rank.$rank" > "$W/$name.out" 2> "$W/$name.err"
		echo $? > "$W/$name.status"
	) &
	PIDS="${PIDS:-} $!"
}

# wait_ranks waits for every rank started and forgets them.
wait_ranks() {
	local pid
	for pid in $PIDS; do
		wait "$pid"
	done
	PIDS=
}

status_of() {
	cat "$W/$1.status"
}
