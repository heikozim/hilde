#!/bin/sh
# Hold the runtime's own declaration of struct addrinfo and the four EAI_
# numbers it sorts answers by against the REAL <netdb.h>.
#
#     sh scripts/resolver/check-header.sh <include-dir> <scratch-dir>
#
# <include-dir> holds the real netdb.h: /usr/include on Debian, on OpenBSD
# and on FreeBSD, the SDK's usr/include on macOS.  <scratch-dir> is where
# the small C files of the check are written; it must exist, and nothing
# else in it is touched.
#
# Under -std=c17 glibc's <netdb.h> declares neither getaddrinfo nor struct
# addrinfo, so lib/prelude.c declares the struct itself, as hilde_addrinfo_t,
# and reaches getaddrinfo and freeaddrinfo through asm labels.  This check
# takes that typedef and the HILDE_EAI_ numbers out of lib/prelude.c,
# compiles them beside the real header, and asserts:
#   - the same size and the same offset for each of the eight fields; the
#     order of ai_addr and ai_canonname is the system's, FreeBSD and macOS
#     have the BSD order and Linux and OpenBSD the other;
#   - the address of a sockaddr_in at offset 4 and of a sockaddr_in6 at
#     offset 8, 4 and 16 bytes long, as hilde_resolve reads them;
#   - HILDE_EAI_NONAME, HILDE_EAI_AGAIN, HILDE_EAI_FAIL and HILDE_EAI_NODATA
#     equal to the header's EAI_ values, the numbers hilde_resolve sorts the
#     answers by: -2, -3, -4 and -5 on Linux and OpenBSD, 8, 2, 4 and 7 on
#     FreeBSD and macOS.
# On Linux the check compiles with _GNU_SOURCE, which shows glibc's
# EAI_NODATA; elsewhere with no feature macro, as the programmes are.
# It then proves it CAN fail, twice (TEST-011): the typedef with two fields
# swapped must not compile, and neither must the numbers with one of them
# changed.
#
# Exit 0   the declaration agrees with the header, and both negative
#          controls failed as they must.
# Exit 1   the declaration differs from the header.
# Exit 9   did not run: no header, no compiler, no typedef found, or a
#          negative control that compiled.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -eq 2 ] || { echo "usage: sh scripts/resolver/check-header.sh <include-dir> <scratch-dir>" >&2; exit 9; }
inc=$1
scratch=$2
here=$(cd "$(dirname "$0")/../.." && pwd)
prelude="$here/lib/prelude.c"
[ -r "$inc/netdb.h" ] || { echo "check-header: NOT RUN -- $inc/netdb.h is not readable"; exit 9; }
[ -r "$prelude" ] || { echo "check-header: NOT RUN -- $prelude is not readable"; exit 9; }
[ -d "$scratch" ] || { echo "check-header: NOT RUN -- $scratch is not a directory"; exit 9; }
command -v cc > /dev/null 2>&1 || { echo "check-header: NOT RUN -- no cc"; exit 9; }

echo "check-header: header $inc/netdb.h"
echo "check-header: copy $prelude, typedef hilde_addrinfo_t and the HILDE_EAI_ numbers"

decl="$scratch/check-resolver-decl.h"
baddecl="$scratch/check-resolver-bad.h"
eai="$scratch/check-resolver-eai.h"
badeai="$scratch/check-resolver-bad-eai.h"
good="$scratch/check-resolver-good.c"
bad="$scratch/check-resolver-bad.c"
bad2="$scratch/check-resolver-bad2.c"

cleanup() {
	rm -f "$decl" "$baddecl" "$eai" "$badeai" "$good" "$bad" "$bad2"
}

sed -n '/^typedef struct hilde_addrinfo {$/,/^} hilde_addrinfo_t;$/p' "$prelude" > "$decl"
lines=$(wc -l < "$decl" | tr -d ' ')
echo "check-header: typedef lines=$lines (want 15)"
if [ "$lines" != 15 ]; then
	echo "check-header: NOT RUN -- the typedef was not found whole in lib/prelude.c"
	cleanup
	exit 9
fi

# The numbers: the #if block of lib/prelude.c whose first line after the #if
# defines a HILDE_EAI_ value, up to its #endif.
awk '/^#if defined\(__FreeBSD__\) \|\| defined\(__APPLE__\)$/ { held = $0; next }
	held != "" { if ($0 ~ /^#define HILDE_EAI_/) { print held; on = 1 } held = "" }
	on { print }
	on && /^#endif$/ { exit }' "$prelude" > "$eai"
eailines=$(wc -l < "$eai" | tr -d ' ')
echo "check-header: HILDE_EAI lines=$eailines (want 11)"
if [ "$eailines" != 11 ]; then
	echo "check-header: NOT RUN -- the HILDE_EAI numbers were not found whole in lib/prelude.c"
	cleanup
	exit 9
fi

feature=
[ "$(uname -s)" = Linux ] && feature='#define _GNU_SOURCE 1'

program() {
	# program <declaration> <numbers> <output>
	{
		printf '%s\n' "$feature"
		printf '#include <stddef.h>\n#include <stdint.h>\n#include <sys/types.h>\n'
		printf '#include <sys/socket.h>\n#include <netinet/in.h>\n#include <netdb.h>\n'
		printf '#include "%s"\n#include "%s"\n' "$1" "$2"
		printf '_Static_assert(sizeof(hilde_addrinfo_t) == sizeof(struct addrinfo), "size");\n'
		for f in ai_flags ai_family ai_socktype ai_protocol ai_addrlen ai_addr ai_canonname ai_next; do
			printf '_Static_assert(offsetof(hilde_addrinfo_t, %s) == offsetof(struct addrinfo, %s), "%s");\n' "$f" "$f" "$f"
			printf '_Static_assert(sizeof(((hilde_addrinfo_t*) 0)->%s) == sizeof(((struct addrinfo*) 0)->%s), "size of %s");\n' "$f" "$f" "$f"
		done
		printf '_Static_assert(offsetof(struct sockaddr_in, sin_addr) == 4, "sin_addr at 4");\n'
		printf '_Static_assert(sizeof(struct in_addr) == 4, "an IPv4 address is 4 bytes");\n'
		printf '_Static_assert(offsetof(struct sockaddr_in6, sin6_addr) == 8, "sin6_addr at 8");\n'
		printf '_Static_assert(sizeof(struct in6_addr) == 16, "an IPv6 address is 16 bytes");\n'
		printf '_Static_assert(HILDE_EAI_NONAME == EAI_NONAME, "EAI_NONAME");\n'
		printf '_Static_assert(HILDE_EAI_AGAIN == EAI_AGAIN, "EAI_AGAIN");\n'
		printf '_Static_assert(HILDE_EAI_FAIL == EAI_FAIL, "EAI_FAIL");\n'
		printf '_Static_assert(HILDE_EAI_NODATA == EAI_NODATA, "EAI_NODATA");\n'
		printf 'int main(void) { return 0; }\n'
	} > "$3"
}

program "$decl" "$eai" "$good"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$good"
rc=$?
echo "check-header: declaration against header, cc-exit=$rc"

# The first negative control: ai_addr and ai_canonname swapped, as the
# other order has them.  Both branches of the typedef are swapped, so on
# every system the declaration that is compiled differs from the header.
sed -e 's/^  void\* ai_addr;$/  HILDE_SWAP_ADDR/' -e 's/^  char\* ai_canonname;$/  void* ai_addr;/' -e 's/^  HILDE_SWAP_ADDR$/  char* ai_canonname;/' "$decl" > "$baddecl"
if cmp -s "$decl" "$baddecl"; then
	echo "check-header: NOT RUN -- the negative control changed nothing"
	cleanup
	exit 9
fi
program "$baddecl" "$eai" "$bad"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad" > /dev/null 2>&1
nrc=$?
echo "check-header: negative control (ai_addr and ai_canonname swapped), cc-exit=$nrc"

# The second: HILDE_EAI_NONAME given the number 99 in every branch.
sed -e 's/^#define HILDE_EAI_NONAME .*$/#define HILDE_EAI_NONAME 99/' "$eai" > "$badeai"
if cmp -s "$eai" "$badeai"; then
	echo "check-header: NOT RUN -- the second negative control changed nothing"
	cleanup
	exit 9
fi
program "$decl" "$badeai" "$bad2"
cc -std=c17 -Wall -Wextra -Werror -fsyntax-only -I"$inc" "$bad2" > /dev/null 2>&1
nrc2=$?
echo "check-header: negative control (HILDE_EAI_NONAME changed), cc-exit=$nrc2"
cleanup

if [ "$nrc" = 0 ] || [ "$nrc2" = 0 ]; then
	echo "check-header: NOT RUN -- a negative control compiled, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ]; then
	echo "check-header: FAIL -- the declaration differs from the header"
	exit 1
fi
echo "check-header: OK"
exit 0
