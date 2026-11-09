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
  has no valid COMMIT and is refused with H1621.
