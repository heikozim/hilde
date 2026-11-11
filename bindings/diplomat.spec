# A Diplomat-style header: an opaque handle, a result copied into a buffer
# of the caller, and the one function that frees the object.  The handle
# is linear, so the compiler holds that nothing uses a value after
# diag_destroy, and the pointer parameters are checked ones for the safe
# layer over this module.  The slice and the flat result struct are passed
# by value, and the write object is the second handle, freed with the
# name Diplomat writes, diplomat_free_write.
module   Bindings.C.Diag
header   fixtures/diplomat.h
output   generated/Diag
library  diag
handle   Diag Diag
handle   DiplomatWrite DiplomatWrite diplomat_free_write
struct   DiplomatStringView DiplomatStringView
struct   DiagWriteResult DiagWriteResult

# The precondition the header states for the buffer of diag_write.
requires diag_write out_len > 0

function diag_new
function diag_write
function diag_destroy
function diag_measure
function diag_parse
function diplomat_write_str
function diplomat_make_write
function diplomat_free_write
