# 047-sftp

`Standard.Sftp`: SFTP version 3 over the pipes of a child process.

The tests need no `sftp-server`: the server in these tests is
`scripts/sftp/replay.py`, which replays an exchange recorded against
OpenSSH's own `sftp-server` 10.0p1 by `scripts/sftp/oracle.py`: it holds
every request of the Hilde client to the recorded one byte for byte and
answers with the recorded reply.  Each test prints the replayer's exit
status last; 0 means every request matched and the whole exchange was
used.  The programme runs in a working directory of its own, two levels
under the tree, so it names the replayer and the exchange
`../../scripts/sftp/replay.py` and `../../test-programs/...`.

- 001: the recorded scenario.  The same programme, given
  `/usr/lib/openssh/sftp-server` as its first argument, runs against the
  real server and prints the same lines.
- 002: a reply that answers another request; the session is spoiled.
- 003: a server that offers another version; no session.  "No session"
  is also what a server that never ran gives, so 003 runs the replayer
  under `/bin/sh`, which writes its exit status to `server-exit.txt`, and
  prints it: `server exit: 0` only if the replayer ran and used the whole
  exchange.

002 and 003 are written by hand from 001's exchange and say so in their
first line.
