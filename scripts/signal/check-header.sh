#!/bin/sh
# Hold the runtime's own declaration of struct sigaction against the REAL
# <signal.h>.
#
#     sh scripts/signal/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real signal.h: /usr/include on Debian.
# <scratch-dir> is where the small C files of the check are written; it
# must exist, and nothing else in it is touched.
#
# Under -std=c17 glibc's <signal.h> declares neither struct sigaction nor
# sigaction nor SA_RESTART, so lib/prelude.c declares the struct itself, as
# hilde_sigaction_t, reaches sigaction through an asm label and writes
# SA_RESTART as HILDE_SA_RESTART.  On OpenBSD the runtime takes the
# header's own struct, so there is nothing to hold, and this check is run
# by the Linux gate only.  It takes the typedef and the value out of
# lib/prelude.c, compiles them beside the real header with _GNU_SOURCE,
# and asserts:
#   - the same size, and the same offset and size for the handler, the
#     mask, the flags and the restorer;
#   - HILDE_SA_RESTART equal to SA_RESTART.
# It then proves it CAN fail: the typedef with the flags and the restorer
# swapped must not compile (TEST-011).
#
# Exit 0   the declaration agrees with the header, and the negative control
#          failed as it must.
# Exit 1   the declaration differs from the header.
# Exit 9   did not run: not Linux, no header, no compiler, no typedef
#          found, or a negative control that compiled.  POSIX sh, no
#          bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/signal/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
prelude="$here/lib/prelude.c"
[ "$(uname -s)" = Linux ] || { echo "check-header: NOT RUN -- the runtime declares struct sigaction only on Linux"; exit 9; }
[ -r "$inc/signal.h" ] || { echo "check-header: NOT RUN -- $inc/signal.h is not readable"; exit 9; }
[ -r "$prelude" ] || { echo "check-header: NOT RUN -- $prelude is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

echo "check-header: header $inc/signal.h"
echo "check-header: copy $prelude, typedef hilde_sigaction_t"

decl="$scratch/check-signal-decl.h"
baddecl="$scratch/check-signal-bad.h"
good="$scratch/check-signal-good.c"
bad="$scratch/check-signal-bad.c"

sed -n '/^typedef struct hilde_sigaction {$/,/^} hilde_sigaction_t;$/p' "$prelude" > "$decl"
lines=$(wc -l < "$decl" | tr -d ' ')
echo "check-header: typedef lines=$lines (want 6)"
restart=$(sed -n 's/^#define HILDE_SA_RESTART \(0x[0-9a-fA-F]*\)$/\1/p' "$prelude")
echo "check-header: HILDE_SA_RESTART=[$restart]"
if [ "$lines" != 6 ] || [ -z "$restart" ]; then
	echo "check-header: NOT RUN -- the typedef or HILDE_SA_RESTART was not found in lib/prelude.c"
	rm -f "$decl"
	exit 9
fi

program() {
	# program <declaration> <output>
	{
		printf '#define _GNU_SOURCE 1\n'
		printf '#include <stddef.h>\n#include <stdint.h>\n#include <signal.h>\n'
		printf '#include "%s"\n' "$1"
		printf '_Static_assert(sizeof(hilde_sigaction_t) == sizeof(struct sigaction), "size");\n'
		for pair in handler:sa_handler mask:sa_mask flags:sa_flags restorer:sa_restorer; do
			mine=${pair%%:*}
			theirs=${pair#*:}
			printf '_Static_assert(offsetof(hilde_sigaction_t, %s) == offsetof(struct sigaction, %s), "%s");\n' "$mine" "$theirs" "$mine"
			printf '_Static_assert(sizeof(((hilde_sigaction_t*) 0)->%s) == sizeof(((struct sigaction*) 0)->%s), "size of %s");\n' "$mine" "$theirs" "$mine"
		done
		printf '_Static_assert(%s == SA_RESTART, "SA_RESTART");\n' "$restart"
		printf 'int main(void) { return 0; }\n'
	} > "$2"
}

program "$decl" "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: declaration against header, cc-exit=$rc"

# The negative control: the flags and the restorer swapped.
sed -e 's/^  int flags;$/  HILDE_SWAP_FLAGS/' -e 's/^  void (\*restorer)(void);$/  int flags;/' -e 's/^  HILDE_SWAP_FLAGS$/  void (*restorer)(void);/' "$decl" > "$baddecl"
if cmp -s "$decl" "$baddecl"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$decl" "$baddecl" "$good" "$bad"
	exit 9
fi
program "$baddecl" "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (flags and restorer swapped), cc-exit=$nrc"
rm -f "$decl" "$baddecl" "$good" "$bad"

if [ "$nrc" = 0 ]; then
	echo "check-header: NOT RUN -- the negative control compiled, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ]; then
	echo "check-header: FAIL -- the declaration differs from the header"
	exit 1
fi
echo "check-header: OK"
exit 0
