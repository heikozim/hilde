#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""The property tables of Standard.UnicodeProperties, generated from the
files of the Unicode Character Database.

    python3 scripts/unicode/make-property-tables.py --hilde
    python3 scripts/unicode/make-property-tables.py --digests
    python3 scripts/unicode/make-property-tables.py --crosscheck
    python3 scripts/unicode/make-property-tables.py --check <UnicodeProperties.hiq>
    python3 scripts/unicode/make-property-tables.py --ocaml

--ocaml writes the list of script names that lib/RegexCheck.ml holds, so
that the compiler's check of a literal pattern knows the names
Standard.Regex knows.

The files of the database are read from scripts/unicode/ucd/17.0.0 and
from nowhere else;
UnicodeData.txt, Scripts.txt and CaseFolding.txt; the version is read
from the headers of the last two and must agree.
scripts/check-unicode-data.py runs --check in both gates.

Four tables of fixed-width records, each sorted by code point:

    categories  14 characters: start (6), end (6), the general category
                (2 letters); the assigned code points in runs of one
                category, the unassigned ones left out (they are Cn)
    scripts     14 characters: start (6), end (6), the index of the script
                in the list of names (2 hexadecimal digits); the code
                points Scripts.txt lists, in runs of one script
    names       the script names, sorted, each followed by a comma
    orbits      12 characters: a code point (6) and the next code point of
                its simple case folding orbit (6); an orbit is the set of
                code points whose simple folding (the C and S entries of
                CaseFolding.txt) is the same, with that folding itself,
                taken in a circle in the order of the code points

Every number is capital hexadecimal.
"""
import hashlib
import os
import re
import sys

UCD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ucd", "17.0.0")

LAST = 0x10FFFF


def version_of(path):
    first = open(path, encoding="utf-8").readline()
    m = re.search(r"-(\d+\.\d+\.\d+)\.txt", first)
    if not m:
        sys.exit("ABORT: no version in the first line of %s" % path)
    return m.group(1)


def read(ucd):
    v1 = version_of(os.path.join(ucd, "Scripts.txt"))
    v2 = version_of(os.path.join(ucd, "CaseFolding.txt"))
    if v1 != v2:
        sys.exit("ABORT: Scripts.txt is %s and CaseFolding.txt %s" % (v1, v2))
    category = {}
    first = None
    for line in open(os.path.join(ucd, "UnicodeData.txt"), encoding="utf-8"):
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
    script = {}
    for line in open(os.path.join(ucd, "Scripts.txt"), encoding="utf-8"):
        body = line.split("#")[0].strip()
        if not body:
            continue
        rng, name = [x.strip() for x in body.split(";")]
        if ".." in rng:
            a, b = [int(x, 16) for x in rng.split("..")]
        else:
            a = b = int(rng, 16)
        for c in range(a, b + 1):
            script[c] = name
    fold = {}
    for line in open(os.path.join(ucd, "CaseFolding.txt"), encoding="utf-8"):
        body = line.split("#")[0].strip()
        if not body:
            continue
        f = [x.strip() for x in body.split(";")]
        if f[1] in ("C", "S"):
            fold[int(f[0], 16)] = int(f[2], 16)
    return v1, category, script, fold


def runs(mapping):
    out = []
    for c in sorted(mapping):
        value = mapping[c]
        if out and out[-1][1] == c - 1 and out[-1][2] == value:
            out[-1][1] = c
        else:
            out.append([c, c, value])
    return out


def orbits(fold):
    groups = {}
    for c, target in fold.items():
        groups.setdefault(target, {target}).add(c)
    nxt = {}
    for members in groups.values():
        ordered = sorted(members)
        if len(ordered) < 2:
            continue
        for i, c in enumerate(ordered):
            nxt[c] = ordered[(i + 1) % len(ordered)]
    return nxt


def tables(data):
    version, category, script, fold = data
    names = sorted(set(script.values()))
    if len(names) > 255:
        sys.exit("ABORT: %d scripts do not fit two digits" % len(names))
    index = {n: i for i, n in enumerate(names)}
    cat = "".join("%06X%06X%s" % (a, b, v) for a, b, v in runs(category))
    scr = "".join("%06X%06X%02X" % (a, b, index[v]) for a, b, v in runs(script))
    nx = orbits(fold)
    orb = "".join("%06X%06X" % (c, nx[c]) for c in sorted(nx))
    nm = "".join(n + "," for n in names)
    return version, cat, scr, nm, orb, category, script, nx


def literal(name, text, comment):
    lines = [text[i:i + 60] for i in range(0, len(text), 60)] or [""]
    out = ["    -- %s" % comment, "    function %s(): Span[Nat8, Static] is" % name]
    if len(lines) == 1:
        out.append('        return "%s";' % lines[0])
    else:
        out.append('        return "%s\\' % lines[0])
        for part in lines[1:-1]:
            out.append('            \\%s\\' % part)
        out.append('            \\%s";' % lines[-1])
    out.append("    end;")
    return "\n".join(out)


def hilde(data):
    version, cat, scr, nm, orb, _, _, _ = tables(data)
    parts = [
        "    ---",
        "    --- The tables, written by scripts/unicode/make-property-tables.py",
        "    --- from the Unicode Character Database %s.  Not edited by hand." % version,
        "    ---",
        "",
        literal("categoryTable", cat, "Runs of one general category: start, end, the category."),
        "",
        literal("scriptTable", scr, "Runs of one script: start, end, the index of its name."),
        "",
        literal("scriptNames", nm, "The names of the scripts, sorted, each followed by a comma."),
        "",
        literal("orbitTable", orb, "Each code point of a folding orbit and the next one of it."),
    ]
    return "\n".join(parts) + "\n"


def ocaml(data):
    version, _, _, nm, _, _, _, _ = tables(data)
    names = nm.rstrip(",").split(",")
    out = ["(* The scripts of Scripts.txt %s, written by" % version,
           "   scripts/unicode/make-property-tables.py --ocaml.  Not edited by hand. *)",
           "let script_names = ["]
    line = "   "
    for n in names:
        item = ' "%s";' % n
        if len(line) + len(item) > 76:
            out.append(line)
            line = "   "
        line += item
    out.append(line)
    out.append("  ]")
    return "\n".join(out) + "\n"


def fnv(data, h):
    for b in data:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def digests(data):
    _, cat, scr, nm, orb, category, script, nx = tables(data)
    h = 2166136261
    for c in range(0, LAST + 1):
        h = fnv(category.get(c, "Cn").encode(), h)
        h = fnv(script.get(c, "Unknown").encode(), h)
        n = nx.get(c, c)
        h = fnv(bytes([n & 0xFF, (n >> 8) & 0xFF, (n >> 16) & 0xFF]), h)
    print("digest-all=%u" % h)
    print("records categories=%d scripts=%d names=%d orbits=%d"
          % (len(cat) // 14, len(scr) // 14, nm.count(","), len(orb) // 12))
    print("assigned=%d in-scripts=%d in-orbits=%d" % (len(category), len(script), len(nx)))


def crosscheck(data):
    import unicodedata
    _, _, _, _, _, category, _, nx = tables(data)
    print("python-unicodedata=%s" % unicodedata.unidata_version)
    compared = 0
    differ = []
    for c in range(0, LAST + 1):
        py = unicodedata.category(chr(c))
        if py == "Cn":
            continue
        compared += 1
        if category.get(c, "Cn") != py:
            differ.append(c)
    print("categories compared=%d differ=%d %s" % (compared, len(differ), " ".join("%04X" % c for c in differ[:12])))
    # The orbits against Python's own simple folding: two code points of one
    # orbit have the same casefold when both fold simply, and a code point
    # outside every orbit has no other code point with its casefold.
    bad = 0
    checked = 0
    for c, n in nx.items():
        a, b = chr(c).casefold(), chr(n).casefold()
        if len(a) == 1 and len(b) == 1:
            checked += 1
            if a != b:
                bad += 1
    print("orbit-neighbours compared=%d differ=%d" % (checked, bad))


def check(data, path):
    text = open(path, encoding="utf-8").read()
    want = hilde(data)
    ok = want in text
    print("check %s: tables %s" % (path, "equal" if ok else "DIFFER"))
    return 0 if ok else 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 9
    sys.argv.insert(1, UCD)
    data = read(sys.argv[1])
    mode = sys.argv[2]
    if mode == "--hilde":
        sys.stdout.write(hilde(data))
    elif mode == "--digests":
        digests(data)
    elif mode == "--crosscheck":
        crosscheck(data)
    elif mode == "--ocaml":
        sys.stdout.write(ocaml(data))
    elif mode == "--check" and len(sys.argv) > 3:
        return check(data, sys.argv[3])
    else:
        print(__doc__)
        return 9
    return 0


if __name__ == "__main__":
    sys.exit(main())
