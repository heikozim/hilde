#!/bin/sh
# Hold bindings/fixtures/argon2.h against a REAL argon2.h.
#
#     sh scripts/argon2/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real argon2.h: /usr/include on Debian with
# libargon2-dev, /usr/local/include on OpenBSD with the argon2 package.
# <scratch-dir> is where the small C files of the check are written; it must
# exist, and nothing else in it is touched.
#
# The copy is compiled together with <argon2.h>.  C takes a function
# declaration and a typedef twice only when both say the same, so every
# line of the copy that differs from the header -- a type, a `const', the
# structure the typedef names -- stops the compile.  The check then proves
# it CAN stop: a copy of the copy with one return type changed must fail
# (TEST-011).
#
# It also prints what Bindings.Argon2 relies on without copying it: the
# version the header numbers 0x13, and the size of argon2_context, which
# the binding asks the header for when a program is compiled.
#
# Exit 0   the copy agrees with the header, and the negative control failed
#          as it must.
# Exit 1   the copy differs from the header.
# Exit 9   did not run: no header, no compiler, or a negative control that
#          passed.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/argon2/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
copy="$here/bindings/fixtures/argon2.h"
[ -r "$inc/argon2.h" ] || { echo "check-header: NOT RUN -- $inc/argon2.h is not readable"; exit 9; }
[ -r "$copy" ] || { echo "check-header: NOT RUN -- $copy is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

echo "check-header: header $inc/argon2.h"
echo "check-header: copy $copy"

good="$scratch/check-argon2-good.c"
bad="$scratch/check-argon2-bad.c"
badcopy="$scratch/check-argon2-bad.h"

{
	printf '#include <argon2.h>\n#include "%s"\n' "$copy"
	printf '_Static_assert(ARGON2_VERSION_13 == 0x13, "the version the binding writes");\n'
	printf '_Static_assert(ARGON2_OK == 0, "the result the binding takes as success");\n'
	printf 'int main(void) { return (int)sizeof(argon2_context); }\n'
} > "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: copy against header, cc-exit=$rc"

# The negative control: argon2id_ctx made to return a long.
sed 's/^int argon2id_ctx(argon2_context \*context);$/long argon2id_ctx(argon2_context *context);/' "$copy" > "$badcopy"
if cmp -s "$copy" "$badcopy"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	rm -f "$good" "$bad" "$badcopy"
	exit 9
fi
printf '#include <argon2.h>\n#include "%s"\nint main(void) { return 0; }\n' "$badcopy" > "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (argon2id_ctx returning long), cc-exit=$nrc"
rm -f "$good" "$bad" "$badcopy"

if [ "$nrc" = 0 ]; then
	echo "check-header: NOT RUN -- the negative control compiled, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ]; then
	echo "check-header: FAIL -- the copy differs from the header"
	exit 1
fi
echo "check-header: OK"
exit 0
