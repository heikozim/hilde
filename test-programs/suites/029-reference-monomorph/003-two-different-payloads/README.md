The test that would fail if the erasure went one step too far.  Two
DIFFERENT payload types go through the same generic function and must
still get two different monomorphs: erasing the region must not erase the
type.  It prints 3 then 5, so a compiler that gave both the same struct
would print the wrong number rather than merely fail to build.

Calling the same generic twice with the SAME write reference would be no
test of this: it is refused with "The variable `r` has already been
consumed" -- a true answer to a question about linearity and no answer
at all about monomorphs.
