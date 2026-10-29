# 022-foreign-library

`pragma Foreign_Library(Name => "...")` in a module body head names a C
library the module needs.  The compiler collects the names of the modules it
reaches, deduplicates them keeping the first occurrence, links against them,
and writes them as the last line of the emitted C so that whoever compiles
that C can read them.

001 is the case the whole mechanism is for: a program that calls `sqrt` and
therefore needs libm.  It is a real test of the mechanism and not a
formality, because neither the compiler nor the test runner links libm on
its own -- without the pragma this program does not link.

002 is the refusal: a safe module has no C to link against, so it cannot name
a library.

003 declares a C function that returns nothing, `srand`: its Hilde result is
`Unit`, which the code generator must accept; a code generator that
refuses it says "Not allowed".

004 names two C headers with `pragma Foreign_Header` and takes two
constants from them through `@embed`: `EOF` and `CHAR_BIT`, -1 and 8 on
every platform Hilde supports.  `<stdio.h>` is the hard case on
purpose: it declares `fputc`, and the prelude declares it too, with `void*`
for the stream.  The compiler renames every such name while the headers
are read; without that, gcc stops with "conflicting types".

005 and 006 are the refusals: a safe module cannot name a header (H2042),
and a name that is not a header name -- here one with a `..` part -- is
refused before it reaches an `#include` (H2043).

007 to 009 are the library for one system: `System` names the
one system, as `uname -s` prints it, that a library is linked on.  007
names a library no machine has for `Darwin` and `m` for every system; on
Linux and on OpenBSD it links and runs, and with the compiler's filter
taken out it fails at the link with the library's name.  008 misspells
the system (`linux`) and is refused
with H2048; 009 gives the two arguments in the other order and is refused
with H2049.
