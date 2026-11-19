# 100-sperli

Standard.Sperli across processes.  Needs libtls (libretls on Debian) like 080-tls-server.

- 001: the programme starts itself three times as the ranks of a job through Standard.SperliLaunch, on localhost
  over TLS 1.3 with a certificate and a join token for each rank.  Each rank sends its number to the others and
  writes the sum of all three.  A second job lists a host below host-a.invalid and is refused with H1603 before any process
  starts.  The rank mode is chosen by the arguments the launcher gives; the job comes on the standard input.
- 002: the programme starts itself as the ranks of jobs of one to four ranks and every rank runs every collective
  (barrier, bcast, reduce, allreduce, gather, scatter) with every rank as the root, every reduce operation on every
  element type it fits, and negative numbers; a job of three ranks with wrong calls shows H1618 on every rank and the
  scatter that ends the job, and a job in which rank 0 asks for another operation shows H1617 and H1612.
- 003: the programme starts itself as the ranks of jobs that write two checkpoints and then lose a rank; the launcher
  starts the job again and every rank resumes.  One job loses the file of a rank and gets it from the buddy; one has a
  changed SHA-256 and is refused with H1620; one has a changed COMMIT signature so that the epoch before counts; one
  has no valid COMMIT and is refused with H1621; one has a changed magic in the file of a rank and in its buddy copy and
  is refused with H1619; one has lost the file of a rank and its buddy copy and is refused with H1622.
- 005: a job of one rank whose programme is /usr/bin/false, with --rank-program giving rank 0 the test programme, which
  joins and writes its sum; the same job without the option runs /usr/bin/false and ends with status 1.
- 006: the programme starts itself as the ranks of a job of two and one of three; the last rank computes for eight
  seconds, longer than the silence, without calling setSilence or heartbeat, while the others wait for it in a chain.
  Every rank gets its message, and the computing rank has written heartbeats from the runtime's thread.
- 007: a job of two ranks writes two checkpoints; a second job with --resume last resumes them, each rank its own
  state, and writes the next epoch under its own id; a job of three ranks that resumes the second is refused with
  H1623; a job with --checkpoint-every 1 checkpoints each time checkpointDue says so; --resume without a checkpoint
  directory is refused before any rank starts.
