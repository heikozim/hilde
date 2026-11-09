# The same tool, reading a header the way a real one has to be read: through
# the C preprocessor.
module     Bindings.C.ProbePP
header     fixtures/probe-outer.h
output     generated/ProbePP
preprocess yes

flags      OuterFlags Nat32 OUTER_FLAG_

function   outer_twice
function   outer_half
function   probe_add
