The same as 025 for Float32, so that the rejection is not a property
of the integer types.

The typeclass here is `BitwiseOperations`, not `TrappingNegation` as in 025,
and the difference is deliberate: `Float32` has a `TrappingNegation`
instance in `Hilde.Pervasive`, so an instance for it here would be
refused by the overlap check before the orphan rule ever ran, and the case
would silently stop testing what its name says.  `BitwiseOperations` has no
Float32 instance, so the orphan rule is what answers.
