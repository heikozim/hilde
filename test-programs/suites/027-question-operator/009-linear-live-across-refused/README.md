The one that must NOT compile.  `r` is live when the ? may return, and
Hilde has no drop: the early return would lose it.  The refusal comes
from LinearityCheck's TReturn branch -- the operator needs no linearity
rule of its own -- and the message names the variable that would be lost
rather than the operator.
