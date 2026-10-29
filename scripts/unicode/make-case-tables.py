#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""The case tables of Standard.Unicode, generated from the files of the
Unicode Character Database.

    python3 scripts/unicode/make-case-tables.py --hilde
    python3 scripts/unicode/make-case-tables.py --digests
    python3 scripts/unicode/make-case-tables.py --crosscheck
    python3 scripts/unicode/make-case-tables.py --check <Unicode.hiq>

The files of the database are read from scripts/unicode/ucd/17.0.0 and
from nowhere else;
UnicodeData.txt, SpecialCasing.txt and CaseFolding.txt; the version is
read from the headers of the last two and must agree.
scripts/check-unicode-data.py runs --check in both gates.  Three
mappings of a code point alone:

    upper  the unconditional entry of SpecialCasing.txt, else the simple
           upper case mapping of UnicodeData.txt, else the code point
    lower  the same with the lower case fields
    fold   the F entry of CaseFolding.txt, else the C entry, else the code
           point (S and T are not used: F is the full folding, T Turkish)

A conditional entry of SpecialCasing.txt -- the final sigma, the rules of
a language -- is not used.  --crosscheck holds the three against Python's
str.upper, str.lower and str.casefold for every code point Python's
unicodedata has assigned, an implementation of the same rules from
another copy of the database.

Each mapping is two tables of fixed-width hexadecimal records, sorted by
code point, so that Standard.Unicode finds a record by binary search in a
string literal and parses nothing ahead of time:

    runs      20 digits: start (6), end (6), stride (1: 1 or 2), and the
              difference to the mapped code point plus 0x2000000 (7) --
              every code point from start to end, stride apart, maps to
              itself plus the difference.  No run holds a code point of
              another run between its ends.
    specials  24 digits: the code point (6) and the up to three code
              points it maps to (6 each, 000000 for none).
"""
import os
import re
import sys

UCD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ucd", "17.0.0")

PLANES_END = 0x20000
OFFSET = 0x2000000


def fields(line):
    return [f.strip() for f in line.split("#", 1)[0].split(";")]


def version_of(path):
    with open(path, encoding="utf-8") as stream:
        first = stream.readline()
    found = re.search(r"-(\d+\.\d+\.\d+)\.txt", first)
    if not found:
        sys.exit("ABORT: no version in the first line of %s" % path)
    return found.group(1)


def read_ucd(ucd):
    simple_upper = {}
    simple_lower = {}
    with open(os.path.join(ucd, "UnicodeData.txt"), encoding="utf-8") as stream:
        for line in stream:
            f = line.rstrip("\n").split(";")
            if len(f) < 15:
                continue
            c = int(f[0], 16)
            if f[12]:
                simple_upper[c] = int(f[12], 16)
            if f[13]:
                simple_lower[c] = int(f[13], 16)
    special_upper = {}
    special_lower = {}
    with open(os.path.join(ucd, "SpecialCasing.txt"), encoding="utf-8") as stream:
        for line in stream:
            f = fields(line)
            if len(f) < 4 or not f[0]:
                continue
            # A fifth field holds conditions; such an entry is not used.
            if len(f) >= 5 and f[4]:
                continue
            c = int(f[0], 16)
            special_lower[c] = [int(x, 16) for x in f[1].split()]
            special_upper[c] = [int(x, 16) for x in f[3].split()]
    fold_c = {}
    fold_f = {}
    with open(os.path.join(ucd, "CaseFolding.txt"), encoding="utf-8") as stream:
        for line in stream:
            f = fields(line)
            if len(f) < 3 or not f[0]:
                continue
            c = int(f[0], 16)
            if f[1] == "C":
                fold_c[c] = [int(f[2], 16)]
            elif f[1] == "F":
                fold_f[c] = [int(x, 16) for x in f[2].split()]
    return simple_upper, simple_lower, special_upper, special_lower, fold_c, fold_f


def code_points():
    for c in range(0x110000):
        if 0xD800 <= c <= 0xDFFF:
            continue
        yield c


def full_mapping(kind, data):
    """code point -> list of code points, for every code point that
    changes."""
    simple_upper, simple_lower, special_upper, special_lower, fold_c, fold_f = data
    out = {}
    for c in code_points():
        if kind == "upper":
            m = special_upper.get(c) or ([simple_upper[c]] if c in simple_upper else [c])
        elif kind == "lower":
            m = special_lower.get(c) or ([simple_lower[c]] if c in simple_lower else [c])
        else:
            m = fold_f.get(c) or fold_c.get(c) or [c]
        if m != [c]:
            if len(m) > 3:
                sys.exit("ABORT: %04X maps to %d code points" % (c, len(m)))
            out[c] = m
    return out


def runs(simple):
    """Greedy runs of one difference, stride 1 or 2, never holding a mapped
    code point of another run between their ends."""
    taken = set()
    out = []
    for c in sorted(simple):
        if c in taken:
            continue
        delta = simple[c] - c
        best_end, best_stride = c, 1
        for stride in (1, 2):
            end = c
            while True:
                n = end + stride
                if n not in simple or n in taken or simple[n] - n != delta:
                    break
                if stride == 2 and (end + 1) in simple:
                    break
                end = n
            if end > best_end:
                best_end, best_stride = end, stride
        k = c
        while k <= best_end:
            taken.add(k)
            k += best_stride
        out.append((c, best_end, best_stride, delta))
    for i in range(1, len(out)):
        if out[i][0] <= out[i - 1][1]:
            sys.exit("ABORT: runs overlap at %06X" % out[i][0])
    return out


def literal(name, records):
    lines = ["    function %s(): Span[Nat8, Static] is" % name]
    body = "".join(records)
    if not body:
        lines.append('        return "";')
    else:
        chunks = [body[i:i + 60] for i in range(0, len(body), 60)]
        lines.append('        return "' + chunks[0] + ("\\" if len(chunks) > 1 else '";'))
        for j, chunk in enumerate(chunks[1:], 1):
            end = '";' if j == len(chunks) - 1 else "\\"
            lines.append("            \\" + chunk + end)
    lines.append("    end;")
    return "\n".join(lines)


def tables(data):
    out = []
    counts = []
    for kind in ("upper", "lower", "fold"):
        full = full_mapping(kind, data)
        simple = {c: m[0] for c, m in full.items() if len(m) == 1}
        special = {c: m for c, m in full.items() if len(m) > 1}
        rs = runs(simple)
        run_records = ["%06X%06X%1d%07X" % (s, e, st, d + OFFSET) for (s, e, st, d) in rs]
        special_records = ["%06X" % c + "".join("%06X" % x for x in (special[c] + [0, 0, 0])[:3]) for c in sorted(special)]
        out.append(literal(kind + "Runs", run_records))
        out.append(literal(kind + "Specials", special_records))
        counts.append("%s: %d simple in %d runs, %d special" % (kind, len(simple), len(rs), len(special)))
    return out, counts


def fnv(data, h):
    for b in data:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def digests(data):
    for kind in ("upper", "lower", "fold"):
        full = full_mapping(kind, data)
        h = 2166136261
        beyond = 0
        for c in code_points():
            if c >= PLANES_END:
                if c in full:
                    beyond += 1
                continue
            text = "".join(chr(x) for x in full.get(c, [c]))
            h = fnv(text.encode("utf-8"), h)
        print("%s digest-planes-0-1=%u changed=%d changed-beyond-plane-1=%d" % (kind, h, len(full), beyond))


def crosscheck(data):
    import unicodedata
    print("python-unicodedata=%s" % unicodedata.unidata_version)
    for kind in ("upper", "lower", "fold"):
        full = full_mapping(kind, data)
        compared = 0
        differ = []
        for c in code_points():
            if unicodedata.category(chr(c)) == "Cn":
                continue
            compared += 1
            s = chr(c)
            py = s.upper() if kind == "upper" else (s.lower() if kind == "lower" else s.casefold())
            ours = "".join(chr(x) for x in full.get(c, [c]))
            if py != ours:
                differ.append(c)
        print("%s compared=%d differ=%d %s" % (kind, compared, len(differ), " ".join("%04X" % c for c in differ[:10])))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    ucd = UCD
    sys.argv.insert(1, ucd)
    v1 = version_of(os.path.join(ucd, "SpecialCasing.txt"))
    v2 = version_of(os.path.join(ucd, "CaseFolding.txt"))
    if v1 != v2:
        sys.exit("ABORT: SpecialCasing.txt is %s, CaseFolding.txt %s" % (v1, v2))
    data = read_ucd(ucd)
    mode = sys.argv[2]
    if mode == "--hilde" and len(sys.argv) == 3:
        out, counts = tables(data)
        print("\n\n".join(out))
        print("unicode %s" % v1, file=sys.stderr)
        for c in counts:
            print(c, file=sys.stderr)
    elif mode == "--digests" and len(sys.argv) == 3:
        print("unicode %s" % v1)
        digests(data)
    elif mode == "--crosscheck" and len(sys.argv) == 3:
        print("unicode %s" % v1)
        crosscheck(data)
    elif mode == "--check" and len(sys.argv) == 4:
        out, counts = tables(data)
        text = open(sys.argv[3]).read()
        missing = [block.split("\n")[0] for block in out if block not in text]
        for m in missing:
            print("check-case-tables: not current:", m.strip())
        print("check-case-tables: tables=%d not-current=%d unicode=%s" % (len(out), len(missing), v1))
        sys.exit(1 if missing else 0)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
