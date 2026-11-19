Test that a module cannot give a built-in type an instance of a
foreign typeclass.  Nat8 belongs to the language, not to this module,
and TrappingNegation comes from Hilde.Pervasive.  Nat8 has no
TrappingNegation instance anywhere, so the uniqueness check cannot
fire here: this is the locality rule and nothing else.
