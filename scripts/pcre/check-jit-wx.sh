#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The PCRE2 a Hilde program is linked with makes machine code without a
# mapping that is writable and executable at once
#.  Linux only: it
# reads /proc/self/maps.
#
#     sh scripts/pcre/check-jit-wx.sh <scratch-dir>
#
# scripts/pcre/jit-wx.c is built with the flags pkg-config gives for
# libpcre2-8, the flags the compiler and the test runner link a program
# with, and run: the JIT must be built in, every pattern must get
# machine code, every search must find, and no mapping may be writable and
# executable.  ldd of that binary must name no shared PCRE2, so the static
# library of the image is the one that ran.
#
# The negative control links the same probe with the shared library of
# Debian's libpcre2-8-0, whose JIT maps its code writable and executable:
# it must show such a mapping, and ldd must name that library, or the check
# could not fail and does not count.
#
# Exit 0 held, 1 a step failed, 9 did not run.  POSIX sh.
set -u

[ $# -eq 1 ] || { echo "usage: sh scripts/pcre/check-jit-wx.sh <scratch-dir>" >&2; exit 9; }
scratch=$1
here=$(cd "$(dirname "$0")/../.." && pwd)
probe=$here/scripts/pcre/jit-wx.c
[ -d "$scratch" ] || { echo "check-jit-wx: NOT RUN -- $scratch is not a directory"; exit 9; }
[ -r "$probe" ] || { echo "check-jit-wx: NOT RUN -- $probe is not readable"; exit 9; }
[ "$(uname -s)" = Linux ] || { echo "check-jit-wx: NOT RUN -- needs /proc/self/maps of Linux"; exit 9; }
for t in cc pkg-config ldd; do
	command -v "$t" > /dev/null 2>&1 || { echo "check-jit-wx: NOT RUN -- no $t"; exit 9; }
done
pkg-config --exists libpcre2-8 || { echo "check-jit-wx: NOT RUN -- pkg-config knows no libpcre2-8"; exit 9; }
multiarch=$(cc -print-multiarch 2> /dev/null)
system=/usr/lib/$multiarch/libpcre2-8.so.0
[ -n "$multiarch" ] && [ -r "$system" ] || { echo "check-jit-wx: NOT RUN -- no $system for the negative control"; exit 9; }

own=$scratch/jit-wx-own
ctl=$scratch/jit-wx-system
cflags=$(pkg-config --cflags libpcre2-8)
libs=$(pkg-config --libs libpcre2-8)
echo "check-jit-wx: pkg-config libpcre2-8 $(pkg-config --modversion libpcre2-8), libs:" $libs

# Unquoted on purpose: pkg-config's answers are lists of words.
cc -std=c17 -O2 -Wall -Wextra -Werror $cflags -o "$own" "$probe" $libs
brc=$?
cc -std=c17 -O2 -Wall -Wextra -Werror $cflags -o "$ctl" "$probe" "$system"
crc=$?
echo "check-jit-wx: build cc-exit=$brc control-cc-exit=$crc"
[ "$brc" = 0 ] && [ "$crc" = 0 ] || { rm -f "$own" "$ctl"; echo "check-jit-wx: NOT RUN -- a build failed"; exit 9; }

"$own" > "$scratch/jit-wx-own.out" 2>&1
rc=$?
"$ctl" > "$scratch/jit-wx-system.out" 2>&1
nrc=$?
shared=$(ldd "$own" | grep -c 'libpcre2')
cshared=$(ldd "$ctl" | grep -c 'libpcre2-8.so.0')
wx=$(sed -n 's/^wx-mappings=//p' "$scratch/jit-wx-own.out")
cwx=$(sed -n 's/^wx-mappings=//p' "$scratch/jit-wx-system.out")
echo "check-jit-wx: own $(tr '\n' ' ' < "$scratch/jit-wx-own.out")exit=$rc shared-pcre2-in-ldd=$shared"
echo "check-jit-wx: control $(tr '\n' ' ' < "$scratch/jit-wx-system.out")exit=$nrc shared-pcre2-in-ldd=$cshared"
rm -f "$own" "$ctl" "$scratch/jit-wx-own.out" "$scratch/jit-wx-system.out"

if [ "$nrc" != 0 ] || [ "$cshared" != 1 ] || [ -z "$cwx" ] || [ "$cwx" -lt 1 ]; then
	echo "check-jit-wx: NOT RUN -- the negative control shows no writable and executable mapping, so the check cannot fail"
	exit 9
fi
if [ "$rc" != 0 ] || [ "$shared" != 0 ] || [ "$wx" != 0 ]; then
	echo "check-jit-wx: FAIL -- want exit 0, no shared PCRE2 and 0 writable and executable mappings"
	exit 1
fi
echo "check-jit-wx: OK"
exit 0
