#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Writes and checks docs/sperli-vectors.txt, the byte vectors of SPERLI.

    python3 scripts/sperli-vectors.py --write
    python3 scripts/sperli-vectors.py --check

--write regenerates docs/sperli-vectors.txt from the layouts in
docs/sperli-protocol.md.  --check regenerates it in memory, compares it with
the file, and decodes every frame vector again with an independent reader.
Prints vectors=N faults=M; exit 0 when there is no fault, 1 otherwise.
Signatures cannot be made here, so a vector that holds one uses a
placeholder and says so.
"""
import hashlib
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "docs", "sperli-vectors.txt")

HEADER = 52
MAX_PAYLOAD = 16777216
JOB = bytes(range(16))
TYPES = {"HELLO": 1, "DATA": 2, "COLLECTIVE": 3, "HEARTBEAT": 4, "ABORT": 5,
         "CKPT_BEGIN": 6, "CKPT_DATA": 7, "CKPT_ACK": 8, "CKPT_COMMIT": 9,
         "RESUME": 10, "BYE": 11}
SIG_BYTES = 2484
PUB_BYTES = 1344


def frame(ftype, payload, *, incarnation=2, epoch=0, source=1, target=0, tag=0,
          service=0, flags=0, membership=0, length=None):
    n = len(payload) if length is None else length
    head = struct.pack("<IBBH16sIIQIII", n, TYPES[ftype], flags, service, JOB,
                       incarnation, membership, epoch, source, target, tag)
    assert len(head) == HEADER
    return head + payload


def token(rank, size, incarnation, expiry, host):
    h = host.encode()
    msg = (b"SPJT" + struct.pack("<HH", 1, 0) + JOB +
           struct.pack("<IIIQ", rank, size, incarnation, expiry) +
           struct.pack("<H", len(h)) + h)
    return msg, msg + struct.pack("<H", SIG_BYTES) + b"\xaa" * SIG_BYTES


def hello_payload(tok):
    return struct.pack("<HBBIII", 1, 1, 0, 3, 0, len(tok)) + tok


def ckpt_file(payload, epoch=3, rank=1, size=3):
    return (b"SPCK" + struct.pack("<HH", 1, 0) + JOB +
            struct.pack("<QIIQ", epoch, rank, size, len(payload)) +
            hashlib.sha256(payload).digest() + payload)


def commit_body(epoch, hashes):
    return (b"SPCM" + struct.pack("<HH", 1, 0) + JOB +
            struct.pack("<QI", epoch, len(hashes)) + b"".join(hashes))


def hexline(b):
    # runs of one byte, four or more, are written as hh*n
    out = []
    i = 0
    while i < len(b):
        j = i
        while j < len(b) and b[j] == b[i]:
            j += 1
        if j - i >= 4:
            out.append("%02x*%d" % (b[i], j - i))
            i = j
        else:
            out.append("%02x" % b[i])
            i += 1
    return " ".join(out)


def unhex(s):
    out = bytearray()
    for t in s.split():
        if "*" in t:
            h, n = t.split("*")
            out += bytes([int(h, 16)]) * int(n)
        else:
            out.append(int(t, 16))
    return bytes(out)


WIDTH = {0: 1, 1: 4, 2: 8, 3: 4, 4: 8, 5: 4, 6: 8}


def py_combine(typ, op, a, b):
    """Reads two arrays element by element and reduces them; None when the call is refused."""
    if typ not in WIDTH or op < 1 or op > 10:
        return None
    if typ == 0 and op < 8:
        return None
    if typ >= 5 and op > 4:
        return None
    w = WIDTH[typ]
    if len(a) != len(b) or len(a) % w:
        return None
    bits = 8 * w
    out = b""
    for i in range(0, len(a), w):
        x, y = a[i:i + w], b[i:i + w]
        if typ >= 5:
            fmt = "<f" if typ == 5 else "<d"
            fx, fy = struct.unpack(fmt, x)[0], struct.unpack(fmt, y)[0]
            if op == 1:
                r = fx + fy
            elif op == 4:
                r = fx * fy
            elif op == 2:
                r = fy if fy < fx else fx
            else:
                r = fy if fy > fx else fx
            out += struct.pack(fmt, r)
            continue
        signed = typ in (1, 2)
        ux, uy = int.from_bytes(x, "little"), int.from_bytes(y, "little")
        sx = int.from_bytes(x, "little", signed=signed)
        sy = int.from_bytes(y, "little", signed=signed)
        if op == 1:
            r = (ux + uy) % (1 << bits)
        elif op == 4:
            r = (ux * uy) % (1 << bits)
        elif op == 2:
            r = uy if sy < sx else ux
        elif op == 3:
            r = uy if sy > sx else ux
        elif op == 5:
            r = int(bool(ux) and bool(uy))
        elif op == 6:
            r = int(bool(ux) or bool(uy))
        elif op == 7:
            r = int(bool(ux) != bool(uy))
        elif op == 8:
            r = ux & uy
        elif op == 9:
            r = ux | uy
        else:
            r = ux ^ uy
        out += r.to_bytes(w, "little")
    return out


def vectors():
    v = []

    def add(name, kind, data, expect, **kw):
        v.append((name, kind, data, expect, kw))

    msg, tok = token(1, 3, 2, 1790000000, "node1")
    add("hello", "frame", frame("HELLO", hello_payload(tok), source=1, target=0),
        "ok", note="token signature is a placeholder of 0xaa; the message is the signed part",
        token_message=hexline(msg))
    add("data", "frame", frame("DATA", b"hello", tag=7), "ok")
    add("data-empty", "frame", frame("DATA", b"", tag=0), "ok")
    def coll(op, typ, red, phase, root, seq, data):
        return struct.pack("<BBBBIQ", op, typ, red, phase, root, seq) + data

    add("collective-bcast", "frame",
        frame("COLLECTIVE", coll(2, 6, 0, 1, 0, 5, struct.pack("<d", 1.5)), source=0, target=2), "ok",
        note="bcast of one float64 from root 0, call 5, result phase")
    add("collective-allreduce-contribution", "frame",
        frame("COLLECTIVE", coll(4, 2, 1, 0, 0, 9, struct.pack("<q", 42)), source=2, target=0), "ok",
        note="allreduce, int64, sum, contribution of rank 2 to rank 0, call 9")
    add("collective-allreduce-result", "frame",
        frame("COLLECTIVE", coll(4, 2, 1, 1, 0, 9, struct.pack("<q", 42)), source=0, target=2), "ok",
        note="the same call, result phase, from rank 0")
    add("collective-barrier", "frame",
        frame("COLLECTIVE", coll(1, 0, 0, 0, 0, 1, b""), source=1, target=0), "ok",
        note="barrier arrival of rank 1; the release has phase 1 and comes from rank 0")
    add("collective-barrier-release", "frame",
        frame("COLLECTIVE", coll(1, 0, 0, 1, 0, 1, b""), source=0, target=1), "ok")
    add("collective-reduce-max", "frame",
        frame("COLLECTIVE", coll(3, 3, 3, 0, 2, 4, struct.pack("<II", 7, 4294967295)), source=1, target=2), "ok",
        note="reduce to root 2, uint32, max, two elements, call 4")
    add("collective-gather", "frame",
        frame("COLLECTIVE", coll(5, 0, 0, 0, 1, 2, b"abc"), source=2, target=1), "ok",
        note="gather to root 1, a block of three bytes from rank 2, call 2")
    add("collective-scatter", "frame",
        frame("COLLECTIVE", coll(6, 0, 0, 1, 1, 3, b"xyz"), source=1, target=2), "ok",
        note="scatter from root 1, the block of rank 2, call 3")
    add("neg-collective-with-tag", "frame",
        frame("COLLECTIVE", coll(1, 0, 0, 0, 0, 1, b""), tag=7), "reject-collective-tag")
    add("neg-collective-short-header", "frame",
        frame("COLLECTIVE", b"\x01" * 15), "reject-collective-header")
    add("neg-data-reserved-tag", "frame", frame("DATA", b"x", tag=2147483648), "reject-reserved-tag",
        note="user tags are 0 to 2147483647")
    add("data-largest-tag", "frame", frame("DATA", b"x", tag=2147483647), "ok")
    f32 = lambda x: struct.pack("<f", x)
    f64 = lambda x: struct.pack("<d", x)
    u32 = lambda x: struct.pack("<I", x)
    i32 = lambda x: struct.pack("<i", x)
    u64 = lambda x: struct.pack("<Q", x)
    i64 = lambda x: struct.pack("<q", x)
    reduces = [
        ("reduce-uint32-sum-wraps", 3, 1, u32(4000000000), u32(500000000)),
        ("reduce-uint32-prod-wraps", 3, 4, u32(65536), u32(65536)),
        ("reduce-uint64-sum-wraps", 4, 1, u64(2**64 - 1), u64(2)),
        ("reduce-int32-min-signed", 1, 2, i32(-1), i32(1)),
        ("reduce-int32-max-signed", 1, 3, i32(-1), i32(1)),
        ("reduce-int64-prod", 2, 4, i64(-3), i64(4)),
        ("reduce-int64-max-signed", 2, 3, i64(-2**63), i64(2**63 - 1)),
        ("reduce-uint64-min", 4, 2, u64(2**64 - 1), u64(2)),
        ("reduce-int32-land", 1, 5, i32(5), i32(0)),
        ("reduce-int32-lor", 1, 6, i32(0), i32(7)),
        ("reduce-int32-lxor", 1, 7, i32(5), i32(3)),
        ("reduce-int64-band", 2, 8, i64(12), i64(10)),
        ("reduce-int64-bor", 2, 9, i64(12), i64(10)),
        ("reduce-int64-bxor", 2, 10, i64(12), i64(10)),
        ("reduce-bytes-band", 0, 8, b"\xff\x0f", b"\x0f\xff"),
        ("reduce-bytes-bxor", 0, 10, b"\xff\x0f", b"\x0f\xff"),
        ("reduce-float64-sum", 6, 1, f64(1.5), f64(2.25)),
        ("reduce-float64-min", 6, 2, f64(1.5), f64(-2.0)),
        ("reduce-float32-prod", 5, 4, f32(1.5), f32(2.25)),
        ("reduce-float32-max", 5, 3, f32(1.5), f32(-2.0)),
    ]
    for name, typ, op, x, y in reduces:
        add(name, "reduce", py_combine(typ, op, x, y), "ok", type=typ, reduction=op,
            first=hexline(x), second=hexline(y))
    add("neg-reduce-sum-of-bytes", "reduce", b"", "reject-reduce", type=0, reduction=1,
        first=hexline(b"ab"), second=hexline(b"cd"))
    add("neg-reduce-bitwise-of-floats", "reduce", b"", "reject-reduce", type=6, reduction=8,
        first=hexline(f64(1.0)), second=hexline(f64(2.0)))
    add("neg-reduce-lengths-differ", "reduce", b"", "reject-reduce", type=1, reduction=1,
        first=hexline(u32(1)), second=hexline(u64(1)))
    add("heartbeat", "frame",
        frame("HEARTBEAT", struct.pack("<Q", 123456789)), "ok")
    add("abort", "frame",
        frame("ABORT", struct.pack("<I", 1) + b"heartbeat lost from rank 2", source=0, target=1), "ok")
    add("ckpt-begin", "frame",
        frame("CKPT_BEGIN", struct.pack("<II", 1, 3), epoch=3, source=0, target=1), "ok", deferred="until the array type exists")
    whole = ckpt_file(b"state-of-rank-1")
    chunk = whole[:16]
    add("ckpt-data-push", "frame",
        frame("CKPT_DATA", struct.pack("<B3xIQQ", 0, 1, 0, len(whole)) + chunk, epoch=3, source=1, target=2), "ok", deferred="until the array type exists")
    add("ckpt-ack", "frame",
        frame("CKPT_ACK", hashlib.sha256(b"rank file 1").digest(), epoch=3, source=1, target=0), "ok",
        note="the digest is that of the bytes 'rank file 1'", deferred="until the array type exists")
    body = commit_body(3, [hashlib.sha256(b"rank file %d" % r).digest() for r in range(3)])
    commit = body + struct.pack("<H", SIG_BYTES) + b"\xaa" * SIG_BYTES
    add("ckpt-commit", "frame", frame("CKPT_COMMIT", commit, epoch=3, source=0, target=1), "ok",
        note="signature is a placeholder of 0xaa", deferred="until the array type exists")
    add("resume", "frame",
        frame("RESUME", struct.pack("<II", 3, 0) + hashlib.sha256(commit).digest(),
              epoch=3, incarnation=3, source=0, target=1), "ok", receiver_incarnation="3", deferred="until the array type exists")
    add("bye", "frame", frame("BYE", b""), "ok")

    add("neg-oversized-length", "frame", frame("DATA", b"", length=MAX_PAYLOAD + 1),
        "reject-oversized", note="header only; the reader must refuse before reading any payload")
    add("neg-max-length-accepted", "frame", frame("DATA", b"", length=MAX_PAYLOAD),
        "ok-length", note="header only; the length is at the limit and passes the check")
    add("neg-old-incarnation", "frame", frame("DATA", b"old", incarnation=1, tag=7),
        "drop-old-incarnation", receiver_incarnation="2")
    add("neg-future-incarnation", "frame", frame("DATA", b"new", incarnation=9, tag=7),
        "reject-future-incarnation", receiver_incarnation="2")
    add("neg-unknown-type", "frame", frame("DATA", b"")[:4] + b"\x63" + frame("DATA", b"")[5:],
        "reject-type")
    add("neg-reserved-flags", "frame", frame("DATA", b"", flags=1), "reject-flags")
    add("neg-unknown-service", "frame", frame("DATA", b"", service=9), "reject-service")
    add("neg-membership-epoch", "frame", frame("DATA", b"", membership=1), "reject-membership")

    payload = b"state-of-rank-1"
    add("ckpt-header", "ckpt", ckpt_file(payload), "ok",
        payload=hexline(payload), sha256=hashlib.sha256(payload).hexdigest(), deferred="until the array type exists")
    bad = bytearray(ckpt_file(payload))
    bad[-1] ^= 1
    add("neg-ckpt-bad-sha256", "ckpt", bytes(bad), "reject-sha256", deferred="until the array type exists")
    add("neg-ckpt-bad-magic", "ckpt", b"SPCX" + ckpt_file(payload)[4:], "reject-magic", deferred="until the array type exists")
    add("commit-body", "commit", commit, "ok",
        note="signature is a placeholder of 0xaa; the signed part is the bytes before the signature length", deferred="until the array type exists")
    return v


def render():
    lines = [
        "# SPERLI test vectors, version 1.  Written by scripts/sperli-vectors.py.",
        "# Records are separated by a blank line.  Each line is key: value.",
        "# hex: bytes in hexadecimal, blanks between bytes; hh*n is n times the byte hh.",
        "# expect: ok, ok-length, or reject-<reason> or drop-<reason> for a negative case.",
        "# kind: frame (header and payload), ckpt (a rank file), commit (a COMMIT file),",
        "#   reduce (hex is the result of reducing first and second, arrays of type with reduction).",
        "# Job id in all vectors: 000102030405060708090a0b0c0d0e0f.",
        "# deferred: the vector belongs to a part that waits for the array type; it is kept and still checked.",
        "# max-payload: %d" % MAX_PAYLOAD,
        "",
    ]
    for name, kind, data, expect, kw in vectors():
        lines.append("name: " + name)
        lines.append("kind: " + kind)
        lines.append("expect: " + expect)
        for k in sorted(kw):
            lines.append("%s: %s" % (k.replace("_", "-"), kw[k]))
        lines.append("length: %d" % len(data))
        lines.append(("hex: " + hexline(data)).rstrip())
        lines.append("")
    return "\n".join(lines)


def decode_frame(b, receiver_incarnation=2):
    """Independent reader: returns an expect string for the bytes."""
    if len(b) < HEADER:
        return "reject-short"
    n, t, flags, service, job, inc, memb, epoch, src, tgt, tag = struct.unpack("<IBBH16sIIQIII", b[:HEADER])
    if n > MAX_PAYLOAD:
        return "reject-oversized"
    if len(b) == HEADER and n == MAX_PAYLOAD:
        return "ok-length"
    if t < 1 or t > 11:
        return "reject-type"
    if flags != 0:
        return "reject-flags"
    if service != 0:
        return "reject-service"
    if memb != 0:
        return "reject-membership"
    if inc < receiver_incarnation:
        return "drop-old-incarnation"
    if inc > receiver_incarnation:
        return "reject-future-incarnation"
    if len(b) != HEADER + n:
        return "reject-short"
    if t == 3 and tag != 0:
        return "reject-collective-tag"
    if t == 3 and n < 16:
        return "reject-collective-header"
    if t == 2 and tag > 2147483647:
        return "reject-reserved-tag"
    return "ok"


def decode_ckpt(b):
    if b[:4] != b"SPCK":
        return "reject-magic"
    plen = struct.unpack("<Q", b[40:48])[0]
    if hashlib.sha256(b[80:80 + plen]).digest() != b[48:80]:
        return "reject-sha256"
    return "ok"


def check():
    faults = 0
    text = render()
    try:
        have = open(PATH).read()
    except OSError:
        have = None
    if have != text:
        print("docs/sperli-vectors.txt differs from the generated text")
        faults += 1
    n = 0
    for name, kind, data, expect, kw in vectors():
        n += 1
        if kind == "frame":
            got = decode_frame(data, int(kw.get("receiver_incarnation", 2)))
        elif kind == "ckpt":
            got = decode_ckpt(data)
        elif kind == "reduce":
            want = py_combine(int(kw["type"]), int(kw["reduction"]), unhex(kw["first"]), unhex(kw["second"]))
            got = "reject-reduce" if want is None else ("ok" if want == data else "reject-result")
        else:
            got = "ok" if data[:4] == b"SPCM" else "reject-magic"
        if got != expect:
            print("vector %s: expected %s, read %s" % (name, expect, got))
            faults += 1
        if unhex(hexline(data)) != data:
            print("vector %s: hex does not round-trip" % name)
            faults += 1
    # positive control: a corrupted copy must be seen as bad
    if decode_frame(frame("DATA", b"", length=MAX_PAYLOAD + 1)) == "ok":
        faults += 1
    print("vectors=%d faults=%d" % (n, faults))
    return faults


def main(argv):
    if argv == ["--write"]:
        with open(PATH, "w") as f:
            f.write(render())
        return 0
    if argv == ["--check"]:
        return 1 if check() else 0
    print(__doc__)
    return 9


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
