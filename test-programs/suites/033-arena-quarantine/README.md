# 033-arena-quarantine

The arena quarantine.  The quarantine is a switch at compile time that is
OFF in the default build; every test here carries a `cflags.txt` with
`-DHILDE_ARENA_QUARANTINE`, so that the suite is built with it ON wherever
it runs, in the ordinary end-to-end run.

- 001: a pointer kept past `freeArena` -- good before the free (7 written
  and read back) -- faults when it is written after the free, even after a
  new arena of the same size has been made; exit by SIGSEGV, with the line
  on stderr written before the store, as in 032/001.
- 002: the quarantine holds 16 freed arenas per thread; after 17 frees the
  oldest comes out, open again, and the next `createArena` of its size gets
  it -- the same address -- with the byte written before its free
  overwritten to 0.
- 003: forty tasks with an arena each on four workers, twice, each arena
  freed into the quarantine of the worker that ran its task, while main
  makes new ones: one quarantine per thread, no lock; the checks run it
  under ThreadSanitizer.

The controls of 001 -- the same programme without the switch -- are not
tests: whether a stale write faults there depends on where the system puts
the next mapping.
