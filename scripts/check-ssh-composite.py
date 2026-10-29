#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""Standard.CompositeSig against OpenSSH's ssh-mldsa44-ed25519.

    python3 scripts/check-ssh-composite.py <work-dir>

Run from the top of a tree with ./hilde built.  ssh-keygen makes a key of
the type; its two seeds and its public key are read from the private key
file, and a Hilde programme, pledged to stdio before it touches a key where
the system has pledge, must make the same public key from the seeds, must
hold the signature ssh-keygen -Y sign makes, and must refuse it for another
message.  Its own signature of the same signed data, wrapped as SSHSIG, must
pass ssh-keygen -Y verify, and fail it for another message.  Prints one line
per check and a count; exit 0 when all held, 1 when one did not, 9 when it
could not run (no ssh-keygen with the type, no ./hilde).
"""
import base64
import hashlib
import os
import struct
import subprocess
import sys

ALG = b"ssh-mldsa44-ed25519"
CHECKS = 7


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, **kw)


def u32(b, at):
    return struct.unpack(">I", b[at:at + 4])[0], at + 4


def string(b, at):
    n, at = u32(b, at)
    return b[at:at + n], at + n


def put(s):
    return struct.pack(">I", len(s)) + s


def armored(text, label):
    lines = text.strip().splitlines()
    if lines[0] != "-----BEGIN %s-----" % label or lines[-1] != "-----END %s-----" % label:
        raise ValueError("not " + label)
    return base64.b64decode("".join(lines[1:-1]))


def private_key(path):
    """The public key and the 64 bytes of the two seeds of an unencrypted
    OpenSSH private key of the type."""
    b = armored(open(path).read(), "OPENSSH PRIVATE KEY")
    magic = b"openssh-key-v1\0"
    if not b.startswith(magic):
        raise ValueError("no openssh-key-v1")
    at = len(magic)
    cipher, at = string(b, at)
    kdf, at = string(b, at)
    _, at = string(b, at)
    count, at = u32(b, at)
    if cipher != b"none" or kdf != b"none" or count != 1:
        raise ValueError("an encrypted key or more than one")
    _, at = string(b, at)
    section, at = string(b, at)
    c1, s = u32(section, 0)
    c2, s = u32(section, s)
    kind, s = string(section, s)
    public, s = string(section, s)
    seeds, s = string(section, s)
    if c1 != c2 or kind != ALG or len(public) != 1344 or len(seeds) != 64:
        raise ValueError("not a key of %s" % ALG.decode())
    return public, seeds


def signed_data(namespace, message):
    """The blob SSHSIG signs: the magic, the namespace, the reserved string,
    the hash algorithm and the hash of the message."""
    return b"SSHSIG" + put(namespace) + put(b"") + put(b"sha512") + put(hashlib.sha512(message).digest())


def sshsig_signature(text):
    b = armored(text, "SSH SIGNATURE")
    if not b.startswith(b"SSHSIG"):
        raise ValueError("no SSHSIG")
    at = 6
    _, at = u32(b, at)
    public, at = string(b, at)
    namespace, at = string(b, at)
    _, at = string(b, at)
    hashalg, at = string(b, at)
    inner, at = string(b, at)
    kind, i = string(inner, 0)
    raw, i = string(inner, i)
    if kind != ALG or hashalg != b"sha512" or len(raw) != 2484:
        raise ValueError("not a signature of %s with sha512" % ALG.decode())
    return public, namespace, raw


def sshsig_text(public_blob, namespace, raw):
    inner = put(ALG) + put(raw)
    b = b"SSHSIG" + struct.pack(">I", 1) + put(public_blob) + put(namespace) + put(b"") + put(b"sha512") + put(inner)
    body = base64.b64encode(b).decode()
    return "-----BEGIN SSH SIGNATURE-----\n" + "\n".join(body[i:i + 76] for i in range(0, len(body), 76)) + "\n-----END SSH SIGNATURE-----\n"


MODULES = ["Buffer", "String", "StringBuilder", "Text", "Bindings/File", "File", "Bindings/Platform", "Platform",
           "Bindings/Sandbox", "Sandbox", "*bindings/generated/Libcrypto", "Bindings/Libcrypto", "Libcrypto",
           "Bindings/MlDsa", "MlDsa", "CompositeSig"]

PROGRAMME = """import Standard.String (
    String,
    fromLiteral,
    destroyString,
    asSpan
);
import Standard.Text (
    bytesToHex,
    hexToBytes,
    equal,
    substring
);
import Standard.Sandbox (
    Report,
    makePolicy,
    allowPromises,
    applyPolicy,
    reportApplied,
    sandboxAvailable
);
import Standard.CompositeSig (
    CompositeKey,
    openSshLabel,
    keypairFromSeeds,
    publicKeyOf,
    sign,
    verify,
    destroyCompositeKey
);

module body Interop is
    function bytes(hex: Span[Nat8, Static]): String is
        case hexToBytes(hex) of
            when Some(value as b: String) do
                return b;
            when None do
                abort("no hex");
        end case;
    end;

    function main(): ExitCode is
        if sandboxAvailable() then
            let promises: String := fromLiteral("stdio");
            let applied: Report := applyPolicy(allowPromises(makePolicy(), asSpan(&promises)));
            destroyString(promises);
            printLn(reportApplied(applied));
        else
            printLn("no sandbox");
        end if;
        let seeds: String := bytes(@SEEDS@);
        let public: String := bytes(@PUBLIC@);
        let data: String := bytes(@DATA@);
        let other: String := bytes(@OTHER@);
        let theirs: String := bytes(@SIGNATURE@);
        case keypairFromSeeds(substring(asSpan(&seeds), 0, 32), substring(asSpan(&seeds), 32, 64)) of
            when Some(value as key: CompositeKey) do
                let mine: String := publicKeyOf(&key);
                printLn(equal(asSpan(&mine), asSpan(&public)));
                destroyString(mine);
                printLn(verify(asSpan(&public), openSshLabel(), asSpan(&data), "", asSpan(&theirs)));
                printLn(verify(asSpan(&public), openSshLabel(), asSpan(&other), "", asSpan(&theirs)));
                case sign(&key, openSshLabel(), asSpan(&data), "") of
                    when Some(value as signature: String) do
                        let hex: String := bytesToHex(asSpan(&signature));
                        printLn(asSpan(&hex));
                        destroyString(hex);
                        destroyString(signature);
                    when None do
                        printLn("no signature");
                end case;
                destroyCompositeKey(key);
            when None do
                printLn("no key");
        end case;
        destroyString(theirs);
        destroyString(other);
        destroyString(data);
        destroyString(public);
        destroyString(seeds);
        return ExitSuccess();
    end;
end module body.
"""


def main():
    if len(sys.argv) != 2:
        print("usage: python3 scripts/check-ssh-composite.py <work-dir>", file=sys.stderr)
        return 9
    work = sys.argv[1]
    os.makedirs(work, exist_ok=True)
    if not os.access("./hilde", os.X_OK):
        print("ssh-composite: NOT RUN -- no ./hilde")
        return 9
    key = os.path.join(work, "k")
    for p in (key, key + ".pub"):
        if os.path.exists(p):
            os.remove(p)
    made = run(["ssh-keygen", "-q", "-t", "mldsa44-ed25519", "-N", "", "-C", "hilde", "-f", key])
    if made.returncode != 0:
        print("ssh-composite: NOT RUN -- ssh-keygen makes no mldsa44-ed25519 key: %s" % made.stderr.decode().strip())
        return 9
    public, seeds = private_key(key)
    message = b"the message signed by ssh-keygen\n"
    other = b"another message\n"
    msgfile = os.path.join(work, "message")
    open(msgfile, "wb").write(message)
    signed = run(["ssh-keygen", "-q", "-Y", "sign", "-f", key, "-n", "file", msgfile])
    if signed.returncode != 0:
        print("ssh-composite: NOT RUN -- ssh-keygen -Y sign: %s" % signed.stderr.decode().strip())
        return 9
    blob_public, namespace, theirs = sshsig_signature(open(msgfile + ".sig").read())
    data = signed_data(namespace, message)
    src = PROGRAMME
    for name, value in (("SEEDS", seeds), ("PUBLIC", public), ("DATA", data), ("OTHER", signed_data(namespace, other)), ("SIGNATURE", theirs)):
        src = src.replace("@%s@" % name, '"%s"' % value.hex())
    hiq = os.path.join(work, "Interop.hiq")
    open(hiq, "w").write(src)
    mods = []
    for m in MODULES:
        base = m[1:] if m.startswith("*") else "standard/src/" + m
        mods.append("%s.hih,%s.hiq" % (base, base))
    exe = os.path.join(work, "interop")
    built = run(["./hilde", "compile"] + mods + [hiq, "--entrypoint=Interop:main", "--output=" + exe])
    if built.returncode != 0:
        print("ssh-composite: BAD the programme did not build")
        print(built.stdout.decode()[-2000:] + built.stderr.decode()[-2000:])
        return 1
    ran = run([exe])
    lines = ran.stdout.decode().splitlines()
    good = 0
    checks = []
    checks.append(("the programme ran", ran.returncode == 0 and len(lines) == 5))
    while len(lines) < 5:
        lines.append("")
    checks.append(("pledged to stdio where there is pledge", lines[0] in ("true", "no sandbox")))
    checks.append(("the same public key from the seeds", lines[1] == "true"))
    checks.append(("ssh-keygen's signature holds", lines[2] == "true"))
    checks.append(("and not for another message", lines[3] == "false"))
    ok_sig = False
    refused_other = False
    try:
        mine = bytes.fromhex(lines[4])
        sigfile = os.path.join(work, "hilde.sig")
        open(sigfile, "w").write(sshsig_text(blob_public, namespace, mine))
        signers = os.path.join(work, "allowed")
        open(signers, "w").write("hilde " + open(key + ".pub").read().split(" ", 2)[0] + " " + open(key + ".pub").read().split(" ", 2)[1] + "\n")
        v = run(["ssh-keygen", "-Y", "verify", "-f", signers, "-I", "hilde", "-n", "file", "-s", sigfile], input=message)
        ok_sig = v.returncode == 0
        w = run(["ssh-keygen", "-Y", "verify", "-f", signers, "-I", "hilde", "-n", "file", "-s", sigfile], input=other)
        refused_other = w.returncode != 0
    except ValueError:
        pass
    checks.append(("ssh-keygen -Y verify holds Hilde's signature", ok_sig))
    checks.append(("and refuses it for another message", refused_other))
    for what, held in checks:
        print("ssh-composite: %s %s" % ("held" if held else "BAD", what))
        good += 1 if held else 0
    print("ssh-composite: held=%d of %d (pledge line %s)" % (good, CHECKS, lines[0]))
    return 0 if good == CHECKS else 1


if __name__ == "__main__":
    sys.exit(main())
