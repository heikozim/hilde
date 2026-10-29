# Traps in writing Hilde

Every trap met in writing the compiler, the standard library or an
application built on them, in one list: the error code and what the
compiler said, the wrong and the right code, and a rule in one sentence.
The line Now says what the compiler does about it now: the trap is
removed, or the message names it and suggests the fix, or nothing changed
and why.  The line Test names the test that holds it.  New entries go at
the end.

## Language and compiler

### 1. A linear value consumed in a branch that returns

- Error: `H4004` Linearity Error, "The variable `box` is used inconsistently
  in the branches of an if statement."
- Wrong: `if bad then destroy(x); return y; end if;` and `x` used further down
- Right before: an `else` that holds the rest, or the decision taken before
  the if
- Now: removed.  A branch that ends in a return on every path does not reach
  the statement after the if or the case, and its return has checked that
  every linear variable is consumed; the other branches alone decide the
  state after it.
- Test: `093-traps/006-return-in-a-branch` (if and case)

### 2. An integer literal is an Int32 where its place asks for another type

- Errors: `H3060` "Expected a value of type `Nat64`, but got a value of type
  `Int32`", `H3003` "The type parameter `T` cannot be bound to both `Int64`
  and `Int32`", `H3027` "Cannot cast to `Int64` from `Int32`", `H3055` for the
  constructor
- Wrong: `pages := 1;` with a `Nat64`, `insertBack(&!odd, 3)` with a
  `Buffer[Int64]`, `55 + idLength` with an `Index`
- Right before: a typed constant, `constant one: Nat64 := 1;`
- Now: removed.  A literal takes the type of the variable or path it is
  assigned to, of the other operand of an operator on either side, of a
  generic parameter that the other arguments bind, and of the type a
  constructor or generic call is to have; the assigned value of a
  constructor gets the type of its variable.  A literal only stays an Int32
  where nothing asks for a type.  One thing is refused that was taken:
  `1 + n` with `n` a `Nat64` was an Int32 addition that narrowed `n`
  without a word, and is now a `Nat64`.
- Still: a literal assigned through a path of a reference, `p->n := 0;` with
  `p: &![Counter, R]` and `n: Index`, is `H3060` (Int32, not Index); bind it
  first, `let zero: Index := 0; p->n := zero;`.
- Test: `093-traps/001-literal-takes-the-other-operand`,
  `002-literal-takes-the-assigned-type`, `003-literal-in-a-generic-call`,
  `107-literal-no-longer-narrows`

### 3. No operator precedence

- Error: `H0005` Parse Error, "Error during parse."
- Wrong: `a or b or c`, `start + 32 <= n`, `at + 826 * 86400`
- Right: `(a or b) or c`, `(start + 32) <= n`, `at + (826 * 86400)`
- Now: a chain of one of the associative operators `+`, `*`, `and` and `or`
  parses and is grouped from the left; any other operator after an
  operation is `H0009`, which says that Hilde has no precedence and suggests
  the parentheses around the operation before the operator.  Precedence
  itself stays out by design.
- Test: `093-traps/004-operator-chains`, `101-operators-mixed`,
  `102-minus-chain`, `118-rustc-json`

### 4. A local named like a declaration of the module

- Error: `H6045` "The variable `allowed` collides with the name of a
  declaration."
- Rule: a local or parameter takes a name that no declaration of the module
  has.
- Now: unchanged; the message names the collision.  A collision inside one
  module is one its writer sees and fixes in the same file.
- Test: the catalog entry H6045 in `docs/errors.en.md`

### 5. A parameter named like an imported function

- Error: `H3055` "`start` is generic but unconstrained", or `H3050` for
  `start + 1`: the name meant the imported function
- Now: removed.  A local or a parameter named like an imported declaration
  means the local inside its function.  A refusal as for item 4 would break a
  module whenever another module it imports adds a function of the same
  name.
- Test: `093-traps/008-local-shadows-an-import`

### 6. The interface imports what its contracts call

- Error: `H6039` "I can't find a callable named `length`."
- Now: `H6060` names the module that declares a function of that name, gives
  the import line, and says that an interface imports what its own contracts
  call.
- Test: `093-traps/113-interface-contract-calls-an-import`

### 7. A typeclass in a constraint that the module does not import

- Error: `H9999` Internal Error, "No typeclass with the given name."
- Now: `H3105`, which names the typeclass and the module that declares it,
  with the import line.
- Test: `093-traps/114-typeclass-imported-nowhere`

### 8. An instance whose module is not imported

- Error: `H3061` "the type `Int64` does not implement the typeclass
  `TotalOrder`."
- Now: `H3061` says, where an instance exists in a module that is not
  imported, which module holds it and how to import it.
- Test: `093-traps/115-instance-not-imported`

### 9. No valueOr in the language

- Error: `H6039` "I can't find a callable named `valueOr`."
- Rule: `valueOr` is a helper of single test files; a module that wants it
  declares it.
- Now: unchanged for a name no module declares; a name another module
  declares gets `H6060` (item 6).
- Test: the catalog entry H6039

### 10. A contract that reads a byte of a String

- Error: `H3098` "This condition calls `Standard.String.nthByte -> ... ->
  @embed`"
- Now: unchanged; the message names the chain of calls down to the C.
- Test: the catalog entry H3098

### 11. A field of a written reference, or a reborrow, used twice

- Error: `H4011` "Cannot borrow ... because it is already consumed", "Cannot
  reborrow ... because it is already borrowed"
- Rule: `&!(r->field)` and a write reference passed on use the reference up;
  a borrow in an expression lasts to the end of its statement.
- Now: the rule stays, it is what linearity is; `H4011` says it: for a write
  reference that is used up, a reborrow of its own for each use; for a
  borrow, one statement per borrow.
- Test: `007-borrowing/004`, `005`, `012`, `057-write-reference-reads/101`,
  `103` with their new expected output

### 12. A borrowed literal and the apostrophe

- Errors: `H0005` for `get(&!cache, &1, 0)`; `H0001` "Character not allowed"
  for `'\''`
- Now: `'\''` is the apostrophe, 39.  `&1` is `H0011`, which says that only a
  variable is borrowed and shows the binding to write first.
- Test: `093-traps/005-escapes`, `104-borrowed-literal`

### 13. A reserved word as a name

- Error: `H0008`, a parse error that names the word
- Now: `H0008` suggests a free name for the words most often taken for one:
  `from` since, `to` until, `body` content, `end` finish, `type` kind, `case`
  choice, `record` entry, `union` variant.
- Test: `093-traps/105-reserved-word-suggests-a-name`, `084-reserved-words`

### 14. An index on the result of a call

- Error: `H0005`
- Now: `H0010` says that an index stands after a name and shows the binding
  to write first.  Not removed: an index on a call would borrow a value that
  has no variable to live in.
- Test: `093-traps/103-index-on-a-call`

### 15. An index of a module constant

- Error: `H6039` "I can't find a variable named `digits`." with no place in
  the source
- Now: `H6059` with the place: a path is read through a borrow, a constant
  cannot be borrowed, and the message shows the local to bind first.
- Test: `093-traps/112-index-of-a-constant`

### 16. A path into a value instead of a reference

- Error: `H6043` "The head of a reference transform expression must be of a
  reference type, but I got `Stamp`"
- Now: `H6043` shows the function over `&[T, R]` that returns `&(r->slot)`.
- Test: `093-traps/110-path-of-a-value`, `013-ref-transforms/001`

### 17. A binding of a case that takes a name bound before

- Error: `H6020` "push_var: var with the name stamp already exists"
- Now: `H6020` says that a name stays bound to the end of its block, also
  after its value is consumed, and suggests another name.
- Test: `093-traps/109-case-binding-takes-a-bound-name`

### 18. A linear var assigned again, and None of a linear Option built early

- Errors: `H4010` "Cannot assign to the variable `result` because it is not
  yet consumed."; `H4012` "The variable `nothing` is not consumed by the time
  of the return statement."
- Rule: an Option of a linear type is linear, also as None, and a var of a
  linear type takes a new value only after the old one is consumed.
- Now: the rule stays; `H4010` says it, and `H4012` says it for a variable of
  an Option or Either.
- Test: `093-traps/111-linear-var-assigned-again`,
  `117-option-built-before-the-branches`

### 19. A linear value in the branches of an if expression

- Error: `H4005` "The variable `plain` is consumed multiple times within the
  same expression."
- Now: removed: one branch runs, so a value both branches consume once is
  consumed once.  Found on the way: a value only one branch consumed was
  taken and left unconsumed on the other path; that is `H4015` now.
- Test: `093-traps/007-if-expression-consumes-in-both-branches`,
  `108-if-expression-one-branch`

### 20. A span of a borrow of a local bound with a region name

- Error: `H3054` "The slot `there` should have type `Span[Nat8,
  Region<5782>]` but is declared to have type `Span[Nat8, R]`"
- Now: `H3054` says, for a region of a borrow of a local, that it has no name
  in the source, and how to use the value instead.
- Test: `093-traps/119-region-of-a-local-borrow`

### 21. Two modules export the same name

- Error: `H2027` "Colliding imports"
- Now: `H2027` shows the import with `as`.
- Test: the catalog entry H2027

### 22. \u{...} in a string literal

- Error: none; the six characters stayed in the string as written
- Now: `\u{X}` writes the code point X, one to six hexadecimal digits, as
  UTF-8; a code point above 10FFFF or a surrogate is `H6058`.
- Test: `093-traps/005-escapes`, `106-unicode-escape-out-of-range`

### 23. An imported C function inside @embed

- Error: gcc, "implicit declaration of function `duckdb_close`"
- Now: `H3106`: a call of a C name that the programme imports through
  `pragma Foreign_Import`, inside the text of an @embed, is refused with the
  Hilde name to call.
- Test: `093-traps/116-embed-calls-an-import`

### 24. None() as an argument of a parameter of type Option

- Error: `H3055` "`None` is generic but unconstrained"
- Wrong: `second(box, None())` with a parameter `choice: Option[Int32]`
- Right: `let none: Option[Int32] := None();` and `second(box, none)`
- Now: taken: an argument refused with `H3055` is checked
  once more with the type of its parameter, when that type is written out
  or decided by the type expected of the call; so `Right(right => None())`
  in a `let` of `Either[Int32, Option[Int32]]` is taken as well.  A
  parameter of the callee's own type variable, as `ignore(None())` or
  `isEmpty(None())` over `Option[T]`, still decides nothing and stays
  `H3055`.
- Test: `086-open-type/003-none-decided-by-its-place`

## Outside the compiler

### 25. Checks that name a generated C variable

- Rule: after a change to the names in the generated C, search `scripts/`
  for the old names before the checks run again.
- Now: unchanged; it is a rule for whoever changes the code generator.

### 26. SQLite and SQLCipher in one programme

- Error: `H2044` "This programme links both `sqlite3` and `sqlcipher`"
- Now: unchanged; the message names both, and Standard.SqlCipher opens plain
  files with `openPlainWriter` and `openPlainReader`.
- Test: `088-database`

### 27. A setting of DuckDB that says yes to anything

- Rule: a protection is checked where it acts: Standard.DuckDB reads the
  settings back after the open.
- Test: `091-duckdb`

### 28. A commit of DuckDB after a failed statement

- Rule: a database that aborts a transaction on the first error may still
  call its commit a success; Standard.DuckDB rolls back with an error.
- Test: `091-duckdb/004`

### 29. A data: URL in a URL attribute of a template

- Effect: `src="#ZgotmplZ"` instead of the image
- Rule: in `href`, `src` and attributes with `src`, `uri` or `url` in the
  name, every scheme but http, https and mailto becomes `#ZgotmplZ`, by
  design; a value the server
  makes itself goes through `|safe` with the reason beside it.
- Test: `045-template`

### 30. A function of a newer Hilde in an application built with an older one

- Error: `H2030` for a function the Hilde the application is built with
  does not have yet
- Rule: an application builds against the Hilde it is built with; what is
  missing there is missing for it.

### 31. An anchored pattern with a literal after its start

- Now: fixed in Standard.Regex: an anchored pattern skips the search for
  its required literal.
- Test: `043-regex/012`

### 32. = between two spans

- Error: cc, "invalid operands to binary ==" on `hilde_span_t`
- Wrong: `word = "export "` with `word: Span[Nat8, Static]`
- Right: `equal(word, "export ")` with Standard.Text's `equal`
- Now: `H3107`: a comparison of spans, records or unions is refused by the
  type checker, `H3108` where a call makes a type variable one of them.
- Test: `093-traps/120` to `122`, `093-traps/010` for what still compares

### 33. A reserved word as a name: is, skip and the others

- Error: a parse error; at the time shown as `H2017` for another module (34)
- Wrong: `function is(found: Option[String], expected: Span[Nat8, Static]): Bool`,
  `let skip: Int32 := 3;`
- Right: `function holds(...)`, `let skipCount: Int32 := 3;`
- Now: `H0008` names the word and suggests a free name, in the text and as a
  suggestion of the JSON form (`skip` gives `skipCount`, `is` gives `holds`).
- The reserved words, all of them: `and`, `as`, `body`, `borrow`, `case`,
  `constant`, `do`, `else`, `end`, `ensures`, `false`, `for`, `from`,
  `function`, `generic`, `if`, `import`, `instance`, `invariant`, `is`,
  `let`, `method`, `module`, `nil`, `not`, `of`, `or`, `pragma`, `raise`,
  `raises`, `record`, `requires`, `return`, `sizeof`, `skip`, `then`, `to`,
  `true`, `type`, `typeclass`, `union`, `var`, `when`, `while`, and the type
  words `Free`, `Linear`, `Region`, `Type` and `Span` (docs/syntax.en.md,
  section 1).
- Test: `084-reserved-words/006`, `093-traps/123`

### 34. An unknown module for a parse error elsewhere

- Error: `H2017` "Unknown module `Standard.String`" for `Bindings.File`
- Now: a module whose head cannot be read makes the order report its own parse
  error instead of leaving the modules unsorted.
- Test: `021-module-order/003` and `004`

### 35. A value made up to return after abort

- Error: `H2031` "The function `x` does not end in a return statement."
  when a function ended in `abort(...)` and nothing after it
- Wrong: `abort("bad"); return 0;`, a value no caller ever sees
- Right: `abort("bad");` as the last statement
- Now: removed.  `abort` returns `Never`, and a call of a function that
  returns `Never` ends a path as a return does; 139 of the 160 values are
  gone.
- Test: `098-never-and-slots/001-ends-in-abort`, `002-own-never-function`

### 36. A docstring between pragma Slot and its declaration

- Error: `H0005` "Error during parse." at the docstring
- Wrong: `pragma Slot;`, then a docstring, then `function sqliteClose(...)`
- Right: the docstring before `pragma Slot;`, or a `--` comment above the
  group of slots, which the contract check (`scripts/check-contracts.py`)
  takes for each slot of the group; both check with exit 0
- Rule: nothing stands between `pragma Slot;` and the declaration it marks.
- Now: nothing changed: the parser still refuses a docstring there, and the
  contract check takes the comment above a group of slots for each of them.
- Test: `093-traps/125-docstring-after-slot-pragma`

### 37. A write reference handed on where a read reference is asked

- Error: `H3060` "Expected a value of type `&[Manifest, R]`, but got a value of
  type `&![Manifest, Region<...>]`."
- Wrong: `peek(x)` or `peek(&~x)` with `x: &![T, R]` and `peek` over `&[T, R]`
- Right: take the value and give it back, `function set(m: Manifest, ...):
  Manifest`, and inside borrow it for reading and for writing in turn; or give
  the function a write reference too, as `Standard.Buffer.lengthMut` does
- Now: nothing changed: a write reference is not read through by another
  function while it is held.
- Test: `093-traps/126-write-reference-where-a-read-is-asked`

### 38. A field of a result borrowed in an ensures

- Error: `H6043` "The head of a reference transform expression must be of a
  reference type" for `ensures length(&(result.name)) = spanLength(name)`
- Wrong: `ensures length(&(result.name)) > 0;`, a path into the value result
- Right: an accessor of the module that takes `&result` and gives what the
  condition needs, `ensures nameLength(&result) = spanLength(name);`; one that
  gives a span through asSpan is refused in a contract (H3098), one that gives
  a length is taken
- Now: the message names the form with a reference and a function, as trap 16
  does; nothing else changed, since a contract reads its result as any
  expression reads a value.
- Test: `093-traps/124-field-of-a-linear-result-in-ensures`

### 39. A field of the result of a call

- Error: `H0005` "Error during parse." at the dot, with no hint
- Wrong: `nodeAt().kind`, `nth(xs, i).kind`
- Right: `let node: Node := nodeAt();` and then `node.kind`
- Now: `H0012` says that a field stands after a name and shows the binding
  to write first, as `H0010` does for an index.  Not removed: the grammar
  takes a path only from a name.
- Test: `093-traps/127-field-on-a-call`
