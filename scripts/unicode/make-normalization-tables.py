#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""The tables of Standard.Normalization, generated from UnicodeData.txt of
the Unicode Character Database.

    python3 scripts/unicode/make-normalization-tables.py --hilde
    python3 scripts/unicode/make-normalization-tables.py --digests
    python3 scripts/unicode/make-normalization-tables.py --crosscheck
    python3 scripts/unicode/make-normalization-tables.py --check <Normalization.hiq>
    python3 scripts/unicode/make-normalization-tables.py --check-ucd <Normalization.hiq>
    python3 scripts/unicode/make-normalization-tables.py --sequences

--sequences prints, for each form, the digest of Python's normalization of
every text of a base followed by two accents from the two lists below,
which the module's test holds; there the ordering and the composition of
accents are at work, which single code points do not show.

The files of the database are read from scripts/unicode/ucd/17.0.0 and
from nowhere else;
UnicodeData.txt, and the version from the header of CaseFolding.txt.
The composition exclusions are not read from CompositionExclusions.txt,
which is not in the repository yet, but found as the
definition of Full_Composition_Exclusion gives them: a canonical
decomposition to one code point (a singleton), one whose first code point
has a combining class other than 0 (a non-starter), or one Python's NFC
does not compose back to the code point, which leaves the listed
exclusions; --crosscheck says how many of each.  This needs Python with a
unicodedata that has every code point with a canonical decomposition;
the script refuses to write tables otherwise.

--check-ucd needs no Python module: it takes the listed exclusions from
the compose table of the file it checks, derives everything else from
UnicodeData.txt, and holds the whole text to the file.  Every table but
the choice of the listed exclusions is then checked against the
database; that choice is not, and the line says how many there are.

Four tables of capital hexadecimal, each sorted by code point:

    classes      14 characters: start (6), end (6), the canonical combining
                 class (2); runs of code points with one class other than 0
    decompose    14 characters: the code point (6), where its full
                 decomposition starts in the list (5), its length (2), and C
                 for canonical or K for compatibility (1)
    list         the full decompositions one after another, 6 characters
                 per code point
    compose      18 characters: the first code point (6), the second (6)
                 and what the two compose to (6); sorted by the first, then
                 the second

Hangul syllables are decomposed and composed by arithmetic and are in no
table.
"""
import hashlib
import os
import sys

UCD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ucd", "17.0.0")

LAST = 0x10FFFF
S_BASE, L_BASE, V_BASE, T_BASE = 0xAC00, 0x1100, 0x1161, 0x11A7
L_COUNT, V_COUNT, T_COUNT = 19, 21, 28
N_COUNT = V_COUNT * T_COUNT
S_COUNT = L_COUNT * N_COUNT


def read(ucd):
    ccc = {}
    decomp = {}
    first = None
    for line in open(os.path.join(ucd, "UnicodeData.txt"), encoding="utf-8"):
        f = line.rstrip("\n").split(";")
        cp = int(f[0], 16)
        if f[1].endswith(", First>"):
            first = cp
            continue
        if f[1].endswith(", Last>"):
            first = None
            continue
        if f[3] != "0":
            ccc[cp] = int(f[3])
        if f[5]:
            parts = f[5].split()
            kind = "C"
            if parts[0].startswith("<"):
                kind = "K"
                parts = parts[1:]
            decomp[cp] = (kind, [int(x, 16) for x in parts])
    return ccc, decomp


def full(cp, decomp, compat, seen=None):
    if S_BASE <= cp < S_BASE + S_COUNT:
        s = cp - S_BASE
        out = [L_BASE + s // N_COUNT, V_BASE + (s % N_COUNT) // T_COUNT]
        if s % T_COUNT:
            out.append(T_BASE + s % T_COUNT)
        return out
    if cp not in decomp:
        return [cp]
    kind, parts = decomp[cp]
    if kind == "K" and not compat:
        return [cp]
    out = []
    for p in parts:
        out.extend(full(p, decomp, compat))
    return out


def exclusions(ccc, decomp):
    import unicodedata
    singleton = set()
    nonstarter = set()
    listed = set()
    for cp, (kind, parts) in decomp.items():
        if kind != "C":
            continue
        if unicodedata.category(chr(cp)) == "Cn":
            sys.exit("ABORT: Python %s does not have U+%04X; the exclusions cannot be found"
                     % (unicodedata.unidata_version, cp))
        if len(parts) == 1:
            singleton.add(cp)
        elif ccc.get(cp, 0) != 0 or ccc.get(parts[0], 0) != 0:
            nonstarter.add(cp)
        elif unicodedata.normalize("NFC", chr(cp)) != chr(cp):
            listed.add(cp)
    return singleton, nonstarter, listed


def tables(data, listed_given=None):
    ccc, decomp = data
    if listed_given is None:
        singleton, nonstarter, listed = exclusions(ccc, decomp)
    else:
        singleton, nonstarter, listed = structural(ccc, decomp) + (listed_given,)
    excluded = singleton | nonstarter | listed
    cls = []
    for c in sorted(ccc):
        if cls and cls[-1][1] == c - 1 and cls[-1][2] == ccc[c]:
            cls[-1][1] = c
        else:
            cls.append([c, c, ccc[c]])
    classes = "".join("%06X%06X%02X" % (a, b, v) for a, b, v in cls)
    index = []
    lst = []
    for cp in sorted(decomp):
        kind, _ = decomp[cp]
        seq = full(cp, decomp, kind == "K")
        index.append("%06X%05X%02X%s" % (cp, len(lst), len(seq), kind))
        lst.extend(seq)
    decompose = "".join(index)
    listing = "".join("%06X" % c for c in lst)
    pairs = []
    for cp, (kind, parts) in decomp.items():
        if kind == "C" and len(parts) == 2 and cp not in excluded:
            pairs.append((parts[0], parts[1], cp))
    compose = "".join("%06X%06X%06X" % p for p in sorted(pairs))
    counts = (len(singleton), len(nonstarter), len(listed), len(cls), len(index), len(lst), len(pairs))
    return classes, decompose, listing, compose, counts


def structural(ccc, decomp):
    """The singletons and the non-starters, the exclusions UnicodeData.txt
    alone decides."""
    singleton = set()
    nonstarter = set()
    for cp, (kind, parts) in decomp.items():
        if kind != "C":
            continue
        if len(parts) == 1:
            singleton.add(cp)
        elif ccc.get(cp, 0) != 0 or ccc.get(parts[0], 0) != 0:
            nonstarter.add(cp)
    return singleton, nonstarter


def compose_of(path):
    """The code points the compose table of a module composes to."""
    text = open(path, encoding="utf-8").read()
    start = text.index("function composeTable()")
    end = text.index("end;", start)
    body = "".join(ch for ch in text[start:end].split("return", 1)[1] if ch in "0123456789ABCDEF")
    return {int(body[i + 12:i + 18], 16) for i in range(0, len(body), 18)}


def check_ucd(data, version, path):
    ccc, decomp = data
    singleton, nonstarter = structural(ccc, decomp)
    composed = compose_of(path)
    listed = {cp for cp, (kind, parts) in decomp.items()
              if kind == "C" and len(parts) == 2 and cp not in singleton
              and cp not in nonstarter and cp not in composed}
    stray = [cp for cp in composed if cp not in decomp]
    ok = not stray and hilde(data, version, listed) in open(path, encoding="utf-8").read()
    print("check-ucd %s: tables %s; compose entries %d, singletons %d, non-starters %d,"
          " listed exclusions %d (taken from the file, not checked: CompositionExclusions.txt"
          " is not in the repository)" % (path, "equal" if ok else "DIFFER", len(composed),
                                           len(singleton), len(nonstarter), len(listed)))
    return 0 if ok else 1


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


def hilde(data, version, listed=None):
    classes, decompose, listing, compose, _ = tables(data, listed)
    parts = [
        "    ---",
        "    --- The tables, written by scripts/unicode/make-normalization-tables.py",
        "    --- from the Unicode Character Database %s.  Not edited by hand." % version,
        "    ---",
        "",
        literal("classTable", classes, "Runs of one canonical combining class other than 0."),
        "",
        literal("decomposeTable", decompose, "Each code point with a decomposition: where it starts, its length, its kind."),
        "",
        literal("decompositionList", listing, "The full decompositions, one after another."),
        "",
        literal("composeTable", compose, "Two code points and what they compose to."),
    ]
    return "\n".join(parts) + "\n"


SEQUENCE_BASES = [0x41, 0x61, 0x45, 0x65, 0x4F, 0x6F, 0x53, 0x73, 0xC5, 0x1100, 0xAC00,
                  0x391, 0x3B1, 0x415, 0x435, 0x5D0, 0x915]
SEQUENCE_MARKS = [0x300, 0x301, 0x302, 0x308, 0x30A, 0x323, 0x327, 0x328, 0x345, 0x5B0,
                  0x93C, 0x94D, 0x1161, 0x11A8]


def sequences():
    import unicodedata
    print("python-unicodedata=%s texts=%d" % (unicodedata.unidata_version,
                                             len(SEQUENCE_BASES) * len(SEQUENCE_MARKS) ** 2))
    for form in ("NFD", "NFC", "NFKD", "NFKC"):
        h = 2166136261
        for b in SEQUENCE_BASES:
            for m1 in SEQUENCE_MARKS:
                for m2 in SEQUENCE_MARKS:
                    h = fnv(unicodedata.normalize(form, chr(b) + chr(m1) + chr(m2)).encode("utf-8"), h)
        print("%s sequences-digest=%u" % (form, h))


def fnv(data, h):
    for b in data:
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def expected(form, c, decomp):
    """Python's normalization of the code point, except for one that
    Python's unicodedata does not know (category Cn there) and the UCD
    decomposes: that one is decomposed by the UCD first, compatibility
    mappings only for the K forms, and Python normalizes the result, whose
    code points it knows.  True as the second value when the UCD was used."""
    import unicodedata
    ch = chr(c)
    if c in decomp and unicodedata.category(ch) == "Cn":
        compat = form in ("NFKD", "NFKC")
        text = "".join(chr(x) for x in full(c, decomp, compat))
        return unicodedata.normalize(form, text), True
    return unicodedata.normalize(form, ch), False


def digests(data):
    import unicodedata
    ccc, decomp = data
    classes, decompose, listing, compose, counts = tables(data)
    print("records classes=%d decompositions=%d list=%d pairs=%d" % (counts[3], counts[4], counts[5], counts[6]))
    print("exclusions singletons=%d non-starters=%d listed=%d" % counts[:3])
    for form in ("NFD", "NFC", "NFKD", "NFKC"):
        h = 2166136261
        by_ucd = 0
        for c in range(0, LAST + 1):
            if 0xD800 <= c <= 0xDFFF:
                continue
            text, used = expected(form, c, decomp)
            by_ucd += 1 if used else 0
            h = fnv(text.encode("utf-8"), h)
        print("%s digest-python-%s=%u decomposed-by-the-ucd-first=%d"
              % (form, unicodedata.unidata_version, h, by_ucd))


def crosscheck(data):
    import unicodedata
    ccc, decomp = data
    print("python-unicodedata=%s" % unicodedata.unidata_version)
    for form, compat in (("NFD", False), ("NFKD", True)):
        compared = differ = 0
        for c in range(0, LAST + 1):
            if 0xD800 <= c <= 0xDFFF or unicodedata.category(chr(c)) == "Cn":
                continue
            compared += 1
            if "".join(chr(x) for x in full(c, decomp, compat)) != unicodedata.normalize(form, chr(c)):
                differ += 1
        print("%s compared=%d differ=%d" % (form, compared, differ))
    compared = differ = 0
    for c in range(0, LAST + 1):
        if 0xD800 <= c <= 0xDFFF or unicodedata.category(chr(c)) == "Cn":
            continue
        compared += 1
        if ccc.get(c, 0) != unicodedata.combining(chr(c)):
            differ += 1
    print("combining classes compared=%d differ=%d" % (compared, differ))


def check(data, version, path):
    ok = hilde(data, version) in open(path, encoding="utf-8").read()
    print("check %s: tables %s" % (path, "equal" if ok else "DIFFER"))
    return 0 if ok else 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 9
    sys.argv.insert(1, UCD)
    ucd = sys.argv[1]
    first = open(os.path.join(ucd, "CaseFolding.txt"), encoding="utf-8").readline()
    version = first.split("-")[1].split(".txt")[0] if "-" in first else "unknown"
    data = read(ucd)
    mode = sys.argv[2]
    if mode == "--hilde":
        sys.stdout.write(hilde(data, version))
    elif mode == "--digests":
        digests(data)
    elif mode == "--crosscheck":
        crosscheck(data)
    elif mode == "--sequences":
        sequences()
    elif mode == "--check" and len(sys.argv) > 3:
        return check(data, version, sys.argv[3])
    elif mode == "--check-ucd" and len(sys.argv) > 3:
        return check_ucd(data, version, sys.argv[3])
    else:
        print(__doc__)
        return 9
    return 0


if __name__ == "__main__":
    sys.exit(main())
