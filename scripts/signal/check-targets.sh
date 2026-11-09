#!/bin/sh
# Hold hilde_sigaction_t against the real <signal.h> of every Linux target
# whose headers are on this machine, not only the host's.
#
#     sh scripts/signal/check-targets.sh <scratch-dir> [bionic-libc-dir]
#
# <scratch-dir> is passed on to scripts/signal/check-header.sh.
# [bionic-libc-dir] is the libc directory of a checkout of bionic
# (github.com/aosp-mirror/platform_bionic); without it Android is skipped.
#
# glibc and musl: scripts/signal/check-header.sh, once per target found:
#   host       cc, /usr/include
#   i386       cc -m32, when gcc-multilib is installed
#   armhf      clang --target=arm-linux-gnueabihf, /usr/arm-linux-gnueabihf/include
#   armel      clang --target=arm-linux-gnueabi, /usr/arm-linux-gnueabi/include
#   aarch64    clang --target=aarch64-linux-gnu, /usr/aarch64-linux-gnu/include
# Android: the runtime takes bionic's own struct sigaction, so the check is
# that lib/prelude/all.c, the whole runtime, compiles against bionic under
# -std=c17 for arm64, x86_64, arm and i686 at API level 29, and that
# hilde_sigaction_t is bionic's struct there.
#
# Exit 0   every target that ran agreed, and at least one ran.
# Exit 1   a target differs.
# Exit 9   nothing ran.  POSIX sh, no bashisms (SH-002).
set -u

[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: sh scripts/signal/check-targets.sh <scratch-dir> [bionic-libc-dir]" >&2; exit 9; }
scratch=$1
bionic=${2:-}
here=$(cd "$(dirname "$0")/../.." && pwd)
check="$here/scripts/signal/check-header.sh"
ran=0
failed=0

one() {
	# one <name> <cc> <include-dir> [cc-flag...]
	name=$1
	compiler=$2
	inc=$3
	shift 3
	if [ ! -r "$inc/signal.h" ] || ! command -v "$compiler" > /dev/null 2>&1; then
		echo "check-targets: $name NOT RUN -- no $inc/signal.h or no $compiler"
		return
	fi
	CC=$compiler sh "$check" "$inc" "$scratch" "$@"
	rc=$?
	echo "check-targets: $name exit=$rc"
	case $rc in
		0) ran=$((ran + 1)) ;;
		1) ran=$((ran + 1)); failed=$((failed + 1)) ;;
	esac
}

one host cc /usr/include
if [ -r /usr/include/x86_64-linux-gnu/gnu/stubs-32.h ] || [ -r /usr/include/i386-linux-gnu/gnu/stubs-32.h ]; then
	one i386 cc /usr/include -m32
else
	echo "check-targets: i386 NOT RUN -- no 32-bit glibc headers"
fi
one armhf clang /usr/arm-linux-gnueabihf/include --target=arm-linux-gnueabihf
one armel clang /usr/arm-linux-gnueabi/include --target=arm-linux-gnueabi
one aarch64 clang /usr/aarch64-linux-gnu/include --target=aarch64-linux-gnu

if [ -z "$bionic" ]; then
	echo "check-targets: android NOT RUN -- no bionic libc directory given"
elif [ ! -r "$bionic/include/signal.h" ] || ! command -v clang > /dev/null 2>&1; then
	echo "check-targets: android NOT RUN -- no $bionic/include/signal.h or no clang"
else
	probe="$scratch/check-signal-android.c"
	{
		printf '#include "%s/lib/prelude/all.c"\n' "$here"
		printf '_Static_assert(sizeof(hilde_sigaction_t) == sizeof(struct sigaction), "size");\n'
		printf '_Static_assert(offsetof(hilde_sigaction_t, sa_flags) == offsetof(struct sigaction, sa_flags), "flags");\n'
		printf '_Static_assert(HILDE_SA_RESTART == 0x10000000, "SA_RESTART");\n'
	} > "$probe"
	for pair in aarch64-linux-android29:arm64 x86_64-linux-android29:x86 armv7a-linux-androideabi29:arm i686-linux-android29:x86; do
		target=${pair%%:*}
		asm=${pair#*:}
		clang --target="$target" -std=c17 -Wall -Wextra -Werror -fsyntax-only -nostdlibinc \
			-isystem "$bionic/include" -isystem "$bionic/kernel/uapi" \
			-isystem "$bionic/kernel/uapi/asm-$asm" -isystem "$bionic/kernel/android/uapi" \
			-I"$here/lib" "$probe"
		rc=$?
		echo "check-targets: android $target exit=$rc"
		ran=$((ran + 1))
		[ "$rc" = 0 ] || failed=$((failed + 1))
	done
	rm -f "$probe"
fi

echo "check-targets: ran=$ran failed=$failed"
[ "$ran" -gt 0 ] || { echo "check-targets: NOT RUN -- no target"; exit 9; }
[ "$failed" = 0 ] || { echo "check-targets: FAIL"; exit 1; }
echo "check-targets: OK"
exit 0
