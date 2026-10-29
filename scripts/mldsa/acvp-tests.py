#!/usr/bin/env python3
"""Write standard/src/Bindings/MlDsa.test.hiq from the ML-DSA vectors of
NIST's ACVP server: a fixed choice of the cases of FIPS 204 that the pure,
external interface reaches.

    python3 scripts/mldsa/acvp-tests.py <dir> [--check]

<dir> holds the three files internalProjection.json of the server's
gen-val/json-files/ML-DSA-keyGen-FIPS204, ML-DSA-sigGen-FIPS204 and
ML-DSA-sigVer-FIPS204 as ML-DSA-keyGen-FIPS204.json and so on; their
sha256 must be the ones below, of the server's commit named below, so the
choice is the same every time.  --check compares with the file in the tree
instead of writing it.  Exit 0 written or current, 1 different, 9 could not
run.

The choice, for each of ML-DSA-44, -65 and -87: the first two key
generations; of signature generation with the external interface and no
pre-hash, the case with the shortest message of the deterministic group and
of the hedged one; of signature verification with that interface, the case
with the shortest message that must verify and, for each reason a case must
not, the one with the shortest message.
"""
import hashlib
import json
import os
import sys

COMMIT = "975de31eb83d87039ec88934fdc47d8c312b892d"
SHA256 = {
    "ML-DSA-keyGen-FIPS204.json": "e67ee6540d40e11506c3c4e3b1f79fc1cefcd49820db99fc61f87cc8ba463baf",
    "ML-DSA-sigGen-FIPS204.json": "72dcaf5f69853ca267ccd16af9cb40949786aca0fcfbf05d1ebeba132b93af22",
    "ML-DSA-sigVer-FIPS204.json": "47cdd6314c7f746d02421ffcba89d4dbc7bb875ac49e07a029fdfc26fba55437",
}
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "standard", "src", "Bindings", "MlDsa.test.hiq")
LEVELS = {"ML-DSA-44": 44, "ML-DSA-65": 65, "ML-DSA-87": 87}


def load(directory, name):
    path = os.path.join(directory, name)
    try:
        data = open(path, "rb").read()
    except OSError as e:
        sys.exit("ABORT: %s: %s" % (path, e))
    if hashlib.sha256(data).hexdigest() != SHA256[name]:
        print("ABORT: %s is not the file of commit %s" % (path, COMMIT), file=sys.stderr)
        sys.exit(9)
    return json.loads(data)


def pure(group):
    return group.get("signatureInterface") == "external" and group.get("preHash") == "pure"


def lit(hexstring):
    return '"' + hexstring.lower() + '"'


def build(directory):
    keygen = load(directory, "ML-DSA-keyGen-FIPS204.json")
    siggen = load(directory, "ML-DSA-sigGen-FIPS204.json")
    sigver = load(directory, "ML-DSA-sigVer-FIPS204.json")
    keys, signs, checks = [], [], []
    for g in keygen["testGroups"]:
        for t in g["tests"][:2]:
            keys.append((LEVELS[g["parameterSet"]], g["tgId"], t))
    for g in siggen["testGroups"]:
        if pure(g):
            t = min(g["tests"], key=lambda t: (len(t["message"]), t["tcId"]))
            signs.append((LEVELS[g["parameterSet"]], g["tgId"], t, g["deterministic"]))
    for g in sigver["testGroups"]:
        if pure(g):
            chosen = {}
            for t in sorted(g["tests"], key=lambda t: (len(t["message"]), t["tcId"])):
                reason = "valid" if t["testPassed"] else t["reason"]
                chosen.setdefault(reason, t)
            for reason in sorted(chosen):
                checks.append((LEVELS[g["parameterSet"]], g["tgId"], chosen[reason], reason))
    lines = []
    w = lines.append
    w("--")
    w("-- Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.")
    w("-- See LICENSE file for details.")
    w("--")
    w("-- SPDX-FileCopyrightText: 2026 Heiko Zimmermann")
    w("-- SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception")
    w("--")
    w("-- Written by scripts/mldsa/acvp-tests.py from the vectors of FIPS 204 on")
    w("-- the validation server of NIST, commit " + COMMIT + ".")
    w("-- Do not edit: change the script.")
    w("import Standard.Testing (")
    w("    assertTrue")
    w(");")
    w("import Standard.String (")
    w("    String,")
    w("    destroyString,")
    w("    asSpan")
    w(");")
    w("import Standard.Text (")
    w("    hexToBytes,")
    w("    bytesToHex,")
    w("    equal")
    w(");")
    w("import Bindings.MlDsa (")
    w("    KeyBytes,")
    w("    keypair,")
    w("    sign,")
    w("    verify")
    w(");")
    w("")
    w("module body Standard.Bindings.MlDsa.Test is")
    w("    -- The bytes of a hex literal of the vectors.")
    w("    function bytes(hex: Span[Nat8, Static]): String is")
    w("        case hexToBytes(hex) of")
    w("            when Some(value as made: String) do")
    w("                return made;")
    w("            when None do")
    w("                abort(\"a vector is no hex\");")
    w("        end case;")
    w("    end;")
    w("")
    w("    -- Whether text is, as lower-case hex, the hex literal want.")
    w("    generic [R: Region]")
    w("    function isHex(text: &[String, R], want: Span[Nat8, Static]): Bool is")
    w("        let hex: String := bytesToHex(asSpan(text));")
    w("        let same: Bool := equal(asSpan(&hex), want);")
    w("        destroyString(hex);")
    w("        return same;")
    w("    end;")
    w("")
    w("    -- Key generation: the seed gives the public and the secret key.")
    w("    function keyGenHolds(level: Int32, seed: Span[Nat8, Static], public: Span[Nat8, Static], secret: Span[Nat8, Static], name: Span[Nat8, Static]): Unit is")
    w("        let seedBytes: String := bytes(seed);")
    w("        case keypair(level, asSpan(&seedBytes)) of")
    w("            when Some(value as pair: KeyBytes) do")
    w("                let { public as madePublic: String, secret as madeSecret: String } := pair;")
    w("                assertTrue(isHex(&madePublic, public) and isHex(&madeSecret, secret), name);")
    w("                destroyString(madeSecret);")
    w("                destroyString(madePublic);")
    w("            when None do")
    w("                assertTrue(false, name);")
    w("        end case;")
    w("        destroyString(seedBytes);")
    w("        return nil;")
    w("    end;")
    w("")
    w("    -- Signature generation: the secret key signs message with context and")
    w("    -- randomness, all zero for the deterministic variant, to signature.")
    w("    function sigGenHolds(level: Int32, secret: Span[Nat8, Static], message: Span[Nat8, Static], context: Span[Nat8, Static], randomness: Span[Nat8, Static], signature: Span[Nat8, Static], name: Span[Nat8, Static]): Unit is")
    w("        let secretBytes: String := bytes(secret);")
    w("        let messageBytes: String := bytes(message);")
    w("        let contextBytes: String := bytes(context);")
    w("        let randomBytes: String := bytes(randomness);")
    w("        case sign(level, asSpan(&secretBytes), asSpan(&messageBytes), asSpan(&contextBytes), asSpan(&randomBytes)) of")
    w("            when Some(value as made: String) do")
    w("                assertTrue(isHex(&made, signature), name);")
    w("                destroyString(made);")
    w("            when None do")
    w("                assertTrue(false, name);")
    w("        end case;")
    w("        destroyString(randomBytes);")
    w("        destroyString(contextBytes);")
    w("        destroyString(messageBytes);")
    w("        destroyString(secretBytes);")
    w("        return nil;")
    w("    end;")
    w("")
    w("    -- Signature verification: the answer for public, message, context and")
    w("    -- signature is want.")
    w("    function sigVerIs(level: Int32, public: Span[Nat8, Static], message: Span[Nat8, Static], context: Span[Nat8, Static], signature: Span[Nat8, Static], want: Bool, name: Span[Nat8, Static]): Unit is")
    w("        let publicBytes: String := bytes(public);")
    w("        let messageBytes: String := bytes(message);")
    w("        let contextBytes: String := bytes(context);")
    w("        let signatureBytes: String := bytes(signature);")
    w("        let got: Bool := verify(level, asSpan(&publicBytes), asSpan(&messageBytes), asSpan(&contextBytes), asSpan(&signatureBytes));")
    w("        assertTrue(got = want, name);")
    w("        destroyString(signatureBytes);")
    w("        destroyString(contextBytes);")
    w("        destroyString(messageBytes);")
    w("        destroyString(publicBytes);")
    w("        return nil;")
    w("    end;")
    for level in (44, 65, 87):
        w("")
        w("    function testKeyGen%d(): Unit is" % level)
        for lv, tg, t in keys:
            if lv == level:
                w("        keyGenHolds(%d, %s, %s, %s, \"keyGen group %d case %d\");" % (level, lit(t["seed"]), lit(t["pk"]), lit(t["sk"]), tg, t["tcId"]))
        w("        return nil;")
        w("    end;")
        w("")
        w("    function testSigGen%d(): Unit is" % level)
        for lv, tg, t, det in signs:
            if lv == level:
                rnd = "00" * 32 if det else t["rnd"]
                kind = "deterministic" if det else "hedged"
                w("        sigGenHolds(%d, %s, %s, %s, %s, %s, \"sigGen %s group %d case %d\");" % (level, lit(t["sk"]), lit(t["message"]), lit(t.get("context", "")), lit(rnd), lit(t["signature"]), kind, tg, t["tcId"]))
        w("        return nil;")
        w("    end;")
        w("")
        w("    function testSigVer%d(): Unit is" % level)
        for lv, tg, t, reason in checks:
            if lv == level:
                w("        sigVerIs(%d, %s, %s, %s, %s, %s, \"sigVer %s group %d case %d\");" % (level, lit(t["pk"]), lit(t["message"]), lit(t.get("context", "")), lit(t["signature"]), "true" if t["testPassed"] else "false", reason, tg, t["tcId"]))
        w("        return nil;")
        w("    end;")
    w("end module body.")
    counts = (len(keys), len(signs), len(checks))
    return "\n".join(lines) + "\n", counts


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: acvp-tests.py <dir> [--check]")
    text, (k, s, v) = build(sys.argv[1])
    if "--check" in sys.argv[2:]:
        current = open(OUT).read() if os.path.exists(OUT) else ""
        print("acvp-tests --check: keyGen=%d sigGen=%d sigVer=%d %s" % (k, s, v, "current" if current == text else "DIFFERS"))
        return 0 if current == text else 1
    open(OUT, "w").write(text)
    print("acvp-tests: keyGen=%d sigGen=%d sigVer=%d written to %s (%d bytes)" % (k, s, v, OUT, len(text)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
