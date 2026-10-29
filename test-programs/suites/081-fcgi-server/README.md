# 081-fcgi-server

`Standard.FcgiServer` against a FastCGI client that shares no code with it.

- 001: `scripts/socket/fcgi-client.py`, written from the specification in
  Python, sends one request with a parameter of 200 bytes and a body; the
  loop takes the one connection, and the client prints the records it gets
  back.
