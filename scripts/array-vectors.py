#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Writes and checks docs/array-vectors.txt, the byte vectors of the array wire form.

    python3 scripts/array-vectors.py --write
    python3 scripts/array-vectors.py --check

--write regenerates docs/array-vectors.txt from the layout in docs/array.en.md.
--check regenerates it in memory, compares it with the file, and judges every
vector again with an independent reader written here, which must give the
verdict the file states.  Prints vectors=N valid=V rejected=R faults=M; exit 0
when there is no fault, 1 otherwise.
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "docs", "array-vectors.txt")

MAGIC = b"HLDA"
VERSION = 1
MAX_RANK = 4
MAX_ELEMENTS = 2147483648
# name -> (code, width, struct format)
TYPES = {
    "nat8": (0, 1, "<B"),
    "int32": (1, 4, "<i"),
    "int64": (2, 8, "<q"),
    "float32": (5, 4, "<f"),
    "float64": (6, 8, "<d"),
    "bool": (7, 1, "<B"),
}
CODES = {v[0]: (k, v[1]) for k, v in TYPES.items()}


def header(code, extents, *, version=VERSION, flags=0, magic=MAGIC, rank=None):
    r = len(extents) if rank is None else rank
    out = magic + bytes([version, code, r, flags])
    for e in extents:
        out += struct.pack("<Q", e)
    return out


def data(kind, values):
    code, width, fmt = TYPES[kind]
    return b"".join(struct.pack(fmt, v) for v in values)


def valid(name, kind, extents, values, note=""):
    body = data(kind, values)
    return {"name": name, "expect": "ok", "type": kind,
            "shape": " ".join(str(e) for e in extents), "note": note,
            "bytes": header(TYPES[kind][0], extents) + body}


def invalid(name, expect, raw, note=""):
    return {"name": name, "expect": expect, "note": note, "bytes": raw}


def vectors():
    v = []
    v.append(valid("float64-2x3", "float64", [2, 3], [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
                   "row-major: the last axis runs fastest"))
    v.append(valid("float64-nan", "float64", [1], [float("nan")],
                   "the bits of a NaN are kept"))
    v.append(valid("float64-negative-zero", "float64", [2], [-0.0, 0.0],
                   "the sign of zero is kept"))
    v.append(valid("float32-vector", "float32", [3], [0.5, -8.0, 3.25]))
    v.append(valid("int32-vector", "int32", [4], [0, 1, -1, 2147483647]))
    v.append(valid("int64-vector", "int64", [3], [9223372036854775807, -1, 0]))
    v.append(valid("nat8-vector", "nat8", [5], [0, 1, 127, 128, 255]))
    v.append(valid("bool-vector", "bool", [4], [1, 0, 0, 1]))
    v.append(valid("int32-rank3", "int32", [2, 1, 3], [1, 2, 3, 4, 5, 6]))
    v.append(valid("nat8-rank4", "nat8", [1, 2, 1, 2], [9, 8, 7, 6]))
    v.append(valid("float64-single", "float64", [1], [42.0]))
    good = header(6, [2]) + data("float64", [1.0, 2.0])
    v.append(invalid("neg-empty", "reject-too-short", b""))
    v.append(invalid("neg-header-cut", "reject-too-short", good[:7],
                     "seven bytes are less than the fixed head"))
    v.append(invalid("neg-extent-cut", "reject-too-short", good[:12],
                     "the head says rank 1 but the extent is cut"))
    v.append(invalid("neg-magic", "reject-magic", b"HLDB" + good[4:]))
    v.append(invalid("neg-version", "reject-version", header(6, [2], version=2) + data("float64", [1.0, 2.0])))
    v.append(invalid("neg-flags", "reject-flags", header(6, [2], flags=1) + data("float64", [1.0, 2.0]),
                     "the reserved byte must be zero"))
    for code in (3, 4, 8, 255):
        v.append(invalid("neg-element-type-%d" % code, "reject-element-type",
                         header(code, [1]) + bytes(8),
                         "codes 3 and 4 are reserved for Nat32 and Nat64 and not taken"))
    v.append(invalid("neg-rank-0", "reject-rank", header(6, [], rank=0) + bytes(8)))
    v.append(invalid("neg-rank-5", "reject-rank", header(6, [1, 1, 1, 1, 1]) + bytes(8)))
    v.append(invalid("neg-extent-zero", "reject-extent", header(6, [0])))
    v.append(invalid("neg-extent-zero-second", "reject-extent", header(6, [2, 0]) + bytes(0)))
    v.append(invalid("neg-extent-over-limit", "reject-extent", header(0, [MAX_ELEMENTS + 1]) + bytes(8)))
    v.append(invalid("neg-extent-huge", "reject-extent", header(0, [1 << 40]) + bytes(8)))
    v.append(invalid("neg-extent-top-bit", "reject-extent", header(0, [1 << 63]) + bytes(8),
                     "an extent that would be negative as a signed number"))
    v.append(invalid("neg-too-many-elements", "reject-too-large", header(0, [65536, 65536]),
                     "each extent is allowed, the product is 2^32"))
    v.append(invalid("neg-too-many-elements-rank4", "reject-too-large", header(0, [2048, 2048, 2048, 2048])))
    v.append(invalid("neg-data-short", "reject-length", good[:-1], "one byte of data missing"))
    v.append(invalid("neg-data-missing", "reject-length", header(6, [2])))
    v.append(invalid("neg-data-long", "reject-length", good + b"\x00", "one byte too many"))
    v.append(invalid("neg-type-length-mismatch", "reject-length",
                     header(6, [2]) + data("int32", [1, 2]),
                     "float64 says 16 bytes of data and int32 gave 8"))
    v.append(invalid("neg-extent-max-short", "reject-length", header(6, [MAX_ELEMENTS]),
                     "the largest extent is allowed, but the data of 2^31 float64 values is missing"))
    v.append(invalid("neg-bool-two", "reject-bool", header(7, [3]) + bytes([1, 2, 0])))
    v.append(invalid("neg-bool-255", "reject-bool", header(7, [1]) + bytes([255])))
    return v


def text():
    out = ["# Array wire form, test vectors, version 1.  Written by scripts/array-vectors.py.",
           "# Records are separated by a blank line.  Each line is key: value.",
           "# hex: the whole value in hexadecimal, one pair of digits per byte, blanks between bytes.",
           "# expect: ok, or reject-<reason> with too-short, magic, version, flags, element-type, rank,",
           "#   extent, too-large, length or bool.",
           "# type and shape: given for ok vectors; shape lists the extents.",
           "# max-rank: %d" % MAX_RANK,
           "# max-elements: %d" % MAX_ELEMENTS,
           ""]
    for rec in vectors():
        out.append("name: " + rec["name"])
        out.append("expect: " + rec["expect"])
        if "type" in rec:
            out.append("type: " + rec["type"])
            out.append("shape: " + rec["shape"])
        if rec["note"]:
            out.append("note: " + rec["note"])
        out.append("length: %d" % len(rec["bytes"]))
        out.append(("hex: " + " ".join("%02x" % b for b in rec["bytes"])).rstrip())
        out.append("")
    return "\n".join(out)


def judge(raw):
    """The verdict of an independent reader for the bytes."""
    n = len(raw)
    if n < 8:
        return "reject-too-short"
    if raw[:4] != MAGIC:
        return "reject-magic"
    if raw[4] != VERSION:
        return "reject-version"
    if raw[7] != 0:
        return "reject-flags"
    if raw[5] not in CODES:
        return "reject-element-type"
    rank = raw[6]
    if rank < 1 or rank > MAX_RANK:
        return "reject-rank"
    if n < 8 + 8 * rank:
        return "reject-too-short"
    total = 1
    for i in range(rank):
        e = struct.unpack_from("<Q", raw, 8 + 8 * i)[0]
        if e < 1 or e > MAX_ELEMENTS:
            return "reject-extent"
        total *= e
        if total > MAX_ELEMENTS:
            return "reject-too-large"
    name, width = CODES[raw[5]]
    if n - (8 + 8 * rank) != total * width:
        return "reject-length"
    if name == "bool" and any(b > 1 for b in raw[8 + 8 * rank:]):
        return "reject-bool"
    return "ok"


def check():
    faults = 0
    recs = vectors()
    try:
        with open(PATH, encoding="ascii") as f:
            have = f.read()
    except OSError:
        have = None
    if have != text():
        print("docs/array-vectors.txt is not what --write makes")
        faults += 1
    seen = set()
    for rec in recs:
        if rec["name"] in seen:
            print("name twice: " + rec["name"])
            faults += 1
        seen.add(rec["name"])
        verdict = judge(rec["bytes"])
        if verdict != rec["expect"]:
            print("%s: expected %s, the reader says %s" % (rec["name"], rec["expect"], verdict))
            faults += 1
    # positive control: the reader must refuse something and accept something
    if not any(r["expect"] == "ok" for r in recs) or not any(r["expect"] != "ok" for r in recs):
        print("the file has no valid or no invalid vector")
        faults += 1
    good = sum(1 for r in recs if r["expect"] == "ok")
    bad = sum(1 for r in recs if r["expect"] != "ok")
    print("vectors=%d valid=%d rejected=%d faults=%d" % (len(recs), good, bad, faults))
    return 0 if faults == 0 else 1


def main(argv):
    if argv == ["--write"]:
        with open(PATH, "w", encoding="ascii", newline="\n") as f:
            f.write(text())
        print("wrote %s: %d vectors" % (os.path.relpath(PATH, ROOT), len(vectors())))
        return 0
    if argv == ["--check"]:
        return check()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
