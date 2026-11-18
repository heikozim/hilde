The operand of a ? may take a borrow, of a local (`&!box`) or as a reborrow
of a reference parameter (`&~w`), and the success value bound by the let may
be linear.  A compiler that lifted the borrow around the whole assignment
would no longer see the operator in the let, would bind the variable around
the case, and would refuse the early return with H4012 about that variable,
at every `let x: T := f(&~session, ...)?;`.  The reborrowed reference is
used again after the operator, so the borrow has ended there.
