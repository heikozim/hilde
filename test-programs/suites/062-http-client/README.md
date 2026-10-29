# 062-http-client

`Standard.HttpClient`: one HTTPS request to
`scripts/http/server.py`, which makes its certificates at run time, listens
on 127.0.0.1 and answers the one connection in the way the test's mode
names.  The client connects to `localhost`, so every address the name has is
tried in order: 127.0.0.1 is the one that listens.  The limits say
`publicOnly` false, since the server is on loopback; the library's own tests
(`standard/src/HttpClient.test.hiq`) refuse loopback with the defaults.

- 001 to 003: a body framed by a length, by chunks, and by the end of the
  connection.
- 004 and 005: an answer larger than the limit, announced and sent.
- 006 to 008 and 012: the whole time limit of one second holds against a
  server that stalls, drips the body, trickles one TLS record a byte at a
  time, or never answers the handshake; each test also prints that it ended
  within three seconds.
- 009: a status line the client does not read.
- 010: a POST, its body and a header line of the caller's.
- 011: an interim answer before the answer.
- 013: a certificate the client does not trust.
- 014: a port nobody listens at, without a server.
- 015 and 016: two lengths that disagree, and a chunk size that is not a
  number, refused as the framing a second reader could take differently.
- 017 and 018: a server that asks for a client certificate (mode mutual);
  requestAs presents the one the server made and is answered, request
  presents none and fails with TlsFailed.

Under valgrind 006, 007 and 008 are NOT RUN
(`test-programs/not-run-valgrind.txt`): valgrind's slowdown uses their
second up in the TLS handshake, so the limit still holds but runs out
before the request is sent, and the output differs.
