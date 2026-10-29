# learn-crypto

## What it shows

Cryptography through the system's libcrypto, with `Standard.Libcrypto`.

- SHA-256 of `abc` and an HMAC-SHA256, both the published test values.
- A message sealed and opened with ChaCha20-Poly1305; opened under another
  header it is refused.
- An Ed25519 public key from a fixed seed, a signature, and its check for
  the right and for another message.
- Random bytes, of which only the number is printed.

The keys are fixed so that the output is the same on every run.  A real
key comes from `randomBytes` and is never written into a programme.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-crypto
make
./main
```

## What comes out

```
SHA-256 of abc: ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
HMAC-SHA256: f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8
sealed: 30 bytes, the text and a tag of 16
opened: attack at dawn
opened under another header: refused
public key: d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a
the signature holds: true
for another message: false
random bytes: 32
```
