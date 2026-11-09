The case that made the gap worth closing: a safe module holding mutable
C state.  The embedded statement expression carries a `static` variable,
so the counter survives between the two calls, and the language has no
global mutable state of its own.

Before the rule this compiled, linked and ran with exit 0.  It must now
be refused like any other `@embed` outside an unsafe module.
