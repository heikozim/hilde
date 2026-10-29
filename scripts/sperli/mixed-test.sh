#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The mixed tests of Sperli, from the root of the tree:
#
#     bash scripts/sperli/mixed-test.sh
#
# 1. The sum of 3000000 rows over 3 ranks with rank 0 a Hilde programme and
#    ranks 1 and 2 the Go rank program, and over 3 Hilde ranks.
# 2. A Hilde rank 0 that is wrong in one way meets a Go rank 1, which must
#    refuse it: a certificate of another CA, no certificate, an expired
#    token, a token of another job, a token of another rank, an oversized
#    frame.  A client that is right is let in.
# 3. The Go rank program refuses a host list that names a host it refuses:
#    the Go test the regular expression SPERLI_GO_REFUSED_TEST matches
#    must run and pass.  The default matches no test, so the check fails
#    until the variable names one.
#
# Exit 0 when every check held, 1 when one failed, 9 when it could not run.
# The ranks start in the order 2, 1, 0 with a second between them, since the
# library does not wait for a rank that does not listen yet.
set -u
. scripts/sperli/lib.sh

FAILS=0
check() {
	if [ "$2" = ok ]; then
		echo "ok   $1"
	else
		echo "FAIL $1: $2"
		FAILS=$((FAILS + 1))
	fi
}

contains() {
	grep -q -- "$2" "$1" && echo ok || echo "no '$2' in $1: $(head -c 300 "$1")"
}

make_work
build_all
SUM="rows=3000000 total=4500001500000 expected=4500001500000 ok"

# One job of three ranks; the programme of each rank is given.
sum_job() {
	local name=$1 p1=$2 p2=$3 p0=$4
	describe 3
	PIDS=
	start_rank 3 2 "$name-2" "$p2" -mode sum
	sleep 1
	start_rank 3 1 "$name-1" "$p1" -mode sum
	sleep 1
	start_rank 3 0 "$name-0" "$p0"
	wait_ranks
	local r
	for r in 0 1 2; do
		[ "$(status_of "$name-$r")" = 0 ] || { check "$name rank $r exit status" "$(status_of "$name-$r"): $(head -c 300 "$W/$name-$r.err")"; return; }
	done
	check "$name total" "$(contains "$W/$name-0.out" "$SUM")"
}

GO="$W/bin/sperli-rank"
HI="$W/bin/SperliSum"
sum_job mixed "$GO" "$GO" "$HI"
sum_job hilde "$HI" "$HI" "$HI"

# A Go rank 1 of a job of two ranks, and a Hilde rank 0 with a fault.
reject() {
	local fault=$1 want=$2 dir="$W/reject-$1"
	mkdir "$dir"
	( cd "$dir" && timeout 120 "$W/bin/MixedReject" "$fault" "$dir/rank1" > "$dir/hilde.out" 2>&1; echo $? > "$dir/hilde.status" ) &
	local hilde=$! tries=0
	while [ ! -s "$dir/rank1" ] && [ "$tries" -lt 100 ]; do
		sleep 0.1
		tries=$((tries + 1))
	done
	[ -s "$dir/rank1" ] || { check "$fault" "no description of rank 1"; wait "$hilde"; return; }
	( cd "$dir" && timeout 120 "$GO" -mode sink -count 1 -peer 0 < "$dir/rank1" > "$dir/go.out" 2> "$dir/go.err"; echo $? > "$dir/go.status" )
	wait "$hilde"
	if [ "$want" = none ]; then
		[ "$(cat "$dir/go.status")" = 0 ] && check "$fault: let in" ok || check "$fault: let in" "go status $(cat "$dir/go.status"): $(head -c 300 "$dir/go.err")"
		return
	fi
	[ "$(cat "$dir/go.status")" = 1 ] || { check "$fault: refused" "go status $(cat "$dir/go.status"), not 1"; return; }
	check "$fault: refused with $want" "$(contains "$dir/go.err" "$want")"
}

reject good none
reject wrong-ca SPERLI_BAD_CERTIFICATE
reject no-cert SPERLI_BAD_CERTIFICATE
reject expired SPERLI_TOKEN_EXPIRED
reject foreign-job SPERLI_TOKEN_FOREIGN_JOB
reject wrong-rank SPERLI_TOKEN_WRONG_RANK
reject oversized SPERLI_OVERSIZED_FRAME

# A refused host is refused although it is listed.  go test passes when no
# test matches, so a line of a passed test is asked for as well.
REFUSED_TEST=${SPERLI_GO_REFUSED_TEST:-^TestRefusedHostPlaceholder$}
if (cd "$W/go" && CGO_ENABLED=1 go test ./cmd/sperli-rank -v -run "$REFUSED_TEST" -count=1 > "$W/refused.log" 2>&1); then
	grep -q -- '^--- PASS' "$W/refused.log" && check "refused host" ok || check "refused host" "no Go test matched $REFUSED_TEST; set SPERLI_GO_REFUSED_TEST"
else
	check "refused host" "$(head -c 300 "$W/refused.log")"
fi

echo "sperli mixed: $FAILS failed"
[ "$FAILS" -eq 0 ]
