Test that `@embed` is refused in a module that does not carry
`pragma Unsafe_Module;`.  `@embed` pastes C into the generated program
and the compiler does not check that C, so the module has to say so.

The message carries the span of the `@embed` itself, not of the
statement around it: see `hilde-stderr.txt`.
