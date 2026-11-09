# The C interface of the calamine bridge of the spreadsheet pilot: one
# opaque workbook the caller owns, reads that leave it with the caller,
# and every string copied into a buffer of the caller.  It is the header
# Diplomat writes from rust/calamine-bridge, and the generated module is
# the unsafe half of the safe layer bindings/Calamine.
module   Bindings.C.Calamine
header   fixtures/calamine.h
output   generated/Calamine
library  calamine
handle   CalamineSheet CalamineSheet calamine_destroy
struct   CalamineBytes CalamineBytes
struct   CalamineCell CalamineCell

function calamine_new
function calamine_open
function calamine_error
function calamine_sheet_count
function calamine_sheet_name
function calamine_sheet_rows
function calamine_sheet_columns
function calamine_cell
function calamine_cell_text
function calamine_destroy
