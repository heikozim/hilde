# Writing Hilde: a guide for models

This guide is written
for a model -- or a person -- about to write Hilde code with a compiler at
hand, and it keeps to one rule: **every programme here is in `examples/`
and the project's checks compile and run it, and every refusal named here is a test
in `test-programs/suites/` with its real message and code.**  Where this
text and the compiler disagree, the compiler is right and this text is the
defect.

## 1. What Hilde is

Hilde is a fork of Austral (`docs/austral-README.md`): a small language
with linear types, compiled to C.  A value of a Linear type is used exactly once; the type
checker, not the programmer's care, makes sure of it.  That is the one
idea everything else serves, and most compile errors a newcomer meets are
about it.

The differences from Austral a reader of Austral would trip over are in
`docs/differences-from-austral.md`.

## 2. Files and modules

A module is two files: the interface `Name.hih` and the body `Name.hiq`.

```
module Example.HelloWorld is
    """
    No contract: the exit code of the programme, the result of what it did.
    """
    function main(): ExitCode;
end module.
```

```
module body Example.HelloWorld is
    function main(): ExitCode is
        printLn("Hello, world!");
        return ExitSuccess();
    end;
end module body.
```

(`examples/hello-world/`.)  Imports stand before `module` or `module body`
and name what they bring in: `import Standard.String (String, length);`.
A module is compiled together with every module it imports, each as an
`interface,body` pair:

```
hilde compile standard/src/String.hih,standard/src/String.hiq \
    Main.hih,Main.hiq --entrypoint=Main:main --output=main
```

`run-examples.sh` shows the full list for a programme that prints; the
`cli.txt` beside each test shows it for the modules that test uses.

## 3. Reading a compile error

Every error has a code: `Error code: H4008` in the text output,
`"code": {"code": "H4008", ...}` with `--error-format=json`, which writes
rustc's form, and `"code": "H4008"` with `--error-format=hilde-json`.
`docs/error-codes.md` lists
every code with the file that raises it and how its message begins.  The
first digit says the kind: 0 parse, 1 command line, 2 declaration, 3 type,
4 linearity, 5 entrypoint, 6 generic, 7 `@template`, 8 SQL, 9 internal.

A parse error names the place, and for the causes met most often the
cause and the fix: a reserved word as a name (H0008, with a free name),
an operator after an operation without parentheses (H0009, with the
parentheses), an index after a call (H0010), a borrowed literal (H0011).
Any other is H0005, "Error during parse."; section 10 lists the
keywords, and `docs/hilde-traps.md` the traps behind the messages.

**Checking a module in a second.**  `hilde check X.hiq` parses, types and
checks a module -- contracts and linearity included -- with the modules it
imports, found in the standard library beside the compiler or in the
directories of `--modules=d:d`, and writes no C.  It reports the first
error as `hilde compile` does, in any of the error formats; on an aarch64 Linux host a
module of the standard library with eight imports took under a second.

**One form for every source.**  `hilde fmt <file or directory...>`
writes Hilde sources in their one form -- indentation by blocks, one rule
for the spaces between tokens, at most one blank line -- and keeps the
tokens, the comments and the line breaks; `hilde fmt --check` names the
files that are not in it and exits 1.

**In the editor.**  `hilde lsp` is a language server on standard input
and output: the first error of a document as a diagnostic while it is
written, and hover and go to definition on a name -- the declaration with
its type, its contract and its docstring.

**Asking the compiler instead of guessing.**  `hilde query <module...>
--module=Name` prints what a module declares as JSON -- every
declaration's kind, its types as the compiler resolved them, and the file
and line it is written on.  Over `examples/learn-linear` it
lists `main`, `Ticket`, `issue`, `use` and `peek`, and says of `peek`:
a private function with the type parameter `R` in the universe `Region`,
the parameter `ticket` of type `&[Ticket, R]`, returning `Nat32`, written
from line 21 of `LearnLinear.hiq`.  Give it the
same module list as `hilde compile`.

**Asking what a programme does in C.**  `hilde guard <module...>
[--entrypoint=Module:name]` lists the modules marked unsafe, the C
libraries and headers, every foreign function and every `@embed` with
whether the programme can reach it from the entrypoint, and the exported
functions.  Over `examples/learn-sqlite` it names the two
unsafe modules of the SQLite binding, the libraries `pthread` and
`sqlite3`, 24 foreign functions of which the programme reaches 19, and 18
embeds, all reached.  The same module list as
`hilde compile` again.

## 4. Linear values

`examples/learn-linear/`: a record declared `Linear` is created, looked at
through a read reference twice, and consumed once.

```
record Ticket: Linear is
    seat: Nat32;
end;
```

A function that takes it by value has to consume it, here by taking it apart:

```
function use(ticket: Ticket): Nat32 is
    let { seat: Nat32 } := ticket;
    return seat;
end;
```

The rules, each with the test that holds it:

| The compiler refuses | Code | Test |
|---|---|---|
| a linear variable still held at `return` | H4012 | `006-linearity/001-forget-variable` |
| a linear variable used after it was consumed | H4008 | `006-linearity/008-consume-twice` |
| consumed in one branch of an `if` and not the other | H4004 | `006-linearity/004-if-true` |
| consumed twice in one expression | H4005 | `006-linearity/012-consume-twice-in-expr` |
| consumed inside a loop | H4003 | `006-linearity/007-outside-for-loop` |
| a linear binding of a `case` left unconsumed | H4002 | `006-linearity/010-forget-case` |
| a new value assigned over one not yet consumed | H4010 | `006-linearity/013-no-assignment` |
| a Free record with a Linear field | H4001 | `003-record/002-free-record-has-linear` |

**Every branch must leave a linear value in the same state.**  An early
`return` inside an `if` without an `else` is the common way to break this:
write both branches, and consume or return in each.

A `String` owns memory and is Linear: every one ends in `destroyString`
or is handed on (`examples/learn-text/`).

## 5. References and regions

`examples/learn-borrow/`.

- `&x` is a read reference, `&![T, R]` in a signature a write reference;
  `R` is a region, declared with `generic [R: Region]`.
- A write reference can only be taken from a `var` (H3018,
  `015-mutability/003-cant-mutborrow-let`); assigning to a `let` is
  refused as well (H6042, `015-mutability/001-cant-assign-let`).
- A field is read and written through a reference with `->`:
  `counter->count := counter->count + 1;`.  A field of a record held in a
  field is reached with `.` after that: `listener->socket.number`.
- **A write reference passed to a function is used up.**  `&~counter`
  passes a new one and keeps `counter`; the last use can pass `counter`
  itself.  Because a write reference is linear, a function that takes one
  must use it the same way on every branch -- the simplest way is `&~` on
  every call.
- While something is borrowed it cannot be consumed (H4006, H4007,
  `046-sqlite/006-finish-in-row`, `031-arena/002-free-while-borrowed`),
  and a variable borrowed read-write cannot be borrowed again (H4011,
  `007-borrowing/012-cant-reborrow-twice`).

## 6. Failure: Option, Either, `?`

`examples/learn-errors/`.

- A function that can fail returns `Option[T]` (`Some(value => x)`,
  `None()`) or `Either[L, R]` (`Left(left => e)`, `Right(right => x)`),
  and the caller takes it apart with `case ... of when Some(value as x: T)
  do ... when None do ... end case;`.
- In a `return` from a function whose result type says it, `None()` can
  stand as it is (`027-question-operator/001-option-propagates`).  Where
  the compiler cannot see which `Option` or `Either` is meant, a typed
  `let` tells it: `let none: Option[Int32] := None();` -- the form the
  standard library uses throughout.
- **Throwing an `Option` or `Either` away is a compile error** (H3037,
  `026-result-discard/001-discard-option-refused`).  `ignore(f());` throws
  it away on purpose; `ignore` takes only Free values (H3004,
  `026-result-discard/007-ignore-refuses-linear`).
- `f()?` returns the failure from the enclosing function at once.  It may
  only stand as the whole right side of a `let` or as a whole statement
  (H3040, `027-question-operator/007-nested-in-expression-refused`), and
  the enclosing function must return the same kind of result (H3039).
  It keeps Hilde explicit: the return it stands for is written, as the
  character ?, at the place where it happens.

## 7. Text and printing

`examples/learn-text/`.  `print` and `printLn` take numbers, `Bool` and
string literals.  A `String` is printed as a span, `getSpan(text, 0,
length(text) - 1)` -- the last index is inclusive, so an empty string
must be checked first: `getSpan` on an empty string stops the programme
with "getSpan: start index out of bounds" and exit status 255.
`Standard.StringBuilder` builds a string; `finalize`
consumes the builder and hands out the `String`.

**A programme that stops like that lost what it printed before, when its
output went to a file**: two lines printed before the failing `getSpan`
do not reach the file, 0 bytes.  When a programme's last lines seem
missing, look at its error stream first.

## 8. Literals

- Integers: `12`, hexadecimal `#x1B0`, octal `#o660`, binary `#b11000`
  (`lib/Lexer.mll:87-90`; `test-programs/suites/002-constants/001-mixed`
  uses all three).  A file mode is written in octal: `#o600`.
- A character literal `'a'` is the integer 97: the parser turns it into an
  integer constant (`lib/Parser.mly:464`), so it is typed like any integer
  literal -- as the argument of a `Nat8` parameter it is a byte.
- Strings: `"..."`, with `\n`, `\r`, `\t`, `\\` and `\"`.  A string may
  end in a backslash: `"\\"` is one backslash, and the lexer reads an
  escaped backslash as a pair before it looks for an escaped quote
  (`read_string` in `lib/Lexer.mll`, test
  `test-programs/suites/005-fixed-string/003-backslash-before-quote`).
- Where a literal's type is not given by its place -- a parameter or a
  typed `let` gives it -- the compiler may choose `Int32`, and a mismatch
  follows.  A typed `let` fixes it: `let limit: Nat32 := 511;`.

## 9. Expressions and statements

- An operator takes two operands; a chain needs parentheses:
  `(n - ((n / 2) * 2)) = 0`.  A comparison is an operator too: the same
  line without the outer pair is a parse error, H0005
  (`examples/learn-errors`).
- `if ... then ... else if ... then ... else ... end if;`,
  `while ... do ... end while;`, `for i from 0 to n - 1 do ... end for;`
  -- `to` is inclusive.
- A statement that does nothing is `skip;`; a function without a result
  returns `nil` and has the type `Unit`.

## 10. Words that cannot be names

From `lib/Lexer.mll`: `and or not module is body
import as end constant type function generic record union case of when
typeclass instance method if then else let var while for do from to
borrow return skip Free Linear Type Region pragma sizeof nil true false
Span`, and the compile-time constructs `@embed @bytes @template @query
@execute @migrations`.  `body`, `type`, `from` and `to` are the ones most
often wanted as names.

## 11. The standard library

`standard/src/`; each `.hih` says in its opening text what the module is
for and what it leaves out, and that text is the reference.  In short:
`String`, `StringBuilder`, `Buffer`, `Text`, `Utf8` for text; `File` for
files, pipes, child processes and Unix domain sockets; `Poller` for
waiting on many descriptors (epoll or kqueue); `Task` for fibers and channels;
`Time`; `Path`; `Regex` (RE2 syntax, linear time); `Template` with
`@template`; `Sqlite` with `@query`, `@execute`, `@migrations`; `Sftp`;
`Libcrypto`; `Http`, `Fcgi`, `Ip` for the web side; `Sandbox`; `Arena`,
`Box`.  A Hilde programme serves the web by FastCGI over a Unix
domain socket behind Hiawatha: `Standard.Fcgi` and
`Standard.File.listenUnix` (`test-programs/suites/049-unix-socket/002-fastcgi`
for a whole request).

## 12. Unsafe code

C is reached three ways, and each needs `pragma Unsafe_Module;` in the
module: `@embed`, which pastes C (H2038,
`020-unsafe-module/001-embed-in-safe-module-rejected`);
`pragma Foreign_Import`, which declares a C function; and `Hilde.Memory`.
Application code does not do this -- a binding in `bindings/` and a safe
module in `standard/` above it do (section A: "bindings at the bottom, a
safe abstraction above them").

*Sections 13 to 17 cover unions and patterns, generics and type classes,
tasks, the compile-time constructs, contracts and effects.  The rule is
the same as above: a programme shown here is an excerpt, line for line, of
a file in `examples/` or of a test, and every refusal named has the code
and the test that holds it.  `scripts/check-learning-doc.py` holds the
text to that, from section 1 to the last.*

## 13. Unions, `case` and patterns

`examples/learn-match/`.  A union is a type of several shapes; each `case`
names one, with its slots.  A value is made by naming the shape and its
slots, `Press(key => Char(code => code), shift => shift)`, and a shape
without slots is made with empty parentheses, `Enter()`.

```
union Key: Free is
    case Char is
        code: Nat8;
    case Enter;
    case Escape;
end;
```

A `case` takes a value apart with patterns that go as deep as the value
does:

```
case event of
    when Press(Char(97 .. 122), false) do
        printLn("a small letter");
    when Press(Char(97 .. 122), true) | Press(Char(65 .. 90), _) do
        printLn("a capital letter");
    when Press(Char(48 .. 57), _) do
        printLn("a digit");
```

A range `97 .. 122` takes both ends.  A bar `|` joins patterns that have
one answer.  `_` takes any value without a name, and a name takes it and
binds it.  The first pattern that fits is taken.

| The compiler refuses | Code | Test (in `056-pattern-matching/`) |
|---|---|---|
| a case that leaves a value out, at any depth, and literals alone | H3075 | `101-missing-variant-level-1`, `105-literals-alone-not-complete` |
| a pattern that no value can reach, because the ones before it take every value it takes | H3074 | `120-unreachable-same-when`, `122-unreachable-after-general` |
| a bar whose alternatives bind different names | H3084 | `130-bar-variable-in-one-only` |
| a name bound twice in one pattern | H3086 | `133-variable-twice` |
| a range whose low end is above its high end | H3079 | `152-reversed-range` |
| `_` where the value is Linear, which would drop it | H3082 | `140-wild-on-linear-slot` |
| a variant the union does not have | H3088 | `161-unknown-variant` |
| the wrong number of sub-patterns | H3083 | `162-too-few-sub-patterns`, `163-too-many-sub-patterns` |
| a linear binding of a pattern left unconsumed, or consumed twice | H4012, H4008 | `170-linear-binding-not-consumed`, `171-linear-binding-consumed-twice` |
| a linear value used after a pattern case took it apart | H4008 | `173-scrutinee-used-after-case` |
| a Free union with a Linear slot | H4001 | `004-union/002-free-union-has-linear` |

## 14. Generics and type classes

`examples/learn-typeclass/`, `examples/generic-union/`.  A type parameter
stands in square brackets with its universe, `Pair[T: Free]`; the
universes are `Free`, `Linear`, `Type` (a parameter that takes both:
`Standard.Box` is `Box[T: Type]`, `standard/src/Box.hih`) and `Region`
(section 5).  A union is generic the same way:

```
union Optional2[T: Type]: Type is
    case None2;
    case Some2 is
        value: T;
end;
```

A type class names what a type can do, and an instance says how one type
does it.  A generic instance gives a type built from others the same
ability, from the instances of its parts, and a generic function asks for
the ability in the universe of its parameter, `T: Free(Shape)`:

```
typeclass Shape(T: Free) is
    method area(shape: T): Nat32;
    method name(shape: T): Span[Nat8, Static];
end;

instance Shape(Square) is
    method area(shape: Square): Nat32 is
        return shape.side * shape.side;
    end;

    method name(shape: Square): Span[Nat8, Static] is
        return "square";
    end;
end;
```

```
generic [U: Free(Shape)]
instance Shape(Pair[U]) is
    method area(shape: Pair[U]): Nat32 is
        return area(shape.first) + area(shape.second);
    end;
```

```
generic [T: Free(Shape)]
function report(shape: T): Unit is
    print(name(shape));
    print(": ");
    printLn(area(shape));
    return nil;
end;
```

The compiler picks the instance from the type of the argument, so
`report(square)` and `report(Pair(first => square, second => Square(side
=> four)))` need no more than the call.  What is refused:

| The compiler refuses | Code | Test (in `008-typeclasses/`) |
|---|---|---|
| a type without an instance where the type class is asked for | H3061 | `020-unsatisfied-constraint` |
| a type parameter used as a type class asks, without the constraint | H3056 | `011-unconstrained-typaram` |
| two instances that overlap, in one module or in two | H6038 | `021-duplicate-instance-int32`, `023-duplicate-instance-two-modules` |
| an instance of a foreign type class for a foreign type | H6032 | `013-orphan-instance` |
| an instance for a built-in type, which belongs to the language | H6037 | `025-instance-for-builtin-nat8` |
| an instance for an argument in the wrong universe | H3007 | `003-expect-linear`, `004-expect-free` |
| a type class parameter in the `Region` universe | H2023 | `002-region-param` |
| the use of a private instance of another module | H3050 | `016-private-instance` |

## 15. Tasks

`examples/learn-tasks/`.  A task is started in a scope with `spawn`, which
gives back the task or, when none could be started, the argument; `join`
waits for it and hands back its result.  A scope ends only when every task
in it has ended, and `closeScope` is what ends it.

```
case spawn(scope, sumSquares, Range(first => first, last => last)) of
    when Right(right as task: Task[Nat64]) do
        let started: Option[Task[Nat64]] := Some(value => task);
        return started;
    when Left(left as back: Range) do
```

A task shares nothing: its argument is copied in and its result is handed
back by `join`.  `Standard.TaskArena` gives a task an arena of its own,
which goes back with the result (`spawnWithArena`).  The example joins its
four tasks in a fixed order, so its output is the same on every run
although the tasks end in any order.  What is refused:

| The compiler refuses | Code | Test (in `041-task/`) |
|---|---|---|
| a task that is not joined | H4002 | `007-unjoined-task-rejected` |
| a channel end that is not closed | H4002 | `009-unclosed-sender-rejected` |
| a lending scope that is not closed | H4002 | `017-lending-scope-not-closed-refused` |
| the argument used after it was moved into a task | H4008 | `008-argument-used-after-spawn-rejected` |
| an argument that holds a reference or a span, alone, in a record, or through a generic | H3002 | `010-reference-argument-rejected`, `011-reference-inside-record-rejected`, `012-reference-through-generic-rejected` |
| the same for a task with an arena | H3002 | `029-task-arena-reference-refused` |

Where a task has to read a value that the caller owns, a lending scope
does it for the length of a borrow (`014-lending-scope-reads`).
A task costs 64 KiB of address space and one page of memory once it runs.

## 16. Constructs that begin with an at sign

Each is read by the compiler, and a mistake in it is a compile error.

**`@bytes` and `@embed`** (`examples/learn-embed/`).  `@bytes("motto.txt")`
puts the bytes of a file beside the module into the programme, as a span
of `Static`; the file is not needed when the programme runs.  A path that
leaves the module's directory, or no file, is refused (H6001, H6002;
`034-embed-file/003-parent-path-refused`, `005-missing-file-refused`).
`@embed` pastes C and needs `pragma Unsafe_Module;` (section 12).

```
let motto: Span[Nat8, Static] := @bytes("motto.txt");
```

**`@template`** (`examples/learn-template/`).  A template in the syntax of
Jinja2, `order.jinja`, is filled from a record, and the compiler turns it
into code.

```
@template("order.jinja", order, out);
```

A name the record does not have, or a filter that does not exist, is a
compile error, not a surprise at run time:

| The compiler refuses | Code | Test (in `045-template/`) |
|---|---|---|
| a name the record has no slot for | H3049 | `002-unknown-name` |
| a filter that is not supported | H7076 | `014-unknown-filter` |
| a path that leaves the module's own directory | H7003 | `010-parent-path` |
| a value in a place where no escaping makes it safe | H7067 | `006-script` |

**`@migrations`, `@execute`, `@query`** (`examples/learn-sqlite/`).  The
files under `migrations` build the schema, and the compiler checks every
statement against it.  Values go to the database as parameters, never into
the text.

```
report("insert", @execute(&~db, "INSERT INTO notes (content) VALUES (?)", "buy bread"));
```

| The compiler refuses | Code | Test (in `046-sqlite/`) |
|---|---|---|
| a table that the migrations do not build | H8027 | `007-no-table` |
| a column that no table of the query has | H8033 | `008-no-column` |
| a comparison of text with an integer | H8041 | `009-text-with-integer` |
| a table that is not STRICT | H8090 | `013-not-strict` |
| a gap in the numbers of the migrations | H8107 | `021-migration-gap` |

## 17. Contracts and effects

`examples/learn-contracts/`, `examples/learn-records/`.  A contract stands
after the return type of a function, and the contract of a public function
stands in the interface, `.hih`, next to the function.  `requires` says
what must hold when it is called, `ensures` what holds when it returns, and
`old(...)` names a value as it was at the call.  Hilde checks them while the
programme runs, and a broken one stops the programme and says which
contract, where it is written and where the call was made
(`examples/learn-contracts/` has a programme that does).

```
generic [R: Region]
function withdraw(account: &![Account, R], amount: Nat64): Unit
    requires (amount > 0) and (amount <= balance(&account))
    ensures balance(&account) = (old(balance(&account)) - amount);
```

A record can carry an invariant, checked whenever a value leaves its
module (`examples/learn-records/`):

```
record Interval: Linear is
    low: Nat32;
    high: Nat32;
    invariant low <= high;
end;
```

| The compiler refuses | Code | Test (in `067-contracts/`) |
|---|---|---|
| a contract in the body of a public function as well as in the interface | H2051 | `101-repeated-in-body` |
| a contract on a function that is imported from C | H2052 | `103-foreign-function` |
| a condition that consumes a linear value | H3096 | `109-condition-consumes` |
| a condition that calls a function that does more than read (here one that asks the system for a limit) | H3098 | `111-condition-binding-module` |
| a `requires` on the entrypoint | H5008 | `117-entrypoint-requires` |
| an invariant on a record whose slots are reachable outside its module | H2057 | `204-invariant-public-record` |

`hilde test --contracts` draws inputs from the contracts and prints its
seed, and a simple `ensures` is proved when the programme is compiled, which
leaves its check out (suite `067-contracts`).

**Effects.**  A function names the error kinds it can end with after its
return type, `raises NotFound`, and `raise NotFound;` ends the programme
with that kind (`069-effects/001-raise-within-clause`).  The clause stands
in the interface as well (`007-clause-in-interface`).  A panic -- `abort`,
a broken contract, a trapped overflow -- carries no kind and needs no
clause (`006-panics-need-no-clause`).

```
function pick(n: Int32): Int32
    raises NotFound is
    if n < 0 then
        raise NotFound;
    end if;
    return n;
end;
```

| The compiler refuses | Code | Test (in `069-effects/`) |
|---|---|---|
| a `raise` in a function with no clause, or of a kind it does not name | H3102 | `101-raise-without-clause`, `102-raise-not-named` |
| a call that can end with a kind the caller's clause does not name | H3103 | `103-call-exceeds-no-clause`, `104-call-exceeds-partial` |
| a function with a clause taken as a function pointer | H3104 | `107-pointer-to-raises` |
