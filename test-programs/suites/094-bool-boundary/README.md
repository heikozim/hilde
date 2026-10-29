# 094-bool-boundary

A Bool that comes from C is 0 or 1, and a C answer with more than two values is
read by the one that means success.

- 001: `@embed(Bool, ...)` of 2, -1, 256 and 2 to the 40 is true and equals
  true, 0 is false, 2 equals -1.  A plain cast would keep 2 as a third
  value and make 256 false.
- 002: a Foreign_Import with a Bool result is refused with H2059, whose
  message names the fix: the C result imported as Int32 and compared
  with /= 0.
- 003: the wait for a descriptor answers 0 for a closed descriptor, which
  poll reports as POLLNVAL, and 1 for a writable end, a byte to read and a
  read end that hung up.  A write end without a reader is not in it: Linux
  reports POLLOUT with POLLERR, the wait answers 1 as the runtime's does,
  and the write after it fails with EPIPE.  Linux sets the task runtime up
  for this programme, so 003 runs the runtime's wait.
- 004: the answer of the wait where there is no runtime (a platform
  without tasks, or a runtime that could not be set up), called with the
  events poll can report: 1 for the asked event and a hang-up on a read,
  0 for an error alone, an invalid descriptor, a hang-up on a write, the
  other event, a time out and a failed poll; a count of 1 alone does not
  answer 1.
- 005: `wctob` imported with an Int32 result, 65 for `A` compared
  with /= 0 is true, 0 false.
