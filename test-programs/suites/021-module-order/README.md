# 021-module-order

The compiler puts the modules it is given into an order in which each one is
compiled after the modules it imports from.

Every test here names its modules on the command line in an order that would
NOT compile if the order were taken as given: the importer stands before the
module it imports from.  That is the whole point of the case -- a test that
named them in a workable order would pass whether the compiler sorted
anything or not.

The negative control lives in the unit suite, `test/CompilerOrderTest.ml`:
there an already-correct order must come out unchanged, so that a function
which simply reversed its input would fail.

003 names a module that does not parse after the module that imports it: the answer is its parse error (H0008), not an unknown module for the importer (H2017).

004 is the same through --modules: the module given has a parse error in its body, and the modules found for it come before it; the answer is H0009, not H2017.

005: an unknown module a letter away from a known one is H2017 with the name it was most likely meant to be.
