#!/usr/bin/env python3
"""ChaCha20-Poly1305 (RFC 8439) in plain Python, for the tests of
Standard.Libcrypto.

    python3 scripts/crypto/chacha.py

Prints the seal of the three inputs of the seal test of Standard.Libcrypto,
in the lines that test prints.
Written from the algorithm's description, sharing nothing with OpenSSL.
When Python's `cryptography' package is there -- which calls OpenSSL --
every seal is also computed with it, and a disagreement stops the script
with exit 1: two implementations that agree are the reference, one alone
is not.  Exit 0 and the last line says how many were compared.
"""
import struct
import sys

M = 0xFFFFFFFF


def rotl(v, c):
    return ((v << c) & M) | (v >> (32 - c))


def quarter(s, a, b, c, d):
    s[a] = (s[a] + s[b]) & M
    s[d] = rotl(s[d] ^ s[a], 16)
    s[c] = (s[c] + s[d]) & M
    s[b] = rotl(s[b] ^ s[c], 12)
    s[a] = (s[a] + s[b]) & M
    s[d] = rotl(s[d] ^ s[a], 8)
    s[c] = (s[c] + s[d]) & M
    s[b] = rotl(s[b] ^ s[c], 7)


def block(key, counter, nonce):
    state = [0x61707865, 0x3320646E, 0x79622D32, 0x6B206574]
    state += list(struct.unpack("<8I", key)) + [counter] + list(struct.unpack("<3I", nonce))
    w = state[:]
    for _ in range(10):
        quarter(w, 0, 4, 8, 12)
        quarter(w, 1, 5, 9, 13)
        quarter(w, 2, 6, 10, 14)
        quarter(w, 3, 7, 11, 15)
        quarter(w, 0, 5, 10, 15)
        quarter(w, 1, 6, 11, 12)
        quarter(w, 2, 7, 8, 13)
        quarter(w, 3, 4, 9, 14)
    return struct.pack("<16I", *[(w[i] + state[i]) & M for i in range(16)])


def chacha20(key, counter, nonce, data):
    out = bytearray()
    for i in range(0, len(data), 64):
        stream = block(key, counter + i // 64, nonce)
        out += bytes(x ^ y for x, y in zip(data[i:i + 64], stream))
    return bytes(out)


def poly1305(key, message):
    r = int.from_bytes(key[:16], "little") & 0x0FFFFFFC0FFFFFFC0FFFFFFC0FFFFFFF
    s = int.from_bytes(key[16:], "little")
    p = (1 << 130) - 5
    acc = 0
    for i in range(0, len(message), 16):
        n = int.from_bytes(message[i:i + 16] + b"\x01", "little")
        acc = ((acc + n) * r) % p
    return ((acc + s) & ((1 << 128) - 1)).to_bytes(16, "little")


def pad16(data):
    return b"\x00" * ((16 - len(data) % 16) % 16)


def seal(key, nonce, plaintext, aad):
    one_time = block(key, 0, nonce)[:32]
    ciphertext = chacha20(key, 1, nonce, plaintext)
    mac_data = (aad + pad16(aad) + ciphertext + pad16(ciphertext)
                + struct.pack("<Q", len(aad)) + struct.pack("<Q", len(ciphertext)))
    return ciphertext + poly1305(one_time, mac_data)


key = bytes(range(32))
nonce = bytes(range(12))
aad = b"header"
inputs = [("empty", b""), ("short", b"attack at dawn"),
          ("long", bytes((i * 13 + 5) % 256 for i in range(100)))]
try:
    from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305
    other = ChaCha20Poly1305(key)
except ImportError:
    other = None
compared = 0
for name, data in inputs:
    sealed = seal(key, nonce, data, aad)
    if other is not None:
        if other.encrypt(nonce, data, aad) != sealed:
            print("chacha.py: %s disagrees with the cryptography package" % name, file=sys.stderr)
            sys.exit(1)
        compared += 1
    print("chacha20-poly1305 %s %s" % (name, sealed.hex()))
print("# compared with the cryptography package: %d of %d" % (compared, len(inputs)), file=sys.stderr)
