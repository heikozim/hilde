# The spec says what to take, because a header does not.
module   Bindings.C.Probe
header   fixtures/probe.h
output   generated/Probe
library  m

flags    ProbeFlags Nat32 PROBE_

function probe_add
function probe_zero
function probe_length
function probe_scale
