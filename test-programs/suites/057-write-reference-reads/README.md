Reading through a write reference, and a reference to a part of a value
through a write reference; docs/differences-from-austral.md has the
rules.

001 to 006 run: a read borrow of a write reference, twice in one
expression, then a write (001); a read and a write reference to parts of a
record, each with the region of the write reference (002); the same read
borrow as a borrow statement (003); Standard.Map read through a write
reference (004); an assignment through the name of a write borrow, in main
and after a reborrow (005); a write reference held in a var and then in a
let, written through each (006).

101 to 114 are refused: the write reference is reborrowed (101) or used up
(102) while a read reference made from it lives; a map is changed while a
reference into it lives (103); a record is written after a reference to a
part of it has used the write reference up (104); a write through a read
reference to a part (105); a write reference to a part taken through a
read reference (106); an assignment through the read reference (107); the
read borrow handed out with the write reference's region (108); a
reference to a local returned as a region the caller chooses (109); a type
parameter fixed by the body (110); a write into a read span (111); a linear
value assigned through the name of a write borrow (112); the name of a read
borrow lent for writing (113); a write reference used under its old name
after it was moved to a new one (114).
