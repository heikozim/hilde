#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Latency and bandwidth of Sperli over TLS 1.3 on localhost, from the root of
# the tree:
#
#     bash scripts/sperli/bench.sh [pings [stream-messages]]
#
# Latency: pings round trips of 64 bytes (default 1000).  Bandwidth:
# stream-messages messages of 1 MiB sent one way (default 32), in MB/s of
# 10^6 bytes.  Both are measured for Hilde and Hilde, Hilde and Go (rank 0 is
# Hilde, rank 1 is the Go rank program) and Go and Go.  One line of numbers is
# printed for each run.  Exit 0 when every run finished, 1 when one failed,
# 9 when it could not run.
set -u
. scripts/sperli/lib.sh

PINGS=${1:-1000}
MESSAGES=${2:-32}
FAILS=0
make_work
build_all
describe 2

HB="$W/bin/SperliBench"
GO="$W/bin/sperli-rank"

# run label rank0-programme rank1-programme: the two ranks of one pair.
# $MODE0 and $MODE1 are the arguments of the two, as words.
run() {
	local label=$1 p0=$2 p1=$3
	PIDS=
	start_rank 2 1 "$label-1" $p1 $ARGS1
	sleep 1
	start_rank 2 0 "$label-0" $p0 $ARGS0
	wait_ranks
	if [ "$(status_of "$label-0")" != 0 ] || [ "$(status_of "$label-1")" != 0 ]; then
		echo "FAIL $label: $(head -c 300 "$W/$label-0.err") $(head -c 300 "$W/$label-1.err") $(head -c 200 "$W/$label-0.out")"
		FAILS=$((FAILS + 1))
		return
	fi
	echo "$label: $(head -1 "$W/$label-0.out")"
}

pair() {
	local name=$1 p0=$2 p1=$3 kind0=$4
	if [ "$kind0" = hilde ]; then
		ARGS0="ping $PINGS 64"
	else
		ARGS0="-mode ping -peer 1 -count $PINGS -msg-size 64"
	fi
	if [ "$p1" = "$HB" ]; then
		ARGS1="echo $PINGS 64"
	else
		ARGS1="-mode echo -count $PINGS"
	fi
	run "$name-latency" "$p0" "$p1"
	if [ "$kind0" = hilde ]; then
		ARGS0="stream $MESSAGES 1048576"
	else
		ARGS0="-mode stream -peer 1 -count $MESSAGES -msg-size 1048576"
	fi
	if [ "$p1" = "$HB" ]; then
		ARGS1="sink $MESSAGES 1048576"
	else
		ARGS1="-mode sink -count $MESSAGES"
	fi
	run "$name-bandwidth" "$p0" "$p1"
}

# The Go rank takes its peer from -peer: rank 1 serves rank 0.
pair hilde-hilde "$HB" "$HB" hilde
pair hilde-go "$HB" "$GO" hilde
pair go-go "$GO" "$GO" go
echo "sperli bench: $FAILS failed"
[ "$FAILS" -eq 0 ]
