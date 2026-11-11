Test that folding an expression of literals stops in onOverflow when an
intermediate step leaves Nat8, as the same steps do at run time, even
though the final value fits the type.
