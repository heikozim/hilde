# 082-x509

`Standard.X509` against the `openssl` command.  Every key and
certificate is made at run time in the test's directory.

- 001: a CA on P-384 and a server certificate on P-256 for `localhost`, made
  here, verified by `openssl verify` and read by `openssl x509`; the server
  certificate serves a TLS handshake that `Standard.Tls` verifies against the
  CA; a request made by `openssl req` is turned into a certificate here and
  verified by `openssl verify`.
