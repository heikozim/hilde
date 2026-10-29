`e?;` as a whole statement: the failure is propagated and the success
value is thrown away.  The value discarded here is an Int32, which the
discard rule allows; had it been another Option it would be refused in
its turn, by that rule and not by this operator.
