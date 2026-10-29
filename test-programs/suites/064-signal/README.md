# 064-signal

`Standard.Signal`: signals watched as events, PID
files, and the time limit of a shutdown.

- 001: SIGHUP, SIGUSR1 and SIGTERM sent to the programme itself with
  `sendSignal`; a watched signal does not end it, `waitSignal` wakes,
  `takeSignal` answers once per arrival, `shutdownRequested` once for
  SIGTERM; a second watch is refused while one is in place; a process
  number below 1 is refused.
- 002: a PID file written, read back as the process's number, removed
  twice; eight other files, of which six are refused and the two valid
  ones read.
- 003: `limitShutdown` sets and takes back the alarm.  That the kernel
  ends a process whose limit passes is not tested here, since the
  harness has no shape for a programme that must die by a signal.

Every file a test makes is removed by the test.
