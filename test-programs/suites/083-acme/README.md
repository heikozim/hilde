# 083-acme

`Standard.Acme` against `scripts/acme/fake-ca.py`, an ACME server after RFC
8555 in Python that verifies every JWS with the `openssl` command.

- 001: an Ed25519 key refused as an account key; an account opened with a
  P-256 key, through one badNonce the server answers on purpose; an order for
  two names; the dns-01 challenge, whose TXT value and key authorization are
  compared with the server's own; the response and the authorization valid;
  the order finalized with a request made by `Standard.X509`; the certificate
  downloaded, read and verified against the server's CA.
