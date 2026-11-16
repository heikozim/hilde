Test that a second instance of a foreign typeclass for a type that
already has one is rejected, even though the existing instance is in
another module.  Hilde.Pervasive declares instance
TrappingNegation(Int32); this module declares a second one.
