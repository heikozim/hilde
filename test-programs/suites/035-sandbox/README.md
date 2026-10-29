Confining the running process, Standard.Sandbox: pledge and unveil on
OpenBSD, Landlock and seccomp on Linux, Capsicum on FreeBSD and Seatbelt
on macOS.

- 001: the report and the kernel are asked separately and must agree.
  Nothing is printed before the second policy, since on macOS the
  programme starts again under the profile.
- 002: a child confined to reading one path cannot open another (unveil
  on OpenBSD, Landlock on Linux, Seatbelt on macOS, Capsicum on
  FreeBSD); unconfined, the other path opens.
- 003: a child pledged to stdio alone is stopped by SIGABRT when it opens
  a socket; where there is no pledge it says so.
- 004: an invalid policy applies nothing, and the report says so.
- 005: 300 paths below /tmp are more names than unveil has room for:
  on OpenBSD nothing is applied, and with folding allowed they become
  /tmp, one path.
- 006: a programme started under execpromises of stdio and rpath is
  stopped by SIGABRT when it opens a socket; started without them it
  runs free.  Where there is no pledge the middle programme says so.
- 007: a confined child prints its line once and ends with a failure,
  and the parent sees that line and that failure; on macOS that is the
  first process passing on how the confined one ended.
- 008: a child confined to its working directory, given as ".", writes,
  reads back under "./" and removes a file by relative names, and still
  cannot open a path outside; unconfined, that path opens.

The expected output is the same on every platform the tests run on.
