A generic function whose return type puts a WRITE reference inside a
generic type.  Austral's type checker accepts this and the C compiler
refuses the output: two structs for one type, differing only in a region
that has no run-time representation.  It prints 7, so a compiler that
emitted the right struct but the wrong value would fail it too.
