Only the standard library imports a Bindings module.

001 runs: a program reaches the clocks through the safe module
Standard.Time.

101 and 102 are refused with H2045: a program imports the binding
Bindings.Time (101), or the declarations of C that
scripts/gen-bindings.py writes, Bindings.C.Libcrypto (102).  Without the
rule, 102 would call C from a safe module without ever naming an address
type.
