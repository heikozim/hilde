#!/usr/bin/env bash
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

# The sum example over several processes on one machine, from the root of
# the tree after make:
#
#     bash scripts/sperli/loopback-probe.sh [hilde]
#
# Builds examples/sperli-sum and runs it with hilde run as jobs of 2, 3
# and 4 ranks whose host lists name 127.0.0.1, and one of 2 ranks on
# localhost and 127.0.0.1; every job is TLS 1.3 with a certificate on both
# sides, and rank 0 must print the total of the 3,000,000 rows.  Then a
# rank 1 that listens alone meets three clients that are wrong: plain
# bytes, a client that offers TLS 1.2 at most, and a TLS 1.3 client without
# a certificate.  Each must end the rank with H1601 and none may reach the
# job.  After every job no credential directory may stay in the working
# directory.  Each command and its output are printed.  Needs hilde with
# hilde-launcher beside it, and openssl for the clients.  Exit 0 when every
# check held, 1 when one failed, 9 when it could not run.
set -u
. scripts/sperli/lib.sh

HILDE=${1:-./hilde}
[ -x "$HILDE" ] || not_run "no hilde at $HILDE"
HILDE=$(cd "$(dirname "$HILDE")" && pwd)/$(basename "$HILDE")
[ -x "$(dirname "$HILDE")/hilde-launcher" ] || not_run "no hilde-launcher beside $HILDE; make builds it"
command -v openssl > /dev/null 2>&1 || not_run "no openssl"
command -v python3 > /dev/null 2>&1 || not_run "no python3"

FAILS=0
check() {
	if [ "$2" = ok ]; then
		echo "ok   $1"
	else
		echo "FAIL $1: $2"
		FAILS=$((FAILS + 1))
	fi
}

no_credentials() {
	if compgen -G "$W/run/sperli-*" > /dev/null; then
		echo "left: $(cd "$W/run" && echo sperli-*)"
	else
		echo ok
	fi
}

make_work
compile examples/sperli-sum/SperliSum.hih,examples/sperli-sum/SperliSum.hiq Example.SperliSum SperliSum
compile libsperli/test/mixed/MixedDescribe.hiq Mixed.Describe MixedDescribe
mkdir "$W/run" || not_run "cannot make $W/run"
SUM="rows=3000000 total=4500001500000 expected=4500001500000 ok"

# sum_job name ranks host...: one job through hilde run on the hosts given.
sum_job() {
	local name=$1 ranks=$2
	shift 2
	printf '%s\n' "$@" > "$W/run/hosts-$name.txt"
	echo "\$ hilde run -n $ranks --hosts hosts-$name.txt ./sperli-sum    # hosts: $*"
	(cd "$W/run" && timeout 120 "$HILDE" run -n "$ranks" --hosts "hosts-$name.txt" "$W/bin/SperliSum") > "$W/$name.out" 2>&1
	local status=$?
	cat "$W/$name.out"
	echo "exit $status"
	if [ "$status" = 0 ] && grep -q -- "^\[rank 0\] $SUM\$" "$W/$name.out"; then
		check "$name" ok
	else
		check "$name" "exit $status"
	fi
	check "$name leaves no credentials" "$(no_credentials)"
}

sum_job two 2 127.0.0.1 127.0.0.1
sum_job three 3 127.0.0.1 127.0.0.1 127.0.0.1
sum_job four 4 127.0.0.1 127.0.0.1 127.0.0.1 127.0.0.1
sum_job named 2 localhost 127.0.0.1

# The port of rank 1 in a description of a job of 2 ranks: the hosts begin
# at byte 36, each port (2 bytes), length (2 bytes), name.
port_of_rank_1() {
	python3 -I -c '
import sys
b = bytes.fromhex(sys.stdin.readline().strip())
at = 36
n = b[at + 2] | (b[at + 3] << 8)
at += 4 + n
print(b[at] | (b[at + 1] << 8))' < "$1"
}

# wrong_client name: a fresh job of 2 ranks, rank 1 listening alone, and a
# client that is wrong in the way name says.
wrong_client() {
	local name=$1
	"$W/bin/MixedDescribe" 2 > "$W/job.all" || not_run "no job description"
	head -1 "$W/job.all" > "$W/job.0"
	tail -1 "$W/job.all" > "$W/job.1"
	rm -f "$W/job.all" "$W/job.0"
	local port
	port=$(port_of_rank_1 "$W/job.1")
	(cd "$W/run" && timeout 60 "$W/bin/SperliSum" < "$W/job.1") > "$W/$name.rank" 2>&1 &
	local rank=$!
	sleep 1
	case $name in
	plain)
		printf '%s\n' "\$ printf 'GET / HTTP/1.0\\r\\n\\r\\n' > /dev/tcp/127.0.0.1/$port"
		printf 'GET / HTTP/1.0\r\n\r\n' | timeout 10 bash -c "cat > /dev/tcp/127.0.0.1/$port"
		;;
	tls12)
		echo "\$ openssl s_client -connect 127.0.0.1:$port -tls1_2"
		timeout 10 openssl s_client -connect 127.0.0.1:"$port" -tls1_2 < /dev/null > "$W/$name.client" 2>&1
		echo "client exit $?: $(grep -m1 -iE 'alert|no protocols|wrong version|error' "$W/$name.client")"
		;;
	nocert)
		echo "\$ openssl s_client -connect 127.0.0.1:$port -tls1_3    # no certificate"
		printf 'x' | timeout 10 openssl s_client -connect 127.0.0.1:"$port" -tls1_3 -ign_eof > "$W/$name.client" 2>&1
		echo "client exit $?: $(grep -m1 -iE 'alert|certificate required|error' "$W/$name.client")"
		;;
	esac
	wait "$rank"
	local status=$?
	echo "rank 1 exit $status: $(head -c 200 "$W/$name.rank")"
	rm -f "$W/job.1"
	if [ "$status" != 0 ] && grep -q '^init failed with 1601$' "$W/$name.rank"; then
		check "$name client refused" ok
	else
		check "$name client refused" "rank 1 exit $status"
	fi
	check "$name leaves no credentials" "$(no_credentials)"
}

wrong_client plain
wrong_client tls12
wrong_client nocert
echo "sperli loopback: $FAILS failed"
[ "$FAILS" -eq 0 ]
