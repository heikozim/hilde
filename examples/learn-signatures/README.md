# learn-signatures

## What it shows

What a login with a second factor and with OpenID Connect needs.

- `Standard.Base32` writes the secret of RFC 6238 as an authenticator app
  takes it, and reads it back.
- `Standard.Otp` makes the otpauth URI the app reads from a QR code, the
  TOTP code at 59 seconds, and checks it a step later within a window of
  one and two steps later, when it is refused.
- `Standard.Jws` signs a token with a P-256, an RSA and an ML-DSA-65 key and
  verifies each with its public key, and finds an ID token expired.

The keys are made when the example runs.  The output is the same on every
system: ML-DSA does not come from the system's libcrypto.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-signatures
make
./main
```

## What comes out

```
the secret in base32: GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
and back: 12345678901234567890
for the app: otpauth://totp/Example:ann@example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example&algorithm=SHA1&digits=6&period=30
the code at 59 seconds: 94287082
taken a step later with a window of one: true
taken two steps later: false
ES256: the token verifies: true
RS256: the token verifies: true
ML-DSA-65: the token verifies: true
claims of an ID token at 1000: the token has expired
```
