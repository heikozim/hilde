# learn-pki

## What it shows

Keys and certificates without a network.

- `Standard.X509` checks a list of DNS names and refuses one with another
  kind of name in it, makes a CA on P-384 that signs itself, a key on
  Ed25519 and a request for two names, issues a certificate from the
  request, and verifies the chain for one of its names and not for another.
- `Standard.Acme` turns an ECDSA signature of a P-256 key into the form a
  JWS carries, in base64url, as an ACME client sends it.

Every key is made when the example runs; nothing is written to a file.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-pki
make
./main
```

## What comes out

```
www.example.org,example.org is a list of names: true
example.org,IP:192.0.2.1 is a list of names: false
the CA: Example Root
a CA: true
the server certificate: www.example.org
issued by: Example Root
for the names: www.example.org,example.org
a CA itself: false
the chain verifies for example.org
for example.net it does not verify
an ES256 signature in a JWS: 86 characters
```
