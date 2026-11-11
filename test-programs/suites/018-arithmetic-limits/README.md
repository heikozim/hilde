Arithmetic at the limits of each numeric type.

Every program here drives one operation of the TrappingArithmetic class
past a limit and must be stopped by Hilde with the abort named in
program-stderr.txt.  A program that finishes, or that finishes with a
wrapped-around value, is a failure of the language, not of the test.

The suite exists because the meaning of the generated C must not depend on
a compiler switch.  It covers the three operations in every direction in
which they can leave the range, division by zero for every type, and for
the signed types the one quotient that leaves the range, minimum / -1.

Negation has its own suite, 019-negation: it is a different operation,
not a subtraction.
