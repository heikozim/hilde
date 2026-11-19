Negating a Float32.

In Austral `Float32` has no arithmetic at all, so `-a` is a type error.
Hilde gives Float32 its arithmetic, so the program compiles, and the case
checks that `-a` is not `a` -- which is
what it was always about.
