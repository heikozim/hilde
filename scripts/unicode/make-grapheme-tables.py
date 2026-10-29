#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""The table of Standard.Grapheme and the texts and digest of its test.

    python3 scripts/unicode/make-grapheme-tables.py <oracle> --hilde
    python3 scripts/unicode/make-grapheme-tables.py <oracle> --crosscheck
    python3 scripts/unicode/make-grapheme-tables.py <oracle> --check <Grapheme.hiq>
    python3 scripts/unicode/make-grapheme-tables.py <oracle> --digest
    python3 scripts/unicode/make-grapheme-tables.py --check-ucd <Grapheme.hiq>

The files of the database are read from scripts/unicode/ucd/17.0.0 and
from nowhere else;
GraphemeBreakProperty.txt and emoji-data.txt.  <oracle> is
scripts/unicode/grapheme-oracle.c built
against ICU; it gives Indic_Conjunct_Break, which those files do not hold,
and the boundaries of the texts of the test.  --crosscheck compares the
two other properties as the files give them with ICU's, code point by code
point, and the tables are only written when both agree everywhere.

The table: 14 characters per run of code points with one class other than
0, sorted: first code point (6), last (6), class (2), in capital
hexadecimal.  The class is the Grapheme_Cluster_Break value (the low four
bits, numbered as GCB below), Indic_Conjunct_Break (the next two, as INCB)
and Extended_Pictographic (the bit of 64).

--check-ucd needs no oracle: it holds, for every code point, the
Grapheme_Cluster_Break and the Extended_Pictographic bits of the table in
the file to the two files of the database.  The Indic_Conjunct_Break bits
are not checked: DerivedCoreProperties.txt is not in the repository yet.

--digest prints the representatives, one code point of each class, and the
digest over the boundaries of every text of one, two and three of them in
order, and of the texts in EXTRA, as ICU finds them; the module's test
builds the same texts and holds its own boundaries to this digest.
"""
import os
import subprocess
import sys

UCD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ucd", "17.0.0")

LAST = 0x10FFFF
GCB = ["Other", "CR", "LF", "Control", "Extend", "ZWJ", "Regional_Indicator",
       "Prepend", "SpacingMark", "L", "V", "T", "LV", "LVT"]
INCB = ["None", "Consonant", "Extend", "Linker"]

# Longer texts the rules are about, each as code points: runs of regional
# indicators, emoji joined by ZWJ with modifiers between, conjuncts of
# Devanagari with more than one linker and extenders between, Hangul
# syllables in their parts, and CR LF around marks.
EXTRA = [
    [0x1F1E9, 0x1F1EA, 0x1F1EB, 0x1F1F7, 0x1F1EE],
    [0x0061, 0x1F1E9, 0x1F1EA, 0x1F1EB],
    [0x1F469, 0x1F3FD, 0x200D, 0x1F52C],
    [0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, 0x200D, 0x1F466],
    [0x1F469, 0x200D, 0x0061],
    [0x0061, 0x200D, 0x1F469],
    [0x2764, 0xFE0F, 0x200D, 0x1F525],
    [0x0915, 0x094D, 0x0937, 0x093F],
    [0x0915, 0x093C, 0x094D, 0x0937],
    [0x0915, 0x094D, 0x200D, 0x0937],
    [0x0915, 0x094D, 0x094D, 0x0937],
    [0x0915, 0x0301, 0x0937],
    [0x0915, 0x094D, 0x0061],
    [0x0995, 0x09CD, 0x09B7, 0x09CD, 0x09A3],
    [0x1100, 0x1161, 0x11A8, 0x1100],
    [0xAC00, 0x11A8, 0x11A8, 0x1161],
    [0xAC01, 0x1161, 0x11A8],
    [0x000D, 0x000A, 0x0301, 0x000D, 0x000D, 0x000A],
    [0x0600, 0x0600, 0x0661, 0x0301],
    [0x0E01, 0x0E33, 0x0E33, 0x0301],
]


def read_ucd(ucd):
    """Grapheme_Cluster_Break and Extended_Pictographic per code point, as
    the two files give them."""
    gcb = {}
    for line in open(os.path.join(ucd, "GraphemeBreakProperty.txt"), encoding="utf-8"):
        line = line.split("#")[0].strip()
        if not line:
            continue
        span, value = [x.strip() for x in line.split(";")]
        first, _, last = span.partition("..")
        for c in range(int(first, 16), int(last or first, 16) + 1):
            gcb[c] = value
    ep = set()
    for line in open(os.path.join(ucd, "emoji-data.txt"), encoding="utf-8"):
        line = line.split("#")[0].strip()
        if not line:
            continue
        span, value = [x.strip() for x in line.split(";")]
        if value != "Extended_Pictographic":
            continue
        first, _, last = span.partition("..")
        for c in range(int(first, 16), int(last or first, 16) + 1):
            ep.add(c)
    return gcb, ep


def oracle(binary, mode, text=None):
    done = subprocess.run([binary, mode], input=text, capture_output=True, text=True, check=True)
    return done.stdout


def read_icu(binary):
    """The three properties as ICU gives them, per run."""
    runs = []
    for line in oracle(binary, "props").splitlines():
        first, last, g, i, e = line.split()
        runs.append((int(first, 16), int(last, 16), g, i, e == "1"))
    return runs


def classes(binary):
    """The class of every run, from ICU, and the runs whose class is not 0."""
    out = []
    for first, last, g, i, e in read_icu(binary):
        value = GCB.index(g) + 16 * INCB.index(i) + (64 if e else 0)
        if value:
            if out and out[-1][1] + 1 == first and out[-1][2] == value:
                out[-1] = (out[-1][0], last, value)
            else:
                out.append((first, last, value))
    return out


def crosscheck(ucd, binary):
    gcb, ep = read_ucd(ucd)
    print("oracle %s" % oracle(binary, "version").strip())
    compared = gcb_differ = ep_differ = 0
    for first, last, g, _, e in read_icu(binary):
        for c in range(first, last + 1):
            compared += 1
            if gcb.get(c, "Other") != g:
                gcb_differ += 1
            if (c in ep) != e:
                ep_differ += 1
    print("code points compared=%d grapheme-cluster-break differ=%d extended-pictographic differ=%d"
          % (compared, gcb_differ, ep_differ))
    return gcb_differ + ep_differ


def table(runs):
    return "".join("%06X%06X%02X" % r for r in runs)


def hilde(runs, version):
    text = table(runs)
    lines = [text[i:i + 60] for i in range(0, len(text), 60)]
    out = ["    ---",
           "    --- The table, written by scripts/unicode/make-grapheme-tables.py",
           "    --- from the Unicode Character Database %s and ICU.  Not edited by" % version,
           "    --- hand.",
           "    ---",
           "",
           "    -- Runs of one class other than 0: first code point, last, class.",
           "    function classTable(): Span[Nat8, Static] is",
           '        return "%s\\' % lines[0]]
    for part in lines[1:-1]:
        out.append('            \\%s\\' % part)
    out.append('            \\%s";' % lines[-1])
    out.append("    end;")
    return "\n".join(out) + "\n"


def representatives(runs):
    """One code point of each class, the first of its first run, and the
    letter a for class 0, sorted by code point."""
    seen = {0: 0x61}
    for first, _, value in runs:
        seen.setdefault(value, first)
    return sorted(seen.values())


def texts(reps):
    out = [[a] for a in reps]
    out += [[a, b] for a in reps for b in reps]
    out += [[a, b, c] for a in reps for b in reps for c in reps]
    return out + EXTRA


def fnv(data, h):
    for b in data:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def digest(binary, runs):
    reps = representatives(runs)
    all_texts = texts(reps)
    feed = "".join(" ".join("%04X" % c for c in t) + "\n" for t in all_texts)
    lines = oracle(binary, "breaks", feed).splitlines()
    if len(lines) != len(all_texts):
        print("ABORT: %d answers for %d texts" % (len(lines), len(all_texts)))
        return 9
    h = 2166136261
    for line in lines:
        h = fnv((line + "\n").encode("ascii"), h)
    print("oracle %s" % oracle(binary, "version").strip())
    print("representatives=%d %s" % (len(reps), "".join("%06X" % c for c in reps)))
    print("texts=%d (one %d, two %d, three %d, extra %d)"
          % (len(all_texts), len(reps), len(reps) ** 2, len(reps) ** 3, len(EXTRA)))
    print("boundaries-digest=%u" % h)
    return 0


def table_of(path):
    """The runs of the class table of a module, as the file holds them."""
    text = open(path, encoding="utf-8").read()
    start = text.index("function classTable()")
    end = text.index("end;", start)
    body = "".join(ch for ch in text[start:end].split("return", 1)[1] if ch in "0123456789ABCDEF")
    return [(int(body[i:i + 6], 16), int(body[i + 6:i + 12], 16), int(body[i + 12:i + 14], 16))
            for i in range(0, len(body), 14)]


def check_ucd(ucd, path):
    gcb, ep = read_ucd(ucd)
    cls = {}
    for first, last, value in table_of(path):
        for c in range(first, last + 1):
            cls[c] = value
    gcb_differ = ep_differ = 0
    for c in range(0x110000):
        value = cls.get(c, 0)
        if GCB[value & 15] != gcb.get(c, "Other"):
            gcb_differ += 1
        if bool(value & 64) != (c in ep):
            ep_differ += 1
    print("check-ucd %s: code points 1114112, grapheme-cluster-break differ=%d,"
          " extended-pictographic differ=%d, indic-conjunct-break not checked"
          " (DerivedCoreProperties.txt is not in the repository)" % (path, gcb_differ, ep_differ))
    return 0 if gcb_differ + ep_differ == 0 else 1


def check(runs, version, path):
    ok = hilde(runs, version) in open(path, encoding="utf-8").read()
    print("check %s: table %s" % (path, "equal" if ok else "DIFFER"))
    return 0 if ok else 1


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--check-ucd":
        return check_ucd(UCD, sys.argv[2])
    if len(sys.argv) < 3:
        print(__doc__)
        return 9
    sys.argv.insert(1, UCD)
    ucd, binary, mode = sys.argv[1], sys.argv[2], sys.argv[3]
    first = open(os.path.join(ucd, "GraphemeBreakProperty.txt"), encoding="utf-8").readline()
    version = first.strip("# \n").replace("GraphemeBreakProperty-", "").replace(".txt", "")
    if mode == "--crosscheck":
        return 0 if crosscheck(ucd, binary) == 0 else 1
    runs = classes(binary)
    if mode == "--digest":
        return digest(binary, runs)
    if mode == "--check":
        return check(runs, version, sys.argv[4])
    if mode == "--hilde":
        if crosscheck(ucd, binary) != 0:
            print("ABORT: the files and ICU disagree -- no table written")
            return 9
        print("runs=%d" % len(runs))
        sys.stdout.write(hilde(runs, version))
        return 0
    print(__doc__)
    return 9


if __name__ == "__main__":
    sys.exit(main())
