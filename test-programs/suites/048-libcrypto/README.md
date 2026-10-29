# 048-libcrypto

`Standard.Libcrypto`: AES-256-GCM, ChaCha20-Poly1305, X25519 and Ed25519
through OpenSSL's EVP interface.

- 001 prints 11 lines, and its expected output is not its own: it is what
  `scripts/crypto/oracle.go` (Go's standard library) and
  `scripts/crypto/chacha.py` (ChaCha20-Poly1305 in plain Python, checked
  against Python's `cryptography` package) print for the same inputs --
  two implementations that share nothing with OpenSSL.  Both run on a
  host with Go and Python.
- 002: each seal opens, a flipped bit or other associated data is refused,
  a short key is refused, X25519 agrees both ways and refuses an all-zero
  key, Ed25519 verifies and refuses.
