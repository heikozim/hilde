An `@embed` in a module-level constant is not inside any statement.
Austral compiles it, exit 0.

This test is why the span travels on the `@embed` node instead of being
taken from the enclosing statement.  A statement has a span and the
typing pass adorns errors with it, but a constant initialiser has none,
so that route would have produced a message with no file and no line
here.  The expectation file holds the span, so a later change that drops
it turns this test red.
