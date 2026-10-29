# Differences from Austral

Hilde is a fork of Austral. This file lists the places where the language
Hilde accepts differs from the language Austral accepts, so that a reader
who knows Austral does not have to find them by being surprised.

Each entry gives the rule in one sentence, why it is there in one
sentence, and a test program that holds the rule in place. Where a
difference is a defect Austral also has, that is said; the defects are
listed together at the end.

## Negation is its own operation, and an instance always wins

**The rule.** `-x` is `trappingNegate(x)`, a method of the typeclass
`TrappingNegation` in `Hilde.Pervasive`, and the type checker asks the
resolver for an instance before it decides anything itself; only where
no instance exists does the type rule speak, with its own message for the
unsigned types, its own message for Float32, and otherwise the plain
statement that the type does not implement the class.

**Why.** In Austral `-x` is parsed as `0 - x`, the zero is an Int32
constant and the arithmetic rule casts both operands to the type of the
left one, so of the twelve numeric types `-x` compiled for exactly one,
Int32, and by accident; making it an operation of its own means it means
the same thing at every width, and asking the resolver first means an
instance a user declares is actually consulted instead of being accepted
and ignored.

**Tests.** `test-programs/suites/019-negation/` -- 001 to 010 are the
built-in signed types at their limits, 011 to 017 the types that have no
negation, 018 a user type whose own instance is called, 019 and 020 the
class message.

## An instance may not overlap an instance in another module

**The rule.** A type may have at most one instance of a typeclass in a
program, whichever module declares it; the check runs against every
instance of the class in the program, and the error names the module of
the existing instance and of the new one.

**Why.** Austral checks uniqueness only against the instances of the
module being compiled, so a second instance for a type that already had
one elsewhere went through, while method resolution treats more than one
matching instance as an internal error -- an assumption nothing enforced.

**Tests.** `test-programs/suites/008-typeclasses/021-duplicate-instance-int32`
and `022-duplicate-instance-int8` for a duplicate of a Pervasive
instance, `023-duplicate-instance-two-modules` for the cross-module case
that no per-module check can see, `024-single-instance-compiles` as the
control.

## A built-in type is foreign outside the built-in modules

**The rule.** For the orphan rules a built-in type -- Unit, Bool, the ten
integer types, Float32, Float64 -- counts as local only in
`Hilde.Pervasive` and `Hilde.Memory`, two of the modules the compiler
injects (the third, `Hilde.Array`, declares no instance). The four
orphan cases are unchanged; case 4 with a built-in type has its own
message, which says the type belongs to the language and that the way out
is a type of your own.

**Why.** In Austral a built-in type is local in every module, so the
fourth case could never arise for one and any module could give any
built-in type an instance of any foreign typeclass; the instance was then
never consulted, because the negation type rule decided on the operand
type before the class was resolved.

**Tests.** `test-programs/suites/008-typeclasses/025-instance-for-builtin-nat8`
and `026-instance-for-builtin-float32` for the rejection,
`027-local-class-builtin-type` as the control for orphan case 2, and
`015-foreign-tc-local-type` and `024-single-instance-compiles` for case 3.

## `@embed` needs a module that says so

**The rule.** `@embed` is allowed only in a module that carries
`pragma Unsafe_Module;`.  The module kind reaches the type checking of
the expression through the environment, and the message carries the span
of the `@embed` itself, so it names file, line and columns even where the
`@embed` stands outside any statement.

**Why.** `@embed` pastes C into the generated program and the compiler
does not check that C.  Austral marks unsafe modules and enforces the
mark in two places -- an import from `Austral.Memory` and a foreign
function -- and `@embed` is in neither, so a safe module could paste
arbitrary C, a `static` variable among it, and hold mutable state that
the language itself does not have.

**What it costs, and what it does not.** `Hilde.Pervasive` and
`Hilde.Memory` carry the pragma themselves: they hold nearly all of the
embedded C of the compiler, they are compiled through the same pipeline
as any other module, and their kind comes from their own pragmas like
everyone else's.  **The compiler knows no exception**: there is no list
of module names in it, and the rule that holds for a user module holds
for the prelude.  The mark does not travel either -- every module imports
`Hilde.Pervasive` implicitly and stays safe, which test 004 holds.  One
test taken over from Austral differs because of this:
`test-programs/suites/001-trivial/005-hello-world` uses `@embed` in a safe
module and now carries the pragma.

**Tests.** `test-programs/suites/020-unsafe-module/` -- 001 the refusal,
002 the same program with the pragma (the exit code is the assertion),
003 the C-state case, 004 an ordinary module with no pragma at all as the
control, and 005 an `@embed` in a module-level constant, the case that
has no enclosing statement and therefore no statement span.

## The standard library's unit tests mark a pass with `ok`

Not a difference of the language; it is listed because it changes the
output of a module taken over from Austral.

**The rule.** `standard/src/Testing.hiq` (`Standard.Testing`, in Austral
`Standard.Test.Unit`) closes the line of an assert that passed with
` ok`, where Austral prints U+2713 (a check mark).

**Why.** Every file of the repository is plain ASCII, and the output of
the tests is compared byte for byte; the check mark put a non-ASCII
character into every test log.

**Tests.** The checks count the lines of the test log that close with
` ok` beside the lines that start an assert; the two counts are equal in
a run where every assert passed.

## A `case` takes patterns

**The rule.** A `when` may give one or more patterns separated by `|`:
variants with positional sub-patterns, variables, `_`, integer and Bool
literals and ranges `a .. b`, looking through `Standard.Box`; a `case`
with patterns decides on a union, an integer or a Bool, has no catch-all
over a union, and is refused when it leaves a value out or has a pattern
that can never be chosen.  A `case` whose every `when` is the old
form -- a variant with named, typed bindings, or a bare variant name -- is
compiled exactly as before.

**Why.** A `case` says in its patterns what it decides, and the compiler
holds it to every value it can meet.

**What Austral accepts and Hilde does not.** A bare `when x do` whose name
begins with a lower-case letter is a variable in Hilde, not a variant; over
a union it is a catch-all and refused (H3073).  The old form with
bindings, `when x(a: T) do`, is unchanged.

**Tests.** `test-programs/suites/056-pattern-matching/`, 12 programmes
that run and 85 refusals, one error each.

## A read borrow of a write reference reads what it points to

**The rule.** When `w` has the type `&![T, R]`, `&w` -- and the borrow
statement `borrow r: &[T, rho] := &w do ... end borrow;` -- is a read
reference `&[T, rho]` to the value `w` points to, for the statement or the
block; `w` is borrowed for as long, so it can be neither handed on nor
reborrowed while the read reference lives.  In Austral `&w` is a read
reference to the variable `w` itself, `&[&![T, R], rho]`, a type no
function of the standard library names.  A path's head is still borrowed
as the variable itself (`w->f` reads a free field as before).

**Why.** A function that holds a value through a write reference had to
read it through a second set of functions (`lengthMut`, `sizeMut`) or
through `@embed`; now it passes `&w` to the reading function.

**Tests.** `test-programs/suites/057-write-reference-reads/` 001, 003 and
004 run; 101 to 103 and 107 to 108 are refused.

## `&(path)` is a read reference, `&!(path)` a write reference

**The rule.** `&(p->f)`, `&(p->f->g)` and `&(p->s[i])` are read
references to the part the path names, whatever kind of reference `p` is;
`&!(p->f)` is a write reference to it and needs `p` to be a write
reference (H3093).  Both have the region of `p`, so a write reference `p`
is used up by either, as by the cast `(p : &[T, R])`.  In Austral
`&(path)` had the kind of the head's reference, and `&!(` was not syntax.

**Why.** The kind of reference is written where it is taken, as `&x` and
`&!x` already say it for a variable, and a read reference to a part of a
value held for writing is one expression.

**Tests.** `test-programs/suites/057-write-reference-reads/` 002 runs; 104
to 106 and 111 are refused.

## The name of a write borrow can be written through

**The rule.** In `borrow r: &![T, R] := &!x do ... end borrow;` an
assignment `r->slot := v;` changes the slot, as it does through a
parameter that holds a write reference.  In Austral it is refused with
the error of an immutable variable borrowed mutably (H3018 here), because
the borrow statement binds `r` as an immutable local (Austral's
`lib/TypingPass.ml`); only handing `r` to a function wrote through it.
Every other immutable local is still refused, and an assignment still
writes a Free value only (H4014).

**Why.** The name of a write borrow is a write reference, and the
assignment writes through it, not into the variable.

**Tests.** `test-programs/suites/057-write-reference-reads/` 005 runs; 112
and 113 are refused.

## A write reference can be bound to a name

**The rule.** `let w: &![T, R] := r;` and `var w: &![T, R] := r;` bind a
write reference to a name of its own; the reference is moved, as when it
is passed on.  In Austral both are refused with H3028, "Write references
can only be casted to a read reference": a declaration casts its value to
the type it names (`AbstractionPass.let_reshape`), and the cast of a write
reference allowed only a read reference as its target (Austral's
`lib/TypeCheckExpr.ml`).

**Why.** A cast of a write reference to its own type converts nothing,
and without it a write reference could not be held in a variable at all.

**Tests.** `test-programs/suites/057-write-reference-reads/` 006 runs; 114
is refused.

## The heap array is built into the compiler; Buffer and Box are safe

**The rule.** A third built-in module, `Hilde.Array`, is compiled into
the compiler after `Hilde.Pervasive` and `Hilde.Memory`: a linear type
`Array[T]` and its operations, each of which checks its index or its span
and stops the programme with a message naming the operation.
`Standard.Buffer` and `Standard.Box` are records around one array and are
safe modules: no `pragma Unsafe_Module`, no import from `Hilde.Memory`, no
`@embed`.  In Austral both are unsafe modules that do their own pointer
work.  Their interfaces are the same; a programme that stops on an index
out of range now says so in the words of `Hilde.Array`
("Hilde.Array.arrayNth: index out of range").

**Why.** A standard library that asks programmes to be safe should be safe
itself; the pointer work is checked once, in the compiler, and not in
every module that needs a growing array.

**Tests.** `test-programs/suites/058-built-in-array/` 001 to 003 run; 101
to 113 stop with their check's message; 114 and 115 are refused.

## C is bound in `Bindings` modules, and only the standard library imports them

**The rule.** The work with addresses and C calls of a standard module
lives in an unsafe module `Bindings.<Name>` under `standard/src/Bindings/`,
on top of the declarations `scripts/gen-bindings.py` writes as
`Bindings.C.<Library>`; the module a programme imports, `Standard.<Name>`,
is safe and keeps its interface.  A module whose name begins neither with
`Standard.` nor with `Bindings.` may not import from a `Bindings.` module
(H2045).  In Austral the standard modules that call C are unsafe
themselves, and any module may import them.

**Why.** Some of what makes a binding safe to call is checked at the safe
module in front of it -- what a task is handed at the calls of
`Standard.Task`, the connection mode of `Standard.Sqlite` -- so a
programme that reached the binding would pass by those checks.  The rule
goes by name: a module that calls itself `Standard.` takes on what the
standard library promises.

**Tests.** `test-programs/suites/059-bindings-import/` 001 runs; 101 and
102 are refused.

## `hilde test` runs the tests of test files

**The rule.** A test file is a module body whose file name ends in
`.test.hiq`, beside the module it tests; every function of it whose name
is `test` followed by a capital letter or a digit is a test, of the form
`function testName(): Unit`, or with the root capability lent to it.
`hilde test <path...>` finds the test files and the modules they import,
builds one programme per test file and runs each test in a process of its
own; `--race`, `--memory` and `--valgrind` build and run them under
ThreadSanitizer, AddressSanitizer with UndefinedBehaviorSanitizer, or
valgrind, and a system that cannot is refused (H1021).  Austral has no
test command: its standard library's tests are one programme whose suites
call the tests one after another, and the first that fails ends all of
them.

**Why.** A test that stops the programme ended every test after it, and a
test the suite forgot never ran: Austral's suites never called the test
of the sextuple in `Standard.Tuples`.

## Every test also runs under the sanitizers, valgrind and cppcheck

**The rule.** The project's checks run every end-to-end test and the
standard library's tests once under AddressSanitizer with
UndefinedBehaviorSanitizer and once under valgrind, and cppcheck over the
generated C, each after controls it must fail (`scripts/check-runtime.sh`).
A test an instrument cannot hold is named with its reason and printed NOT
RUN; where a system cannot run an instrument, the checks say so.  The
end-to-end runner takes a wrapper for the programmes, another directory
of suites and a list of tests not to run, each from the environment.
Austral's tests run without an instrument.

**Why.** The instruments found three faults in the runtime that no plain
run could show: a programme naming a header that brings `<stdio.h>` did
not build with `-O1`, and the task switch was told neither to
AddressSanitizer nor to valgrind.

**Tests.** The fixtures of `test-programs/hilde-test/` and
`scripts/check-hilde-test.sh`; the standard library's test files, which
the checks run through `hilde test`.

## Defects Austral has as well

Eighteen defects of Austral were met while Hilde was built, and each is
fixed in Hilde.  None of them has been reported to Austral, whose
repository has been inactive since 2023; each entry carries what is
needed to reproduce it and the fix.  The places named are those of the
Austral source Hilde is forked from.

1. **Uniqueness of instances per module only**, in `lib/TypeClasses.ml`:
   the entry "An instance may not overlap an instance in another module"
   above.
2. **A built-in type counts as local everywhere**, in `lib/TypeClasses.ml`:
   the entry "A built-in type is foreign outside the built-in modules".
3. **`-x` as `0 - x`**, in `lib/Parser.mly`: the entry "Negation is its
   own operation".
4. **`@embed` in a safe module**: Austral judges the module kind in
   `lib/ImportResolution.ml` and `lib/TypingPass.ml` and nowhere else, the
   module kind never reaches `lib/TypeCheckExpr.ml`, and Austral's own
   hello-world test uses `@embed` on three lines with no pragma.  The
   entry "`@embed` needs a module that says so".
5. **`bump` of the Buffer module copies from freed memory.**  It copies
   with `memcpy` from `buf->array` after `resizeArray` -- realloc -- has
   already carried the contents over to the new block and freed that one.
   Hilde removed the copy.  No language difference.
6. **The return-type polymorphism check sees the caller's type variables.**
   `handle_return_type_polymorphism` receives the return type after the
   argument bindings are put in and hands it to
   `is_return_type_polymorphic`, which compares type variables by NAME with
   the callee's parameters.  A call of `wrap[T](x: T): Option[T]` on a
   `Holder[A]` inside a function generic in A is refused as "`wrap` is
   generic but unconstrained" wherever there is no asserted type -- a case
   scrutinee, an argument.  Five call sites in `lib/TypeCheckExpr.ml` pass
   the return type that way.
7. **`replace_variables` asks a monomorph for its universe.**  For a named
   type in the `Type` universe it recomputes the universe from the
   arguments; during monomorphisation an argument can be a `MonoTy`, and
   `type_universe` refuses one with an internal error.  `Option[T]` in a
   generic body instantiated with a named type is enough.  In
   `lib/TypeBindings.ml` and `lib/TypeSystem.ml`.

   Suite `test-programs/suites/042-generic-bindings` carries one test for
   six and seven, and each fails with Austral's message when its fix is
   taken out.
8. **A generic function cannot call itself.**  When a parameter of type
   `T` is matched against an argument whose type is the SAME type variable
   -- same name, same universe, same provenance -- Austral returns no
   binding at all, with the comment "we don't want circular bindings".  In
   a recursive call that is exactly what happens: the function passes its
   own `T` back as `T`, the parameter stays unbound, and the call is
   refused with "No binding for this parameter".  Over a region parameter
   it refuses every recursive walk that is lent a buffer.  The same gap
   had a second effect that is worse than a refusal: a call that bound `T`
   to itself through one argument and to `Index` through another kept only
   the second binding and was ACCEPTED, so a value of type `T` went where
   an `Index` was expected.  In `lib/TypeMatch.ml`.

   Suite `042-generic-bindings` tests 003 and 004 show the two refused
   recursions compiling and running, test 005 shows the conflicting call
   refused; with Austral's line put back, 003 and 004 fail with "No
   binding for this parameter" and 005 compiles.
9. **A binding of a case over a read reference counts as linear.**  The
   type checker records each binding of a `case` with the PAYLOAD type --
   the code generator wants that one and makes a pointer of it itself --
   and the linearity check enters that type in its table.  For a case over
   `&[Option[T], R]` or over a reference to a union with a linear payload,
   a binding the branch does not use is refused: "The variable ... is not
   consumed".  A read reference is Free; there is nothing to consume.
   `lib/TypingPass.ml` records the type, `lib/LinearityCheck.ml` uses it.
   Fixed in the linearity check alone, for READ references only; a case
   over a write reference is unchanged.

   Test `006-linearity/020-case-on-read-reference` compiles and runs; with
   Austral's linearity check it is refused with that message.
10. **A type error in a condition, a scrutinee, an assigned value or a
    loop bound is reported at the wrong place.**  The lifting pass computes
    those values into a temporary before the statement, in a block with the
    empty span, and the type checker gives a block no span of its own; an
    error there takes the span of the nearest statement around it that has
    one -- the statement BEFORE, or none at all.  `case f(y) of` with `y`
    of the wrong type was reported at the `let` in the line above.  In
    `lib/LiftControlPass.ml` and `lib/TypingPass.ml`.  Fixed: the blocks
    carry the span of their statement, and a block puts its span on an
    error inside it that has none.

    Test `046-sqlite/014-write-through-reader` has its error at the `case`
    in line 27; with Austral's lines put back, at no place.
11. **A type imported under a nickname does not match itself.**
    `import M (T as U)` and then `let x: U := f()` with `f` returning
    `T` is refused with H3027, "Cannot cast to U from T": the type
    matcher compares two named types with `=` over the whole qualified
    identifier, and that carries the LOCAL name.  `equal_ty` in
    `lib/Type.ml` already compares module and original name only
    (`equal_qident`).  Fixed: `lib/TypeMatch.ml` uses `equal_qident` as
    well.

    Test `009-names/007-type-nickname` (`String as Text`) compiles and
    runs; with Austral's matcher it is refused with H3027.

Twelve and thirteen sit in the same call, where the monomorphizer resolves
a method called through a type variable -- a generic function with a
typeclass constraint:

12. **The call cannot dispatch on a named type.**  By the time the
    instance is looked up, the type variable has been replaced by the
    monomorphized argument, and for a record or a union that is `MonoTy
    id`.  `get_instance` hands it to `match_type`, which refuses a MonoTy,
    and the refusal is caught as "does not match": H6021 "Typeclass
    resolution failed".  Only the built-in types could be dispatched on --
    `Order.equal` on two `Nat8` worked, on two Strings it did not.  In
    `lib/Monomorphize.ml` and `lib/TypeMatch.ml`.  Fixed: `unmono_type`
    turns the MonoTy back into the named type it stands for before the
    lookup.
13. **The call looks only among the instances the GENERIC function's
    module sees.**  An instance for a type of the caller's own, in a
    module the generic function's module does not import, is not found --
    the same H6021.  The call site has already checked the constraint with
    its own visible instances, and instances are unique across the
    program, so the monomorphizer now searches all of them
    (`get_instance_anywhere`).  In `lib/TypeMatch.ml`.

    Test `053-sort/001-words-and-records` sorts Strings (twelve) and a
    record of the test module's own whose instance `Standard.Sort` does
    not import (thirteen); with Austral's lookup it stops with H6021, and with only thirteen put back it still does, the
    message naming the record.

Fourteen and fifteen are one defect in two places of `monomorphize_ty`: a
region has no run-time representation, yet it was part of the key a
monomorph is looked up by, so one type became two C structs -- the
borrow's own region at the call site, `Static` inside the generic function
(whose region parameters all become `Static`).  The type checker accepts
the programme and the C compiler refuses the output: "incompatible types"
or "incompatible pointer type".  Hilde erases the region to `Static` in
the key.

14. **The region of a reference or a span.**  `Option[&![T, R]]` returned
    by a generic function.  In `lib/Monomorphize.ml`, the four cases
    `SReadRef`, `SWriteRef`, `SSpan`, `SSpanMut`, each monomorphizing its
    region.  The tests are those of the arena.
15. **A region that stands as a type argument.**  `Lending[R]`, a record
    generic in a region only, returned by the generic `openLending` and
    held in a concrete `main`.  In `lib/Monomorphize.ml`, `SRegionTy r ->
    MonoRegionTy r`.  Tests `041-task/014` and `043-regex/008` (whose
    `Job[R]` is the same shape); with Austral's line put back, both fail
    in the C compiler.

Sixteen and seventeen concern what a reference may be:

16. **A function's own type parameters could be bound by its body.**  The
    check of a `return`, of a `let` with a type, and of an assignment
    matches the value's type against the written type with `match_type`,
    which binds a type variable to whatever stands opposite -- right for a
    call, where the variables are the callee's, and wrong here.  So
    `generic [R: Region] function f(n: Int32): &[Int32, R] is let x: Int32
    := n; return &x; end;` compiled: R was bound to the borrow's own region
    and a reference to a local variable left the function; and `return
    n` compiled as the type parameter `T`.  In `lib/TypingPass.ml`, `let _
    = match_type_with_value ... rt e'`, the bindings thrown away.  Fixed in
    Hilde: a binding of one of the function's own parameters to anything
    but itself is refused, H3094 for a region and H3095 for a type.  Tests
    `057/108`, `057/109`, `057/110`.
17. **An element of a span reached through a reference.**  Through a
    write reference to a read span, `Span[T, R]`, an element came out as
    a WRITE reference into data the span may only read; and through any
    reference the element had the reference's region, not the span's.  In
    `lib/TypeCheckExpr.ml`, `augment_array_index`, whose `WriteRef` case
    ends in `WriteRef (elem_ty, reg)` for a span of either kind.  Fixed in
    Hilde: an element of a read span is a read reference with the span's
    region; an element of a write span is a write reference only through
    a write reference, with that reference's region.  Tests `057/111`
    (refused) and `016-spans/007` (runs: its element reference is declared
    with the span's region).
18. **A function pointer took its parameter types in reverse order.**
    `Fn[A, B, R]` is parsed into the parameter types and the result type
    with `Util.butlast`, which reversed the list it returns: the type
    meant a function of a `B` and an `A`.  `Fn[Int32, Int32, Int32]`
    does not show it; `Fn[Int32, Bool, Int64]` refused `f(1, true)` with
    H3060 and took `f(true, 1)`.  In `lib/Util.ml`, `butlast`, whose
    `rest` is the reversed list, and `lib/TypeParser.ml`, its one caller.
    Fixed in Hilde: `butlast` turns the rest back.  Test
    `010-functions/011`.
