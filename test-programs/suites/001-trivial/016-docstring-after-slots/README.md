A docstring before a union case that follows a case with slots, or a case
with `is` and no slot, belongs to that case: the module parses, and the
cases are made and told apart.  A parser that took the docstring for a
slot's would stop at the `case` after it with H0005.
