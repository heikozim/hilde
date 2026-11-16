# 065-smtp

`Standard.Smtp`: one mail to `scripts/smtp/server.py`,
which makes its certificates at run time, listens on 127.0.0.1 and holds
the one dialogue in the way the test's mode names.  The client connects to
`localhost`, so every address the name has is tried in order: 127.0.0.1 is
the one that listens.  The relay prints what it saw, the login only as
whether it was right, and the lines of the data as they came.

- 001: STARTTLS, a login, two recipients, and lines that begin with one
  dot and with two, which go out with one more.
- 002: TLS from the first byte and a login.
- 003: cleartext to a relay on loopback, without a login.
- 004: a relay that does not offer STARTTLS is refused after EHLO; it
  would answer STARTTLS, but the client does not ask.
- 005: a reply line sent in the same write as the 220 to STARTTLS, before
  TLS, is refused.
- 006: a refused login whose refusal quotes the login back: the failure's
  detail is a fixed sentence, not the relay's words.
- 007: the second recipient refused, with the relay's reply as the detail.
- 008 and 011: the one time limit of one second holds against a relay that
  says nothing and one that sends its greeting a byte every 100 ms; each
  test also prints that it ended within three seconds.
- 009: a greeting without a code.
- 010: a certificate the client does not trust, after STARTTLS.
