Negation.

Unary minus is its own operation, not a subtraction from zero.  Parsed as
`0 - x` it inherited the type of the zero, which is Int32, so it was a
type error for every other signed width and meant nothing at all for the
unsigned ones; only Int32 worked, and only by accident.

What the programs here demand, per type:

  * the negation of the minimum leaves the range of a signed type -- its
    opposite is one past the maximum -- and must be refused at run time,
    before the generated C computes it;
  * the negation of minimum + 1 is the maximum and must be computed;
  * Float64 negation is the IEEE 754 sign flip, so -(0.0) is -0.0.  A
    subtraction from zero gives +0.0, which is why the sign is printed
    rather than compared: the two are equal as doubles;
  * for the six unsigned integer types negation is refused at compile
    time, and so it is for Float32, which has no arithmetic at all.
