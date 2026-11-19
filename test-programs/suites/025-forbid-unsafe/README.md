# 025-forbid-unsafe

`--forbid-unsafe-modules` refuses a module named on the command line that
carries `pragma Unsafe_Module;`.

What matters is the exemption: `Hilde.Pervasive` and
`Hilde.Memory` carry the pragma themselves, and every module imports
`Hilde.Pervasive` implicitly, so a flag that simply refused every unsafe
module would refuse every program ever written.  The exemption is by ORIGIN
and costs no list of names: the built-in modules are compiled from sources
embedded in the compiler and never pass the check at all.

001 is that exemption: a plain safe program, compiled WITH the flag, which
must build and run.  Without the exemption it could not, so this case is the
one that would fail if the built-ins were ever routed through the check.

002 is the refusal.
