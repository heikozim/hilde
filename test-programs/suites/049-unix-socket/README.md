# 049-unix-socket

A Unix domain socket in `Standard.File`: `listenUnix`, `acceptConnection`,
`acceptWithin`, `connectUnix`, `closeListener`.  Each
test makes its socket in its working directory and removes it again.  That
directory is one of its own, two levels under the tree, so 002 and
003 name their scripts `../../scripts/socket/...`, and the directory 003
puts at the path is `../../test-programs`.

- 001, in one process: connect, write before the server has accepted,
  accept, read, answer, read the answer -- twice on one listener; a second
  listener on a live socket is refused; after closing, the file is gone
  and a connect is refused.
- 002, a whole FastCGI request against a client that shares no code with
  `Standard.Fcgi`: `scripts/socket/fcgi-client.py`, written from the
  specification with Python's standard library.  The Hilde side reads the
  request record by record (`Standard.Fcgi.bytesAfterHeader`), answers with
  STDOUT and END_REQUEST, and closes; the client prints what it received,
  and the Hilde side prints that.
- 003, the refusals: an empty path; a path one byte over the platform's
  limit (and one at the limit, which works); a mode above `#o777`; a regular
  file, a directory and a fifo at the path, each left as it was; a stale
  socket, which is replaced; `acceptWithin` with nobody connecting; and
  the mode the kernel reports for `#o600` and `#o660`.  The stale socket and the
  fifo are made by `scripts/socket/fixture.py`, which also reads the mode.
  Negative controls: without the type test in the stale check,
  the regular file holding "keep me" and the fifo are REMOVED and replaced
  by sockets; without the chmod, both modes read 755.
- 004, a directory everybody may write to (mode 1777): the socket is made
  in a directory of its own and renamed to the path, listens with its
  mode, leaves nothing behind, and a file at the path is not replaced.
