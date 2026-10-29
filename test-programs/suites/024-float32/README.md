# 024-float32

In Austral `Float32` has `Printable` and every conversion type class, and
no arithmetic at all: there is no `instance TrappingArithmetic(Float32)`
and no `instance TrappingNegation(Float32)`, while `Float64` has both.  So
`a + b` on two Float32 values was a type error, and a 32-bit float was a
storage type by accident rather than by decision.  Hilde gives Float32 its
arithmetic.

001 does the four operations and the negation, and divides by zero on
purpose, which must abort with the message the type names -- the Float32 one,
not the Float64 one, which is what a copied instance would have produced.
