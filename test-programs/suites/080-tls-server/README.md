# 080-tls-server

The server side of `Standard.Tls` over a TCP listener of `Standard.File`.
The certificate is made at run time by
`scripts/fuzz/tls-certificate.sh`, so no private key lies in the tree.

- 001: a client task connects over TCP, verifies the certificate, sends a
  line and reads the echo the server wrote after its handshake; a client that
  sends no handshake is refused after 300 ms; a file that holds no key is
  refused as the key of a server.

- 002: mutual TLS: a server of `makeVerifyingServer` and the certificates of `scripts/tls/mutual-certificates.sh`; the client of the CA gets its echo and the server reads its subject and hash; a client without a certificate and one that signs itself are refused; the same with the CA from memory.

- 003: the peer has gone: a client task completes the handshake and
  closes, the server then writes until a write fails; the send answers Left
  and the programme goes on, where a write(2) of libtls would raise SIGPIPE
  and end it.
