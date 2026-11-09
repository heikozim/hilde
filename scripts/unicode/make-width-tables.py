#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""The width table of Standard.Grapheme, generated from the files of the
Unicode Character Database.

    python3 scripts/unicode/make-width-tables.py --hilde
    python3 scripts/unicode/make-width-tables.py --digests
    python3 scripts/unicode/make-width-tables.py --check <Grapheme.hiq>

The files of the database are read from scripts/unicode/ucd/17.0.0 and
from nowhere else; EastAsianWidth.txt, emoji-data.txt and
UnicodeData.txt.  Each is held to the SHA-256 pinned in PINNED before it
is read, so the table comes from the bytes the sums name.

The table: 14 characters per run of code points of one width, sorted:
first code point (6), last (6), width (2), in capital hexadecimal.  The
width is the count of columns a terminal shows for the code point on its
own, and the module walks it over a cluster: the cluster is as wide as
its first code point of a width above 0, and no wider than its own rules
make it.  The width of one code point:

    0  the general categories Cc, Cf, Mn, Me, Zl and Zp: control and
       format characters and combining marks are not shown
    2  the East Asian classes W (wide) and F (fullwidth), and every code
       point of Emoji_Presentation, which a terminal shows as emoji
    1  everything else: the classes H, Na, N and A (ambiguous) among
       them, ambiguous counted narrow

The header of EastAsianWidth.txt gives classes only where it lists them;
the @missing lines of the header name what is not listed: class N, but
the unassigned code points of the CJK ideograph blocks and of planes 2
and 3 are wide.

scripts/check-unicode-data.py runs --check in both gates.
"""
import hashlib
import os
import re
import sys

UCD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ucd", "17.0.0")

LAST = 0x10FFFF

PINNED = {
    "EastAsianWidth.txt": "ea7ce50f3444a050333448dffef1cadd9325af55cbb764b4a2280faf52170a33",
    "emoji-data.txt": "2cb2bb9455cda83e8481541ecf5b6dfda66a3bb89efa3fa7c5297eccf607b72b",
    "UnicodeData.txt": "2e1efc1dcb59c575eedf5ccae60f95229f706ee6d031835247d843c11d96470c",
}

# The categories of characters a terminal does not show.
ZERO_CATEGORIES = ("Cc", "Cf", "Mn", "Me", "Zl", "Zp")

# What the @missing lines of the header of EastAsianWidth.txt give the
# code points the file does not list: wide.
DEFAULT_WIDE = (
    (0x3400, 0x4DBF),
    (0x4E00, 0x9FFF),
    (0xF900, 0xFAFF),
    (0x20000, 0x2FFFD),
    (0x30000, 0x3FFFD),
)


def held(name):
    """The path of the file, after its bytes held to the pinned sum."""
    path = os.path.join(UCD, name)
    got = hashlib.sha256(open(path, "rb").read()).hexdigest()
    if got != PINNED[name]:
        sys.exit("ABORT: %s: sha256 %s, pinned %s" % (name, got, PINNED[name]))
    return path


def version_of(path):
    first = open(path, encoding="utf-8").readline()
    m = re.search(r"-(\d+\.\d+\.\d+)\.txt", first)
    if not m:
        sys.exit("ABORT: no version in the first line of %s" % path)
    return m.group(1)


def read(ucd):
    """The version of the data and the width of every code point."""
    eaw = held("EastAsianWidth.txt")
    emoji = held("emoji-data.txt")
    data = held("UnicodeData.txt")
    version = version_of(eaw)
    width = {}

    def put(first, last, value):
        for c in range(first, last + 1):
            width[c] = value

    for line in open(eaw, encoding="utf-8"):
        line = line.split("#")[0].strip()
        if not line:
            continue
        span, value = [x.strip() for x in line.split(";")]
        first, _, last = span.partition("..")
        put(int(first, 16), int(last or first, 16), 2 if value in ("W", "F") else 1)
    for first, last in DEFAULT_WIDE:
        for c in range(first, last + 1):
            if c not in width:
                width[c] = 2
    for line in open(emoji, encoding="utf-8"):
        line = line.split("#")[0].strip()
        if not line:
            continue
        span, value = [x.strip() for x in line.split(";")]
        if value != "Emoji_Presentation":
            continue
        first, _, last = span.partition("..")
        put(int(first, 16), int(last or first, 16), 2)
    category = {}
    first = None
    for line in open(data, encoding="utf-8"):
        f = line.rstrip("\n").split(";")
        cp = int(f[0], 16)
        if f[1].endswith(", First>"):
            first = cp
            continue
        if f[1].endswith(", Last>"):
            for c in range(first, cp + 1):
                category[c] = f[2]
            first = None
            continue
        category[cp] = f[2]
    for c, name in category.items():
        if name in ZERO_CATEGORIES:
            width[c] = 0
    for c in range(0, LAST + 1):
        if c not in width:
            width[c] = 1
    return version, width


def runs(width):
    out = []
    for c in sorted(width):
        value = width[c]
        if out and out[-1][1] == c - 1 and out[-1][2] == value:
            out[-1][1] = c
        else:
            out.append([c, c, value])
    return out


def table(width):
    return "".join("%06X%06X%02X" % (a, b, v) for a, b, v in runs(width))


def hilde(width, version):
    text = table(width)
    lines = [text[i:i + 60] for i in range(0, len(text), 60)]
    out = ["    ---",
           "    --- The table, written by scripts/unicode/make-width-tables.py",
           "    --- from the Unicode Character Database %s.  Not edited by" % version,
           "    --- hand.",
           "    ---",
           "",
           "    -- Runs of one width: first code point, last, the width.",
           "    function widthTable(): Span[Nat8, Static] is",
           '        return "%s\\' % lines[0]]
    for part in lines[1:-1]:
        out.append('            \\%s\\' % part)
    out.append('            \\%s";' % lines[-1])
    out.append("    end;")
    return "\n".join(out) + "\n"


def digests(width):
    h = 2166136261
    for c in range(0, LAST + 1):
        h ^= width[c]
        h = (h * 16777619) & 0xFFFFFFFF
    print("digest-all=%u" % h)
    count = [0, 0, 0]
    for value in width.values():
        count[value] += 1
    print("code points=%d none=%d one=%d two=%d" % (LAST + 1, count[0], count[1], count[2]))
    print("records=%d" % len(runs(width)))


def check(width, version, path):
    text = open(path, encoding="utf-8").read()
    ok = hilde(width, version) in text
    print("check %s: table %s" % (path, "equal" if ok else "DIFFER"))
    return 0 if ok else 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 9
    version, width = read(UCD)
    mode = sys.argv[1]
    if mode == "--hilde":
        sys.stdout.write(hilde(width, version))
    elif mode == "--digests":
        digests(width)
    elif mode == "--check" and len(sys.argv) > 2:
        return check(width, version, sys.argv[2])
    else:
        print(__doc__)
        return 9
    return 0


if __name__ == "__main__":
    sys.exit(main())
