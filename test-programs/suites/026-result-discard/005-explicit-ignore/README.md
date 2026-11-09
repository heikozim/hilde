The deliberate throw-away.  ignore() is the construct that says the
failure really is to be ignored here, and it compiles where a bare
discard does not.  What makes it a rule rather than a convention is
that the discarded expression is then of type Unit: the check in
TypingPass sees Unit and has nothing to object to.
