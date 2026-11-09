# 093-traps

The traps of `docs/hilde-traps.md` that the compiler removes or names.

- 001 to 008 compile and run: a literal takes the type of the other operand,
  of the variable it is assigned to and of a generic parameter the other
  arguments or the asserted type bind; chains of `+`, `*`, `and` and `or`;
  the escapes `'\''` and `\u{...}`; a return in a branch that consumes a
  linear value; an if expression that consumes one in both branches; a
  parameter named like an imported function.
- 009 compiles and runs: an @embed calls a function of the runtime that
  lib/prelude.h declares while the module imports it, which H3106 leaves
  alone.
- 010 compiles and runs: the comparison operators on Int32, Float64, Bool,
  Unit, a reference and a type variable a call makes Int32, which H3107
  and H3108 leave alone.
- 011 stops with exactly the bytes of the span given to abort, a part of a
  longer literal; 012 calls two decisions of the runtime at their edges:
  the time limit of poll(2) and whether a seccomp filter for one thread
  confines the process.
- 101 to 117 are refused, each with the message that names the trap and,
  where it is one, the fix: H0009, H0010, H0011, H0008 with a free name,
  H6058, H3027 (a literal no longer narrows the other operand), H4015,
  H6020, H6043, H4010, H6059, H6060, H3105, H3061 with the module of the
  instance, H3106, H4012 with the note on Option.
- 119 is refused with H3054 and the note on the region of a borrow of a
  local variable, which has no name in the source.
- 120 and 121 are refused with H3107: = between two spans (cc refused the
  generated C otherwise) and between two records; 122 with H3108: a generic
  function compares values of a type variable that a call makes a span.
- 123 is refused with H0008: skip as the name of a let, with the suggestion
  skipCount in the text and as a suggestion of the JSON form.
- 118 is 101 with `--error-format=json`, the error in rustc's form.
- 124 is refused with H6043: an ensures borrows a field of its result,
  `&(result.n)`; an accessor that takes `&result` is the way.
- 125 is refused with H0005: a docstring between `pragma Slot;` and the
  declaration it marks.
- 126 is refused with H3060: a write reference handed on where a read
  reference is asked.
- 127 is refused with H0012: a field on the result of a call,
  `origin().x`; bind the result to a name first.
