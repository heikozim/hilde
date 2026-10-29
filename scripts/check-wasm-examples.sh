#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The examples for WebAssembly, built and run:
#
#   examples/wasm-cli         hilde build --target=wasm, a command module run
#                             in wasmtime on input.txt; the same source built
#                             as a binary gives the same output.
#   examples/wasm-browser     a library for wasm32-wasi, run by the loader of
#                             its page (hilde-wasm.js) in node.
#   examples/wasm-cloudflare  the answer of the worker for the same library,
#                             with node's Request and Response.
#
# Each module is built with zig and with clang, the two compilers hilde
# finds for wasm32-wasi (HILDE_WASM_CC), and each output is held against the
# example's expected-stdout.txt.  The control: a copy of an expected output
# with one byte changed must not hold.
#
#     sh scripts/check-wasm-examples.sh <scratch-dir>
#
# Exit 0 when all held, 1 when one did not, 9 when it could not run (no
# hilde, no wasmtime, no node, no scratch directory).  POSIX sh.
set -u
[ $# -eq 1 ] || { echo "usage: sh scripts/check-wasm-examples.sh <scratch-dir>" >&2; exit 9; }
A=$1/wasm-examples
if ! command -v zig > /dev/null 2>&1 && [ -z "${HILDE_ZIG:-}" ] && [ -x /opt/zig/zig ]; then
	HILDE_ZIG=/opt/zig/zig
	export HILDE_ZIG
fi
[ -x ./hilde ] || { echo "check-wasm-examples: NOT RUN -- no ./hilde"; exit 9; }
for t in wasmtime node cmp; do
	command -v "$t" > /dev/null 2>&1 || { echo "check-wasm-examples: NOT RUN -- no $t"; exit 9; }
done
mkdir -p "$A" || exit 9
ZIG_GLOBAL_CACHE_DIR=$A/cache/global
ZIG_LOCAL_CACHE_DIR=$A/cache/local
export ZIG_GLOBAL_CACHE_DIR ZIG_LOCAL_CACHE_DIR
mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR" || exit 9
held=0
bad=0
ok() { held=$((held + 1)); echo "check-wasm-examples: held $1"; }
no() { bad=$((bad + 1)); echo "check-wasm-examples: BAD $1"; }
same() {
	if cmp -s "$1" "$2"; then ok "$3"; else no "$3"; diff "$2" "$1" | head -10; fi
}

M=--modules=standard/src:bindings/generated
E=examples
./hilde build $M $E/wasm-cli/WordCount.hih,$E/wasm-cli/WordCount.hiq --entrypoint=Example.WordCount:main \
	--output="$A/wordcount" > "$A/wordcount-native.log" 2>&1 \
	&& "$A/wordcount" < $E/wasm-cli/input.txt > "$A/wordcount-native.out" 2>&1
same "$A/wordcount-native.out" $E/wasm-cli/expected-stdout.txt "wasm-cli built as a binary"
for cc in zig clang; do
	HILDE_WASM_CC=$cc
	export HILDE_WASM_CC
	./hilde build $M $E/wasm-cli/WordCount.hih,$E/wasm-cli/WordCount.hiq --entrypoint=Example.WordCount:main \
		--target=wasm --output="$A/wordcount-$cc.wasm" > "$A/wordcount-$cc.log" 2>&1
	rc=$?
	if [ "$rc" = 0 ] && [ -s "$A/wordcount-$cc.wasm" ]; then ok "wasm-cli built with $cc"; else no "wasm-cli did not build with $cc ($rc)"; head -10 "$A/wordcount-$cc.log"; fi
	wasmtime run "$A/wordcount-$cc.wasm" < $E/wasm-cli/input.txt > "$A/wordcount-$cc.out" 2>&1
	same "$A/wordcount-$cc.out" $E/wasm-cli/expected-stdout.txt "wasm-cli with $cc in wasmtime"

	./hilde build --target-type=wasm $E/wasm-browser/TextStats.hiq --output="$A/text-stats-$cc.wasm" > "$A/text-stats-$cc.log" 2>&1
	rc=$?
	if [ "$rc" = 0 ] && [ -s "$A/text-stats-$cc.wasm" ]; then ok "TextStats built with $cc"; else no "TextStats did not build with $cc ($rc)"; head -10 "$A/text-stats-$cc.log"; fi
	node $E/wasm-browser/test.mjs "$A/text-stats-$cc.wasm" > "$A/browser-$cc.out" 2>&1
	same "$A/browser-$cc.out" $E/wasm-browser/expected-stdout.txt "wasm-browser with $cc in node"
	node $E/wasm-cloudflare/test.mjs "$A/text-stats-$cc.wasm" > "$A/cloudflare-$cc.out" 2>&1
	same "$A/cloudflare-$cc.out" $E/wasm-cloudflare/expected-stdout.txt "wasm-cloudflare with $cc in node"
done
unset HILDE_WASM_CC
# The control: an expected output with its first byte changed.
{ printf 'X'; tail -c +2 $E/wasm-cli/expected-stdout.txt; } > "$A/control-expected.txt"
if cmp -s "$A/wordcount-zig.out" "$A/control-expected.txt"; then no "the control: a changed expected output held"; else ok "the control: a changed expected output does not hold"; fi

echo "check-wasm-examples held=$held bad=$bad"
[ "$bad" = 0 ] || exit 1
[ "$held" -gt 0 ] || exit 1
exit 0
