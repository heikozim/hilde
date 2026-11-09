The same program as `001-embed-in-safe-module-rejected`, with
`pragma Unsafe_Module;` in front of the module body.  It must compile,
run and exit 0.

The exit code is the assertion: the program returns `ExitSuccess` only
if the embedded C computed 90 + 7 = 97, so a rule that refused the
`@embed` and a rule that silently dropped it would both show up here.
