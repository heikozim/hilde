A user type with an instance of TrappingNegation: `-x` compiles and
calls the instance.  Before the type rule asked the resolver, the
instance was accepted and then never consulted, and this program did
not compile.
