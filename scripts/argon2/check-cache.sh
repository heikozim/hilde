#!/bin/sh
# The working memory cache of libargon2 under several threads.
#
#     sh scripts/argon2/check-cache.sh <scratch-dir>
#
# <scratch-dir> is where the built programmes lie; it must exist, and
# nothing else in it is touched.  The test source is
# scripts/argon2/cache-test.c: eight threads take memory through
# hilde_argon2_allocate and give it back through hilde_argon2_free at the
# same time, with three sizes, and the test's own line says whether two
# threads ever held one block.
#
# The programme is built twice: plain, and with -fsanitize=thread at -O1,
# where a data race of the cache ends the run.  A system whose cc has no
# thread sanitizer runs the plain build only and the sanitizer line says
# NOT RUN with the reason the compiler gives.
#
# Exit 0  the plain run passed, and so did the sanitizer run or the system
#         has none; 1  a run failed; 9  nothing ran.  POSIX sh, no
#         bashisms.
set -u

usage="usage: sh scripts/argon2/check-cache.sh <scratch-dir>"
[ $# -eq 1 ] || { echo "$usage" >&2; exit 9; }
out=$1
[ -d "$out" ] || { echo "argon2-cache: NOT RUN -- $out is not a directory"; exit 9; }
src=scripts/argon2/cache-test.c
[ -r "$src" ] || { echo "argon2-cache: NOT RUN -- $src is missing"; exit 9; }
[ -r lib/prelude/all.c ] || { echo "argon2-cache: NOT RUN -- lib/prelude/all.c is missing"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "argon2-cache: NOT RUN -- cc is not on PATH"; exit 9; }

bad=0

cc -std=c17 -O1 -g -Wall -Wextra -pthread "$src" -o "$out/cache-plain" > "$out/cache-plain-build.log" 2>&1
rc=$?
warnings=$(grep -c ': warning:' "$out/cache-plain-build.log")
echo "argon2-cache-plain-build-exit=$rc warnings=$warnings"
if [ "$rc" != 0 ] || [ "$warnings" != 0 ]; then
	sed -n '1,20p' "$out/cache-plain-build.log"
	bad=$((bad + 1))
else
	"$out/cache-plain" > "$out/cache-plain-run.log" 2>&1
	rc=$?
	echo "argon2-cache-plain-exit=$rc"
	cat "$out/cache-plain-run.log"
	[ "$rc" = 0 ] || bad=$((bad + 1))
fi

printf 'int main(void) { return 0; }\n' > "$out/tsan-probe.c"
cc -fsanitize=thread -O1 -g -pthread "$out/tsan-probe.c" -o "$out/tsan-probe" > "$out/tsan-probe.log" 2>&1
rc=$?
if [ "$rc" != 0 ]; then
	echo "argon2-cache-tsan: NOT RUN -- cc refuses -fsanitize=thread (exit $rc): $(sed -n '1p' "$out/tsan-probe.log")"
else
	cc -std=c17 -fsanitize=thread -O1 -g -pthread "$src" -o "$out/cache-tsan" > "$out/cache-tsan-build.log" 2>&1
	rc=$?
	echo "argon2-cache-tsan-build-exit=$rc"
	if [ "$rc" != 0 ]; then
		sed -n '1,20p' "$out/cache-tsan-build.log"
		bad=$((bad + 1))
	else
		TSAN_OPTIONS="exitcode=66 halt_on_error=1" "$out/cache-tsan" > "$out/cache-tsan-run.log" 2>&1
		rc=$?
		echo "argon2-cache-tsan-exit=$rc"
		cat "$out/cache-tsan-run.log"
		[ "$rc" = 0 ] || bad=$((bad + 1))
	fi
fi

echo "argon2-cache-failed-steps=$bad"
[ "$bad" = 0 ] || exit 1
exit 0
