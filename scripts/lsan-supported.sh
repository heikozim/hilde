#!/bin/sh
# Whether LeakSanitizer works on this system: prints yes, no or unknown.
#
#     sh scripts/lsan-supported.sh <scratch-directory>
#
# A programme that loses a buffer is built with AddressSanitizer and run with
# detect_leaks=1.  yes: LeakSanitizer reports the lost buffer.  no: the
# system answers that detect_leaks is not supported on this platform and
# reports nothing -- FreeBSD does, so a green run under AddressSanitizer
# there is not a leak check (PIT-027).  unknown: the programme could not be
# built, or said neither; a system that refuses the sanitizers is refused by
# the checks that need them, with H1021.  The pointer is volatile so that no
# compiler drops the allocation.  The files it makes in the scratch
# directory are removed.
#
# Exit 0 whenever it printed an answer, 9 when it did not run.  POSIX sh, no
# bashisms (SH-002).
set -u

[ $# -eq 1 ] && [ -d "$1" ] || { echo "usage: sh scripts/lsan-supported.sh <scratch-directory>" >&2; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "lsan-supported: NOT RUN -- no cc" >&2; exit 9; }
f=$1/lsan-probe
printf '%s\n' '#include <stdlib.h>' 'int main(void) { char* volatile p = malloc(100); p[0] = 1; p = 0; return 0; }' > "$f.c"
answer=unknown
if cc -std=c17 -fsanitize=address -g -O1 -o "$f" "$f.c" > "$f.cc" 2>&1; then
	ASAN_OPTIONS=detect_leaks=1 "$f" > "$f.out" 2>&1
	if grep -q 'LeakSanitizer: detected memory leaks' "$f.out"; then
		answer=yes
	elif grep -q 'detect_leaks is not supported' "$f.out"; then
		answer=no
	fi
fi
rm -f "$f" "$f.c" "$f.cc" "$f.out"
echo "$answer"
exit 0
