The success value of a ? may be LINEAR.  It works because the binding
goes inside the success branch of the case the operator becomes: on the
failure path there is no such variable, so the early return has nothing
to leak.  With the binding around the case this program would be refused
with "The variable `r` is not consumed by the time of the return
statement", about a variable that is not assigned on that path at all.
