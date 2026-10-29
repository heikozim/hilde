# Hilde syntax

This page describes the syntax of Hilde as the compiler in this repository
reads it. The lexer, `lib/Lexer.mll`, and the parser, `lib/Parser.mly`, are
the reference. Hilde is a fork of Austral; where Hilde's syntax differs from
Austral's, a paragraph says so.

Every section except the last has examples, and every code block is a
complete module. A block that opens with ```` ```hilde ```` compiles, together
with the other modules of its example, into a program that runs. A block that
opens with ```` ```hilde fails H4012 ```` shows a rule by breaking it: the
compiler refuses it with exactly that error code.

## 1. Comments and literals

**Comments.** Two hyphens, `--`, start a comment. It runs to the end of the
line. There are no block comments.

**Whitespace.** Spaces, tabs and line ends separate tokens. A line ends with
LF or CR LF. Any other character outside a comment or a string is an error.

**Identifiers.** An identifier starts with a letter and goes on with letters,
digits and underscores: `count`, `Max_Size`, `x2`. Case matters. A single `_`
is not an identifier; it is the wildcard of a pattern (section 11).

**Reserved words.** These words cannot be identifiers: `and`, `as`, `body`,
`borrow`, `case`, `constant`, `do`, `else`, `end`, `ensures`, `false`, `for`,
`from`, `function`, `generic`, `if`, `import`, `instance`, `invariant`, `is`,
`let`, `method`, `module`, `nil`, `not`, `of`, `or`, `pragma`, `raise`,
`raises`, `record`, `requires`, `return`, `sizeof`, `skip`, `then`, `to`,
`true`, `type`, `typeclass`, `union`, `var`, `when`, `while`, and the type
words `Free`, `Linear`, `Region`, `Type` and `Span`.

**Integer literals.** Decimal: `42`, `-42`. Hexadecimal: `#xF0`. Binary:
`#b1010`. Octal: `#o755`. An apostrophe may separate digits: `1'000'000`,
`#b0000'1010`. The sign belongs to a decimal literal, so `-1` is one token.
Write a space after a minus that subtracts: `n - 1`, not `n -1`. Hexadecimal,
binary and octal literals have no sign. An integer literal takes the type that
its place asks for: the declared type of a `let`, the type of the variable or
path it is assigned to, the type of the other operand of an operator (`55 + i`
with `i` an `Index` is an `Index`), the type a parameter of a generic function
gets from the other arguments or from the type the call is to have. Where no
type is asked for, as in the branches of an `if` expression, it is an `Int32`.

**Character literals.** A letter, a digit, a space or a printable ASCII
punctuation character between single quotes: `'A'`, `'?'`. The escapes are
`'\n'`, `'\r'`, `'\t'`, `'\\'` and `'\''`; `'''` is the apostrophe as well. A character literal is an integer literal
whose value is the ASCII code of the character. It is usually given the type
`Nat8`.

**Float literals.** Digits, a point, and optionally more digits and an
exponent: `3.14`, `-0.5`, `6.25e-2`.

**String literals.** Text between double quotes: `"hello"`. The escapes are
`\n`, `\r`, `\t`, `\"`, `\'` and `\\`, and `\u{X}`, the code point X in one to six
hexadecimal digits written as UTF-8: `"caf\u{e9}"` holds five bytes. A
backslash followed by white space
skips everything up to the next backslash; that way a long string can go on
in the next line. A string literal has the type `Span[Nat8, Static]`.

**Triple-quoted strings.** Text between `"""` and `"""` may span lines. A
blank first line and a blank last line are dropped, and the indentation that
all lines share is removed. Inside, `\"""` stands for three quotes.

**Docstrings.** A triple-quoted string directly before a module, a
declaration, a record slot, a union case or a method is its documentation.

**Other values.** `true` and `false` are the two values of `Bool`. `nil` is
the only value of `Unit`.

**At a glance.**

| Form | Example | Type |
| --- | --- | --- |
| Decimal integer | `42`, `-42`, `1'000'000` | what its place asks for, otherwise `Int32` |
| Hexadecimal integer | `#xF0` | as a decimal integer; no sign |
| Binary integer | `#b1010` | as a decimal integer; no sign |
| Octal integer | `#o755` | as a decimal integer; no sign |
| Character | `'A'`, `'\n'` | an integer, usually `Nat8` |
| Float | `3.14`, `-0.5`, `6.25e-2` | `Float32` or `Float64`, as its place asks |
| String | `"hello"` | `Span[Nat8, Static]` |
| Triple-quoted string | `"""text"""` | `Span[Nat8, Static]` |
| Boolean | `true`, `false` | `Bool` |
| Unit value | `nil` | `Unit` |

| Escape | Stands for | In a character | In a string |
| --- | --- | --- | --- |
| `\n` | line feed | yes | yes |
| `\r` | carriage return | yes | yes |
| `\t` | tab | yes | yes |
| `\\` | backslash | yes | yes |
| `\"` | double quote | no | yes |
| `\'` | single quote | yes | yes |
| `\u{e9}` | a code point as UTF-8 | no | yes |

```hilde
-- Two hyphens start a comment. It runs to the end of the line.
module body Example.Literals is
    function main(): ExitCode is
        let million: Int32 := 1'000'000;
        let below: Int32 := -42;
        let mask: Nat8 := #xF0;
        let bits: Nat8 := #b0000'1010;
        let mode: Nat16 := #o755;
        let letter: Nat8 := 'A';
        let apostrophe: Nat8 := '\'';
        let accented: Span[Nat8, Static] := "caf\u{e9}";
        let ratio: Float64 := 6.25e-2;
        let yes: Bool := true;
        let nothing: Unit := nil;
        let quoted: Span[Nat8, Static] := "a \"quoted\" word";
        let joined: Span[Nat8, Static] := "one string, \
            \written in two lines";
        let block: Span[Nat8, Static] := """
            Triple quotes span lines.
              Shared indentation is removed.
            """;
        printLn(million);
        printLn(below);
        printLn(mask);
        printLn(bits);
        printLn(mode);
        printLn(letter);
        printLn(apostrophe);
        printLn(accented);
        printLn(ratio);
        printLn(yes);
        printLn(nothing);
        printLn(quoted);
        printLn(joined);
        printLn(block);
        return ExitSuccess();
    end;
end module body.
```

## 2. Modules

A module has two files. The interface, a `.hih` file, says what other
modules may use. The body, a `.hiq` file, defines it.

Difference from Austral: Austral names the two files `.aui` and `.aum`.

An interface has this form:

- an optional docstring,
- any number of imports,
- `module Name is`, the declarations, `end module.`

A body has this form:

- an optional docstring,
- any number of module pragmas (section 10),
- any number of imports,
- `module body Name is`, the definitions, `end module body.`

A module name is one or more identifiers joined by points: `Example.Counter`.

**Imports.** `import Example.Counter (make, finish as total);` makes the
listed names visible. `as` gives a name a local name. An import always lists
its names; there is no form that imports a whole module. Imports stand before
the word `module`.

**Opaque types.** An interface may declare a type without showing it:
`type Counter: Linear;`. The body defines it as a record or a union. Other
modules can use the type, but they cannot see its slots.

**The prelude.** Every module sees the module `Hilde.Pervasive` without an
import. It holds, among others, `Option`, `Either`, `ExitCode` and `printLn`.

Difference from Austral: there the prelude is `Austral.Pervasive`.

**Programs.** A program starts in a function `main(): ExitCode`. The command
line names it. `ExitSuccess()` ends the process with status 0,
`ExitFailure()` with 1, and `ExitStatus(status => n)` with `n`, a `Nat8`
from 0 to 125; a larger `n` stops the program with the message
`Exit status above 125.`, because the shell gives 126 and 127 to a command
it could not run and 128 and above to a signal. The main module of a
program often has a body and no interface. The example below is three
files, compiled with:
`hilde compile Counter.hih,Counter.hiq Main.hiq --entrypoint=Example.Main:main --output=main`

The interface, `Counter.hih`:

```hilde
"""
A counter that other modules cannot look inside.
"""
module Example.Counter is
    type Counter: Linear;

    constant start: Nat32;

    function make(): Counter;

    function next(counter: Counter): Counter;

    function finish(counter: Counter): Nat32;
end module.
```

The body, `Counter.hiq`:

```hilde
module body Example.Counter is
    record Counter: Linear is
        value: Nat32;
    end;

    constant start: Nat32 := 10;

    function make(): Counter is
        return Counter(value => start);
    end;

    function next(counter: Counter): Counter is
        let { value: Nat32 } := counter;
        return Counter(value => value + 1);
    end;

    function finish(counter: Counter): Nat32 is
        let { value: Nat32 } := counter;
        return value;
    end;
end module body.
```

The main module, `Main.hiq`:

```hilde
import Example.Counter (Counter, make, next, finish as total);

module body Example.Main is
    function main(): ExitCode is
        let first: Counter := make();
        let second: Counter := next(first);
        let third: Counter := next(second);
        printLn(total(third));
        return ExitSuccess();
    end;
end module body.
```

**Tests.** A test file is a module body beside the module it tests,
in a file whose name ends in `.test.hiq`. Every function of it whose name
is `test` followed by a capital letter or a digit is a test, and a test
has one of two forms: `function testName(): Unit`, or, when it needs the
root capability, `generic [R: Region] function testName(root:
&![RootCapability, R]): Unit`. A test passes when it returns and fails when
it ends the programme, with `abort` or with an assertion of
`Standard.Testing`. `hilde test .` runs the test files of the directory and
those below it: one programme per file, each test in a process of its own.
`--race`, `--memory` and `--valgrind` build and run the tests under
ThreadSanitizer, AddressSanitizer with UndefinedBehaviorSanitizer, or
valgrind. `--jobs=N` builds and runs N test files at once; the report is
the same as with one. `--test-jobs=M` runs M tests of a file at once, and
`--fresh-dirs` starts each test in an empty directory of its own, which tests
that write the same file need.

Difference from Austral: Austral has no test command.

The tests of the counter above, `Counter.test.hiq`:

```hilde
import Example.Counter (make, next, finish);

module body Example.Counter.Test is
    function testStartsAtTen(): Unit is
        if finish(make()) /= 10 then
            abort("a new counter is not 10");
        end if;
        return nil;
    end;

    function testCountsOne(): Unit is
        if finish(next(make())) /= 11 then
            abort("one step does not give 11");
        end if;
        return nil;
    end;
end module body.
```

A function with the name of a test and another form is refused, not left
out:

```hilde fails H2046
module body Example.Length.Test is
    function testLength(n: Nat32): Unit is
        return nil;
    end;
end module body.
```

## 3. Declarations

An interface holds declarations: `constant`, `type`, `record`, `union`,
`function`, `typeclass` and `instance`. A body holds definitions: the same
kinds without `type`, and with the values filled in.

**Constants.** In an interface: `constant limit: Int32;`. In a body:
`constant limit: Int32 := 100;`.

**Records.** A record has named slots:

- `record Point: Free is x: Int32; y: Int32; end;`

The word after the colon is the record's universe (section 4). A record value
is made by calling the record's name with named arguments:
`Point(x => 1, y => 2)`. A slot is read with a point: `origin.x`.

**Unions.** A union has cases. A case has no slots, or slots like a record:

- `union Shape: Free is case Dot; case Circle is radius: Int32; end;`

A union value is made by calling a case's name: `Circle(radius => 5)`,
`Dot()`.

**Functions.** `function name(parameter: Type, ...): ReturnType is` followed
by statements and `end;`. In an interface the declaration ends after the
return type with `;`. A function hands back its result with `return`. A
function with nothing to hand back has the return type `Unit` and returns
`nil`.

**Generic declarations** start with `generic [...]` (section 9).

Each declaration may be preceded by a docstring. Record slots and union cases
may have docstrings too.

```hilde
module body Example.Declarations is
    """
    The largest side a rectangle may have.
    """
    constant limit: Int32 := 100;

    record Point: Free is
        """
        Distance from the left edge.
        """
        x: Int32;
        y: Int32;
    end;

    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function perimeter(corner: Point): Int32 is
        return 2 * (corner.x + corner.y);
    end;

    function main(): ExitCode is
        let corner: Point := Point(x => 3, y => 4);
        let small: Shape := Circle(radius => 5);
        let large: Shape := Rectangle(width => 3, height => limit);
        let none: Shape := Dot();
        printLn(perimeter(corner));
        return ExitSuccess();
    end;
end module body.
```

**Contracts.** A function may carry a contract: after the return type,
clauses `requires condition` and `ensures condition`, any number and in
any order, before `;` in an interface or `is` in a body. Each condition is
an expression of type `Bool`. A requires is checked when the function is
entered, an ensures when it returns, and the checks are always on. A
violated condition stops the program with a message that gives the
condition, the function and the place of the contract; for a requires
also the call, whose caller is at fault, and for an ensures the place of
the function in the body, which is at fault. In an ensures `result` is
the value returned and `old(e)` the value `e` had when the function was
entered; `old` takes a free value.

A condition only reads: it uses a linear value through a reference,
takes no reference to write through, and calls no function that reaches
a binding module or C or asks for a reference to write through, however
deep the call. A write reference that is a parameter is read with `&`.
The contract of a public function stands in its interface only; a
function the interface does not declare has it in the body. Operators
take atomic operands, so a condition with more than one comparison has
parentheses. A function with a requires cannot be taken as a function
pointer, and the entry point and a test have none.

**Invariants.** A record may state invariants among its slots,
`invariant condition;`, naming the slots by their names. An invariant
holds for every value that leaves the module: it is checked at each
return of a public function of the module, for every parameter that is
a write reference to the record and for a result of the record's type or
one that holds the record as the payload of an `Option` (its `Some`) or as
the success of an `Either` (its `Right`), and its condition only reads, as
a contract's does. A record inside any other type, a pair or a buffer
of them, is not looked into. A function the
interface does not declare may pass through a broken state. Only a
record that its module alone can build and write has an invariant: the
interface declares its type opaque, or not at all.

**Testing contracts.** `hilde test --contracts` calls every public
function that has a contract and whose parameters are all integers,
`Index` or `Bool`, with inputs drawn from a seed: boundary values first,
then drawn ones. It keeps the inputs its requires accepts and lets its
ensures be checked; a function no input of which is accepted fails.
`--seed=N` repeats a run, and a failure shows the seed, the round and the
inputs; `--rounds=N` sets the inputs per function, 100 by default.

Difference from Austral: contracts and invariants are new in Hilde.

```hilde
module Example.Gauge is
    record Counter: Linear is
        count: Nat32;
    end;

    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32;

    generic [R: Region]
    function bump(counter: &![Counter, R], limit: Nat32): Unit
        requires peek(&counter) < limit
        ensures peek(&counter) = (old(peek(&counter)) + 1);
end module.
```

```hilde
module body Example.Gauge is
    generic [R: Region]
    function peek(counter: &[Counter, R]): Nat32 is
        return counter->count;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R], limit: Nat32): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;
end module body.
```

```hilde
import Example.Gauge (
    Counter,
    peek,
    bump
);

module body Example.Contracts is
    function half(n: Nat32): Nat32
        requires n > 0
        ensures (result * 2) <= n
    is
        return n / 2;
    end;

    function main(): ExitCode is
        var c: Counter := Counter(count => 0);
        bump(&!c, 3);
        bump(&!c, 3);
        printLn(peek(&c));
        printLn(half(9));
        let { count: Nat32 } := c;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

```hilde
module Example.Interval is
    type Interval: Free;

    function make(low: Nat32, high: Nat32): Interval;

    function width(interval: Interval): Nat32;
end module.
```

```hilde
module body Example.Interval is
    record Interval: Free is
        low: Nat32;
        high: Nat32;
        invariant low <= high;
    end;

    function make(low: Nat32, high: Nat32): Interval is
        return Interval(low => low, high => high);
    end;

    function width(interval: Interval): Nat32 is
        return interval.high - interval.low;
    end;
end module body.
```

```hilde
import Example.Interval (
    Interval,
    make,
    width
);

module body Example.Intervals is
    function main(): ExitCode is
        let i: Interval := make(3, 10);
        printLn(width(i));
        return ExitSuccess();
    end;
end module body.
```

```hilde fails H3096
module body Example.ContractConsumes is
    record Token: Linear is
        value: Nat32;
    end;

    function valueOf(token: Token): Nat32 is
        let { value: Nat32 } := token;
        return value;
    end;

    function spend(token: Token): Nat32
        requires valueOf(token) > 0
    is
        return valueOf(token);
    end;

    function main(): ExitCode is
        printLn(spend(Token(value => 3)));
        return ExitSuccess();
    end;
end module body.
```

**Error kinds.** A function may name the error kinds it can end with: after
the return type, a clause `raises NotFound, Denied`, among the contract
clauses and before `;` in an interface or `is` in a body. A kind is a name
written like an identifier; it is declared nowhere and has no value.
`raise NotFound;` is a statement that ends the program with that kind as
its message, the way `abort` ends it with a text, and nothing catches it.
A function may raise only the kinds its own clause names, and may call
only functions whose kinds it names: a call whose callee carries a kind the
caller's clause lacks is refused, and so is a function with no clause that
raises or calls one. `abort`, a violated contract and an arithmetic trap
are panics: they carry no kind and no clause names them. The clause of a
public function stands in its interface only, as its contract does. A
typeclass writes the clause at a method, `method measure(value: T): Int32
raises Broken;`, and every instance inherits it; a clause on an
instance's method is refused. A function with a raises clause cannot be
taken as a function pointer. `hilde query` lists the kinds of a function
under `raises`.

Difference from Austral: error kinds are new in Hilde.

```hilde
module Example.Store is
    function fetch(key: Nat32): Nat32
        raises NotFound;
end module.
```

```hilde
module body Example.Store is
    function fetch(key: Nat32): Nat32 is
        if key > 100 then
            raise NotFound;
        end if;
        return key * 2;
    end;
end module body.
```

```hilde
import Example.Store (
    fetch
);

module body Example.Stores is
    function lookup(key: Nat32): Nat32
        raises NotFound is
        return fetch(key);
    end;

    function main(): ExitCode
        raises NotFound is
        printLn(lookup(21));
        return ExitSuccess();
    end;
end module body.
```

```hilde fails H3103
module body Example.StoreUnnamed is
    function fetch(key: Nat32): Nat32
        raises NotFound is
        return key;
    end;

    function main(): ExitCode is
        printLn(fetch(21));
        return ExitSuccess();
    end;
end module body.
```

## 4. Types and universes

**Type specifiers.** A type is written as:

- a name: `Int32`,
- a name with type arguments in brackets: `Option[Int32]`,
  `Pair[Int32, Bool]`,
- a reference: `&[T, R]` to read, `&![T, R]` to write (section 7),
- a span, a view of consecutive values: `Span[T, R]` to read, `Span![T, R]`
  to write.

In references and spans, `R` is a region.

**Built-in types.** `Unit` and `Bool`; the unsigned integers `Nat8`, `Nat16`,
`Nat32`, `Nat64`; the signed integers `Int8`, `Int16`, `Int32`, `Int64`;
`Index` for positions and counts; `ByteSize` for sizes in bytes; the floating
point types `Float32` and `Float64`.

`Nat` comes from the natural numbers 0, 1, 2 and so on, so a `Nat` is never
negative: `Nat8` is a natural number in 8 bits, 0 to 255.

| Type | Smallest value | Largest value | Used for |
| --- | --- | --- | --- |
| `Unit` | `nil` | `nil` | a result that carries nothing; `nil` is its only value |
| `Bool` | `false` | `true` | conditions |
| `Nat8` | 0 | 255 | bytes and characters; text is a `Span[Nat8, R]` |
| `Nat16` | 0 | 65535 | unsigned integers in 16 bits |
| `Nat32` | 0 | 4294967295 | unsigned integers in 32 bits |
| `Nat64` | 0 | 18446744073709551615 | unsigned integers in 64 bits |
| `Int8` | -128 | 127 | signed integers in 8 bits |
| `Int16` | -32768 | 32767 | signed integers in 16 bits |
| `Int32` | -2147483648 | 2147483647 | signed integers in 32 bits; an integer literal where no type is asked for |
| `Int64` | -9223372036854775808 | 9223372036854775807 | signed integers in 64 bits |
| `Index` | 0 | 18446744073709551615 | positions and counts |
| `ByteSize` | 0 | 18446744073709551615 | sizes in bytes; the type of `sizeof` |
| `Float32` | about -3.4028235e38 | about 3.4028235e38 | floating point numbers in 32 bits, C's `float` |
| `Float64` | about -1.7976931348623157e308 | about 1.7976931348623157e308 | floating point numbers in 64 bits, C's `double` |

The integer bounds are the ones the compiler holds a literal against: a
`Nat8` written as `-1` or `256` is refused. `Index` and `ByteSize` are C's
`size_t`, so their largest value depends on the machine; the table shows it
for a 64-bit machine. The float bounds are the largest finite values,
rounded to the digits shown.

**Never.** `Never` is the result type of a function that does not come
back: it stops the programme or never ends. `abort` returns it. A function
that returns `Never` has no `return`; every path through it ends in a call
of a function that returns `Never`, in a `raise`, or in a `while true` loop
(H2060, H2061), and it has no `ensures` (H2062). A path of any other
function ends there too, so no dummy `return` follows a call of `abort`.
`Never` is no value: no parameter, variable, slot, constant or type
argument has it (H3109), and a call that returns it is not passed on as an
argument or an operand (H3110). It stands where a value is expected, in a
`let`, an assignment, a `return` or a branch of an `if` expression. In C
the function is `_Noreturn`. Difference from Austral: new in Hilde, after
Ada's `No_Return` and C17's `_Noreturn`.

```hilde
module body Example.Never is
    function stop(message: Span[Nat8, Static]): Never is
        abort(message);
    end;

    function positive(n: Int32): Int32 is
        if n > 0 then
            return n;
        end if;
        stop("not positive");
    end;

    function main(): ExitCode is
        printLn(positive(3));
        return ExitSuccess();
    end;
end module body.
```

**Universes.** Every type belongs to a universe. A declaration names it after
the colon:

- `Free`: a value can be copied and dropped freely.
- `Linear`: a value must be used exactly once. It is used by passing it to a
  function, returning it, or taking it apart. Section 8 gives the rules.
- `Type`: only for type parameters and generic types. A parameter in `Type`
  takes a Free or a Linear type. A generic record in `Type` is Free when its
  type arguments are Free.
- `Region`: only for type parameters that stand for a region.

`Static` is the region of values that live as long as the program, such as
string literals.

```hilde
module body Example.Types is
    record Pair[A: Type, B: Type]: Type is
        first: A;
        second: B;
    end;

    record Ticket: Linear is
        number: Nat32;
    end;

    function main(): ExitCode is
        let empty: Unit := nil;
        let flag: Bool := false;
        let a: Nat8 := 200;
        let b: Nat16 := 60'000;
        let c: Nat32 := 4'000'000'000;
        let d: Nat64 := 18'000'000'000'000'000'000;
        let e: Int8 := -100;
        let f: Int16 := -30'000;
        let g: Int32 := -2'000'000'000;
        let h: Int64 := -9'000'000'000'000'000'000;
        let position: Index := 3;
        let size: ByteSize := 64;
        let half: Float32 := 0.5;
        let third: Float64 := 0.333;
        let pair: Pair[Int32, Bool] := Pair(first => 7, second => true);
        let ticket: Ticket := Ticket(number => 1);
        let { number: Nat32 } := ticket;
        let text: Span[Nat8, Static] := "span";
        printLn(d);
        printLn(h);
        printLn(half);
        printLn(pair.first);
        printLn(number);
        printLn(spanLength(text));
        return ExitSuccess();
    end;
end module body.
```

## 5. Statements

**Bindings.** `let name: Type := value;` binds a name that cannot change.
`var name: Type := value;` binds one that can. The type is always written.

**Destructuring.** `let { x: Int32, y as height: Int32 } := point;` takes a
record apart. Each slot gets a name; `as` gives it a different one. `var` works
here too.

**Assignment.** `place := value;` A place is a variable, optionally followed
by `.slot`, `->slot` or `[index]`, as often as needed.

**Conditions.**

- `if condition then ... end if;`
- `if condition then ... else ... end if;`
- `if condition then ... else if condition then ... else ... end if;`

`else if` is one word only when `else` and `if` stand on the same line,
separated by spaces or tabs. An `else` at the end of a line followed by `if` on
the next line starts a new `if` inside the `else` block, and that one needs its
own `end if;`.

**Loops.**

- `while condition do ... end while;`
- `for i from first to last do ... end for;`

The loop variable of `for` has the type `Index`. Both bounds are included.

**Other statements.**

- `return value;` ends the function.
- `skip;` does nothing.
- `raise Kind;` ends the program with an error kind (section 3).
- An expression followed by `;` is a statement, usually a call:
  `printLn(total);`.

A block, such as the part between `then` and `else`, holds at least one
statement. `skip;` fills a block that has nothing to do.

`case` has section 11, `borrow` section 7.

Difference from Austral: a statement that throws away an `Option` or an
`Either` is refused. `ignore(value);` throws one away on purpose.

```hilde
module body Example.Statements is
    record Point: Free is
        x: Int32;
        y: Int32;
    end;

    function main(): ExitCode is
        let limit: Int32 := 5;
        var total: Int32 := 0;
        var count: Int32 := 0;
        while count < limit do
            count := count + 1;
            if count = 2 then
                skip;
            else if count = 4 then
                total := total + 100;
            else
                total := total + count;
            end if;
        end while;
        printLn(total);
        for i from 1 to 3 do
            printLn(i);
        end for;
        var point: Point := Point(x => 1, y => 2);
        point.x := 10;
        let { x: Int32, y as height: Int32 } := point;
        printLn(x + height);
        return ExitSuccess();
    end;
end module body.
```

## 6. Expressions

**No precedence.** The operands of an operator are atomic expressions: a
literal, a name, a call, a path, an expression in parentheses, or one of the
forms `&x`, `&!x`, `&~x`, `&(path)`, `&!(path)`, `!e`, `sizeof(T)` and `e?`.
So `a + b * c` does not parse; write `a + (b * c)`, and `(a < b) and (b < c)`.
The four associative operators `+`, `*`, `and` and `or` may form a chain of
the same operator, read from the left: `a + b + c` is `(a + b) + c`, and
`a and b and c` is `(a and b) and c`. A chain of `-` or `/`, or of two
operators, does not parse: `(a - b) - c`.

**Operators.**

| Operator | Meaning | Example |
| --- | --- | --- |
| `+` | addition | `a + b` |
| `-` | subtraction | `a - b` |
| `*` | multiplication | `a * b` |
| `/` | division | `a / b` |
| `-` before an operand | negation | `-a` |
| `=` | equal | `a = b` |
| `/=` | not equal | `a /= b` |
| `<` | less than | `a < b` |
| `<=` | less than or equal | `a <= b` |
| `>` | greater than | `a > b` |
| `>=` | greater than or equal | `a >= b` |
| `and` | true when both are true | `a and b` |
| `or` | true when at least one is true | `a or b` |
| `not` | the opposite of a condition | `not a` |
| `?` | the value out of an `Option` or `Either`, or return | `half(n)?` |
| `:` | type annotation | `5 : Int64` |
| `&` | borrow for reading | `&x` |
| `&!` | borrow for writing | `&!x` |
| `&~` | reborrow a write reference | `&~r` |
| `&( )` | a read reference to a part | `&(r->slot)` |
| `&!( )` | a write reference to a part | `&!(r->slot)` |
| `!` | the value behind a reference | `!r` |
| `.` | a slot of a record | `p.slot` |
| `->` | a slot through a reference | `r->slot` |
| `[ ]` | an element of a span | `s[i]` |

Negation and `not` apply to an atomic expression: `not (a = b)`.

Difference from Austral: Austral reads `-a` as `0 - a`. In Hilde `-a` is an
operation of its own, the method `trappingNegate` of the type class
`TrappingNegation`.

**Conditional expression.** `if condition then a else b` has a value.

**Type annotation.** `e : T` does three things: it gives an integer or float
literal a type (`5 : Int64`), it turns a write reference into a read
reference, and it tells a generic call which type to return.

**Size.** `sizeof(T)` is the size of a value of type `T` in bytes, as a
`ByteSize`.

**Calls.** Arguments are positional, `f(1, 2)`, or all named,
`f(first => 1, second => 2)`. The two kinds do not mix in one call.

**Paths.** `p.slot` reads a slot of a record. `r->slot` reads a slot through
a reference. `s[i]` reads an element of a span.

**Propagation.** `e?` takes the value out of an `Option` or an `Either`. On
`Some(value => v)` it gives `v`; on `None()` the enclosing function returns
`None()` at once. On `Right(right => v)` it gives `v`; on a `Left` the function
returns that `Left`. `e?` may only be the whole right side of a `let`, or a
whole statement. `!e?` reads as `!(e?)`; write `(!e)?` for the other order.

Difference from Austral: `?` is new in Hilde.

```hilde
module body Example.Expressions is
    function half(n: Int32): Option[Int32] is
        if rem(n, 2) = 0 then
            let result: Option[Int32] := Some(value => n / 2);
            return result;
        else
            let result: Option[Int32] := None();
            return result;
        end if;
    end;

    function quarter(n: Int32): Option[Int32] is
        let h: Int32 := half(n)?;
        let q: Int32 := half(h)?;
        let result: Option[Int32] := Some(value => q);
        return result;
    end;

    function mark(small: Bool, even: Bool): Int32 is
        return if small and even then 1 else 0;
    end;

    function main(): ExitCode is
        let a: Int32 := 7;
        let b: Int32 := 3;
        printLn((a + b) * 2);
        printLn(-a);
        printLn((a > b) and (not (a = b)));
        printLn(if a /= b then a else b);
        printLn(5 : Int64);
        let bytes: ByteSize := sizeof(Int64);
        printLn(bytes);
        printLn(mark(small => true, even => false));
        case quarter(20) of
            when Some(value: Int32) do
                printLn(value);
            when None do
                printLn("not a multiple of four");
        end case;
        return ExitSuccess();
    end;
end module body.
```

## 7. References and borrowing

A reference points at a value that belongs to someone else. It lives in a
region: a name for the stretch of code in which the reference is valid.

**Reference types.** `&[T, R]` reads a `T` in region `R`. `&![T, R]` may also
change it.

**Borrowing a variable.** `&x` lends the variable `x` for reading, `&!x` for
writing. Only a variable can be borrowed. To lend a variable for writing, it
must be declared with `var`.

When `w` is a write reference, `&w` is a read reference to the value `w`
points to, in a region of its own. While it lives, `w` cannot be used.

Difference from Austral: there `&w` is a reference to the variable `w`
itself, a reference to a reference.

**Reborrowing.** A write reference passed on is used up. `&~r` passes on a new
write reference and keeps `r` usable afterwards. A write reference can be
given a name of its own, `let w: &![T, R] := r;`; that moves it, as passing
it on does.

**Using a reference.**

- `!r` reads the value behind `r`.
- `r->slot` reads a slot of the record behind `r`. In a function that takes
  a write reference `r`, `r->slot := value;` changes the slot.
- `&(r->slot)` makes a read reference to that slot, in the region of `r`,
  whether `r` reads or writes. `&!(r->slot)` makes a write reference to it
  and needs a write reference `r`. The path may go on, as in `&(r->a->b)`.
  Either form uses up a write reference `r`.

Difference from Austral: there `&(path)` gives the kind of reference that
the head of the path has, and `&!(path)` does not exist.

**The borrow statement** gives the region a name:

- `borrow name: &[T, R] := &x do ... end borrow;`

Inside the block, `name` is a reference and `R` is its region. After `:=`,
`&x` borrows for reading, `&!x` for writing and `&~x` reborrows. That sigil
decides the kind of borrow; write the matching reference type before it.
When the borrow is for writing, `name` is a write reference, and
`name->slot := value;` changes the slot.

Difference from Austral: there an assignment through the name of a borrow
statement is refused; the value could only be changed by passing `name` to
a function that takes a write reference.

A function that takes a reference is usually generic over its region
(section 9).

```hilde
module body Example.Borrowing is
    record Account: Linear is
        balance: Int64;
    end;

    generic [R: Region]
    function balanceOf(account: &[Account, R]): Int64 is
        return account->balance;
    end;

    generic [R: Region]
    function deposit(account: &![Account, R], amount: Int64): Unit is
        account->balance := account->balance + amount;
        return nil;
    end;

    generic [R: Region]
    function depositTwice(account: &![Account, R], amount: Int64): Unit is
        deposit(&~account, amount);
        deposit(account, amount);
        return nil;
    end;

    function main(): ExitCode is
        var account: Account := Account(balance => 10);
        deposit(&!account, 5);
        depositTwice(&!account, 1);
        borrow slot: &![Account, W] := &!account do
            slot->balance := slot->balance + 100;
            let moved: &![Account, W] := slot;
            deposit(moved, 1);
        end borrow;
        printLn(balanceOf(&account));
        borrow view: &[Account, V] := &account do
            let field: &[Int64, V] := &(view->balance);
            printLn(!field);
        end borrow;
        let { balance: Int64 } := account;
        printLn(balance);
        return ExitSuccess();
    end;
end module body.
```

References to parts of a value, read through a write reference and
written through a part:

```hilde
module body Example.Parts is
    record Inner: Linear is
        value: Int32;
    end;

    record Pair: Linear is
        first: Inner;
        second: Inner;
    end;

    generic [R: Region]
    function valueOf(inner: &[Inner, R]): Int32 is
        return inner->value;
    end;

    generic [R: Region]
    function setValue(inner: &![Inner, R], value: Int32): Unit is
        inner->value := value;
        return nil;
    end;

    generic [R: Region]
    function total(pair: &[Pair, R]): Int32 is
        return valueOf(&(pair->first)) + valueOf(&(pair->second));
    end;

    generic [R: Region]
    function storeTotal(pair: &![Pair, R]): Unit is
        let sum: Int32 := total(&pair);
        setValue(&!(pair->second), sum);
        return nil;
    end;

    function main(): ExitCode is
        var pair: Pair := Pair(first => Inner(value => 2), second => Inner(value => 3));
        storeTotal(&!pair);
        printLn(total(&pair));
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        printLn(a + b);
        return ExitSuccess();
    end;
end module body.
```

A write reference to a part needs a write reference to the whole:

```hilde fails H3093
module body Example.ReadOnlyPart is
    record Inner: Linear is
        value: Int32;
    end;

    record Pair: Linear is
        first: Inner;
        second: Inner;
    end;

    generic [R: Region]
    function setValue(inner: &![Inner, R], value: Int32): Unit is
        inner->value := value;
        return nil;
    end;

    generic [R: Region]
    function clear(pair: &[Pair, R]): Unit is
        setValue(&!(pair->first), 0);
        return nil;
    end;

    function main(): ExitCode is
        let pair: Pair := Pair(first => Inner(value => 2), second => Inner(value => 3));
        clear(&pair);
        let { first: Inner, second: Inner } := pair;
        let { value as a: Int32 } := first;
        let { value as b: Int32 } := second;
        return ExitSuccess();
    end;
end module body.
```

## 8. Linear values

A value of a `Linear` type must be used exactly once. Using it up is called
consuming it: passing it to a function, returning it, or taking it apart with
`let { ... } :=`. The compiler checks this with the rules below. Each rule
has an example that compiles and one that fails. The opening line of a failing
example names the error code the compiler reports: ```` ```hilde fails H4012 ````.

**Exactly once.** A linear variable is consumed before the function returns,
and it is consumed only once.

```hilde
module body Example.Once is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

The ticket is never consumed:

```hilde fails H4012
module body Example.Forgotten is
    record Ticket: Linear is
        number: Int32;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        return ExitSuccess();
    end;
end module body.
```

The ticket is consumed twice:

```hilde fails H4008
module body Example.Twice is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        printLn(redeem(ticket));
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

**Branches.** Every branch of an `if` or a `case` consumes the same linear
variables.

```hilde
module body Example.Branch is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function tear(ticket: Ticket): Unit is
        let { number: Int32 } := ticket;
        return nil;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        let lucky: Bool := true;
        if lucky then
            printLn(redeem(ticket));
        else
            tear(ticket);
        end if;
        return ExitSuccess();
    end;
end module body.
```

Only one branch consumes the ticket:

```hilde fails H4004
module body Example.OneBranch is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        let lucky: Bool := true;
        if lucky then
            printLn(redeem(ticket));
        else
            skip;
        end if;
        return ExitSuccess();
    end;
end module body.
```

**Loops.** A loop body can run more than once. A linear variable from
outside the loop may be consumed in the body only if the body gives it a new
value before it ends. A linear value made inside the body is consumed there.

```hilde
module body Example.Loop is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        for i from 1 to 3 do
            let ticket: Ticket := Ticket(number => 7);
            printLn(redeem(ticket));
        end for;
        return ExitSuccess();
    end;
end module body.
```

The ticket is made before the loop and consumed inside it:

```hilde fails H4003
module body Example.LoopOutside is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        for i from 1 to 3 do
            printLn(redeem(ticket));
        end for;
        return ExitSuccess();
    end;
end module body.
```

**Borrowing.** While a variable is borrowed, it is not consumed. After the
borrow ends, it can be.

```hilde
module body Example.Borrow is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            printLn(view->number);
        end borrow;
        printLn(redeem(ticket));
        return ExitSuccess();
    end;
end module body.
```

The ticket is consumed while it is borrowed:

```hilde fails H4006
module body Example.BorrowConsumed is
    record Ticket: Linear is
        number: Int32;
    end;

    function redeem(ticket: Ticket): Int32 is
        let { number: Int32 } := ticket;
        return number;
    end;

    function main(): ExitCode is
        let ticket: Ticket := Ticket(number => 7);
        borrow view: &[Ticket, R] := &ticket do
            printLn(redeem(ticket));
        end borrow;
        return ExitSuccess();
    end;
end module body.
```

**Passing on a write reference.** A write reference is used up when it is
passed on. `&~` passes on a new one and keeps the old one usable.

```hilde
module body Example.Reborrow is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    generic [R: Region]
    function bumpTwice(counter: &![Counter, R]): Unit is
        bump(&~counter);
        bump(counter);
        return nil;
    end;

    function main(): ExitCode is
        var counter: Counter := Counter(count => 0);
        bumpTwice(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

The same write reference is passed on twice:

```hilde fails H4008
module body Example.PassedTwice is
    record Counter: Linear is
        count: Int32;
    end;

    generic [R: Region]
    function bump(counter: &![Counter, R]): Unit is
        counter->count := counter->count + 1;
        return nil;
    end;

    generic [R: Region]
    function bumpTwice(counter: &![Counter, R]): Unit is
        bump(counter);
        bump(counter);
        return nil;
    end;

    function main(): ExitCode is
        var counter: Counter := Counter(count => 0);
        bumpTwice(&!counter);
        let { count: Int32 } := counter;
        printLn(count);
        return ExitSuccess();
    end;
end module body.
```

## 9. Generics and type classes

**Type parameters.** A generic function begins with `generic` and a list of
type parameters: `generic [T: Free, R: Region]`. Each parameter names its
universe. A record or union takes its type parameters in brackets after its
name: `record Pair[T: Free]: Free is`.

**Constraints.** A type parameter may require type classes, in parentheses
after its universe: `T: Free(Describe)`, or `T: Type(First, Second)`.

**Type classes.** A type class names a type parameter and lists methods:

- `typeclass Describe(T: Free) is method describe(value: T): Span[Nat8, Static]; end;`

**Instances.** An instance gives the methods for one type. In a body it holds
the method definitions; in an interface only the head,
`instance Describe(Bool);`. A generic instance begins with `generic [...]`,
and so does a generic method.

**Calls.** A method is called like a function: `describe(true)`. Type
arguments are never written at a call; the compiler finds them from the
arguments and from the type that is expected.

```hilde
module body Example.Generics is
    record Pair[T: Free]: Free is
        left: T;
        right: T;
    end;

    generic [T: Free]
    function swap(pair: Pair[T]): Pair[T] is
        return Pair(left => pair.right, right => pair.left);
    end;

    typeclass Describe(T: Free) is
        method describe(value: T): Span[Nat8, Static];
    end;

    instance Describe(Bool) is
        method describe(value: Bool): Span[Nat8, Static] is
            if value then
                return "yes";
            else
                return "no";
            end if;
        end;
    end;

    generic [T: Free(Describe)]
    function show(value: T): Unit is
        printLn(describe(value));
        return nil;
    end;

    function main(): ExitCode is
        let pair: Pair[Int32] := Pair(left => 1, right => 2);
        let swapped: Pair[Int32] := swap(pair);
        printLn(swapped.left);
        show(true);
        show(false);
        return ExitSuccess();
    end;
end module body.
```

## 10. Pragmas

A pragma is an instruction to the compiler: `pragma Name;` or
`pragma Name(Argument => "value");`. Pragmas stand in two places.

**Before `module body`**, for the whole module:

- `pragma Unsafe_Module;` marks the module as unsafe. Only an unsafe module
  may bind C functions, use `@embed`, or name C libraries and headers.
- `pragma Foreign_Library(Name => "z");` links the C library `z`.
- `pragma Foreign_Library(Name => "crypt", System => "Linux");` links it
  only when the programme is compiled on that system, as `uname -s` names
  it: `Linux`, `OpenBSD`, `FreeBSD`, `NetBSD` or `Darwin`.
- `pragma Foreign_Header(Name => "zlib.h");` includes a C header.

**Before a definition in a body:**

- `pragma Foreign_Import(External_Name => "c_name");` binds the function that
  follows to a C function. Its body stays empty: `is end;`.
- `pragma Foreign_Export(External_Name => "c_name");` makes the function
  that follows callable from C under that name. The name is a C
  identifier, no keyword of C, not `main`, does not begin with `hilde_`,
  and no other function is exported under it (H2050). The function may be
  generic over regions, not over types (H2018). Its parameters and result
  cross as C types: `Bool` as `bool`, the integers as `int8_t` to
  `uint64_t` and `size_t`, the floats, `Span[Nat8, R]` and
  `Span![Nat8, R]` as a pointer and a length, a record or union without
  type parameters as a handle, and a reference to one as a pointer to its
  handle; any other type is refused (H3001).

`hilde compile --target-type=static --output=libname.a` and
`--target-type=shared --output=libname.so` build a library of the exported
functions, without `main`, and write its header `libname.h` beside it. A C
caller calls `hilde_start()` before the first of them and `hilde_end()`
after the last.

`hilde build` is `hilde compile` under a second name.  `--target=wasm`
builds for wasm32-wasi: a programme with `--entrypoint` becomes a command
module, its output ending in `.wasm` (H1044), which wasmtime runs as it
runs a binary; `--target-type=wasm` builds a library module, a reactor
whose host calls the exported functions after `hilde_start()`.  hilde finds
the compiler itself: zig (`HILDE_ZIG`, then on the path), else clang on
the path with `wasm-ld` and the C library of WASI; `HILDE_WASM_CC=zig` or
`clang` chooses (H1038, H1039).  `--target` names one of `linux`,
`openbsd`, `freebsd`, `darwin` and `wasm`; a system other than the one
hilde runs on is refused (H1041, H1042), and an archive or a shared object
for wasm too (H1043).  `hilde test --target=wasm` builds every test
programme as a command module and runs it in wasmtime (`HILDE_WASMTIME`,
then on the path, H1040), with the working directory, `/tmp` and the
environment handed to it.  A function marked `pragma Foreign_Export` is
exported to the host of the module in both forms.

**Before the imports of an interface**, for the module:

- `pragma Targets(Names => "linux openbsd freebsd darwin wasm");` names
  the targets the module is there for, separated by one space each.
  `Instead => "Standard.Regex"` after it names the module to take on a
  target that is not among them (H2068).  It is the only pragma there, and
  stands once (H2069).  Every interface of the standard library names its
  targets (H2071), and only the standard library does (H2070): what
  differs between the targets is in the standard library, and a programme
  holds no code for one target only.  A module names only targets every
  module it imports is there for (H2072), and a programme built for a
  target imports only modules that are there for it (H2073, with the
  module of `Instead` as a suggestion).

**Before a declaration in an interface:**

- `pragma Slot;` makes the function that follows a slot: one function of
  the programme may implement it, chosen when the whole programme is
  compiled. Its definition in the body, if there is one, is the default.
  A slot is generic over regions at most (H2067).

**Before a definition in a body, for a slot:**

- `pragma Implements(Name => "Module.function");` makes the function
  that follows the implementation of that slot. It has the slot's
  parameters, with their names and types, and its result (H2065); a
  slot has one implementation (H2064), the name is a slot of a module
  compiled before (H2066), and a slot without a default has one (H2063).
  Without a contract of its own it takes the slot's. The call is direct,
  through no function pointer. `Hilde.Pervasive` has two slots:
  `onOverflow`, which every trapping operation calls, and `onAbort`, which
  `abort` calls; both return `Never`. Difference from Austral: new in
  Hilde, after Rust's externally implementable items.

```hilde
module body Example.Slots is
    pragma Implements(Name => "Hilde.Pervasive.onOverflow");
    function overflowed(message: Span[Nat8, Static]): Never is
        printLn("an operation overflowed");
        abort(message);
    end;

    function main(): ExitCode is
        printLn("ok");
        return ExitSuccess();
    end;
end module body.
```

An interface has no module pragmas.

Difference from Austral: `Foreign_Library` and `Foreign_Header` are new in
Hilde, and `@embed` needs `pragma Unsafe_Module;`. An export over regions,
spans of bytes and handles, and the two library targets are new as well.

```hilde
pragma Unsafe_Module;

module body Example.Pragmas is
    pragma Foreign_Import(External_Name => "hilde_put_character");
    function putCharacter(character: Nat8): Int32 is
    end;

    pragma Foreign_Export(External_Name => "example_byte_count");
    generic [R: Region]
    function byteCount(bytes: Span[Nat8, R]): Index is
        return spanLength(bytes);
    end;

    function main(): ExitCode is
        putCharacter('o');
        putCharacter('k');
        putCharacter('\n');
        let two: Int32 := 2;
        let answer: Int32 := @embed(Int32, "40 + $1", two);
        printLn(answer);
        return ExitSuccess();
    end;
end module body.
```

## 11. case

`case` chooses a branch by the value of an expression:

- `case value of when ... do ... when ... do ... end case;`

A `when` can be written in two ways.

**By name.** A `when` names a case of a union and binds its slots by name and
type: `when Circle(radius: Int32) do`, or `when Circle(radius as r: Int32) do`
to use another name. A case without slots is named alone: `when Dot do`. Every
case of the union appears exactly once. This form also works on a reference to
a union; the slots are then bound as references of the same region, such as
`when Circle(radius: &[Int32, R]) do`.

**By pattern.** A `when` gives one or more patterns, separated by `|`. A
pattern is:

- a variable: a name that begins with a lower-case letter; it binds the value,
- `_`, which matches anything and binds nothing,
- an integer literal, including a character literal: `0`, `-1`, `#x41`, `'a'`,
- a range of two integer literals: `'a' .. 'z'`; without spaces, `0..9`,
- `true` or `false`,
- a variant: a name that begins with an upper-case letter, with one
  sub-pattern for each slot in parentheses, in the order of the slots:
  `Rectangle(1, _)`.

The first `when` that matches is taken. The compiler refuses a `case` that
leaves a value out, and a pattern that can never be chosen. A `case` over a
union has no catch-all: `_` or a variable is not allowed as a whole pattern
there. Over an integer or a `Bool`, `_` or a variable finishes the `case`.
Within one `when`, all alternatives bind the same variables. A `case` with
patterns takes a value, not a reference. The parser accepts float and string
literals as patterns; the compiler refuses them.

**Over an integer.** A `case` over an integer is the form for a dispatch on
codes: `when 0 do`, `when 1 | 2 do`, `when 3 .. 9 do`, and at the end
`when _ do` or `when n do`. No value stands in two branches, no branch runs on
into the next, and without `_` or a variable at the end the `case` must cover
every value of the type. When every `when` before the last has only literals
and ranges, and together they name at most 1024 values, the `case` becomes a
`switch` in C; otherwise a chain of `if`. The branch chosen is the same in
both forms.

The two ways do not mix: once one `when` of a `case` uses patterns, a `when`
that binds by name and type is refused. A `when` that is only a name, such as
`when Dot do`, fits both.

Difference from Austral: patterns are new in Hilde. In Austral, `when x do`
names a case of the union. In Hilde a name that begins with a lower-case
letter is a variable.

```hilde
module body Example.Case is
    union Shape: Free is
        case Dot;
        case Circle is
            radius: Int32;
        case Rectangle is
            width: Int32;
            height: Int32;
    end;

    function area(shape: Shape): Int32 is
        case shape of
            when Dot do
                return 0;
            when Circle(radius as r: Int32) do
                return (3 * r) * r;
            when Rectangle(width: Int32, height: Int32) do
                return width * height;
        end case;
    end;

    function kind(shape: Shape): Span[Nat8, Static] is
        case shape of
            when Dot | Circle(0) do
                return "a point";
            when Circle(r) do
                return "a circle";
            when Rectangle(1, _) | Rectangle(_, 1) do
                return "a line";
            when Rectangle(w, h) do
                return "a rectangle";
        end case;
    end;

    function digit(c: Nat8): Bool is
        case c of
            when '0' .. '9' do
                return true;
            when 65..90 | #x61 .. #x7A do
                return false;
            when _ do
                return false;
        end case;
    end;

    function main(): ExitCode is
        printLn(area(Rectangle(width => 2, height => 3)));
        printLn(kind(Circle(radius => 0)));
        printLn(kind(Rectangle(width => 1, height => 7)));
        printLn(kind(Rectangle(width => 2, height => 7)));
        printLn(digit('7'));
        printLn(digit('x'));
        return ExitSuccess();
    end;
end module body.
```

## 12. Forms that begin with @

Six forms begin with `@`. `@embed` appears in the example of section 10. The
other five need a file or a database beside the program, so this section has
no example of its own.

- `@embed(Type, "C expression", arguments)` is an expression. It pastes C
  into the program; `$1`, `$2` and so on stand for the arguments. Only an
  unsafe module may use it (section 10).
- `@bytes("path")` is an expression: the bytes of a file, read when the
  program is compiled, as a `Span[Nat8, Static]`. The path is relative to the
  module's own file. An absolute path or a `..` in it is refused.
- `@template("path", data, out);` is a statement. When the program is
  compiled, it reads the template file beside the module and turns it into
  statements that write into `out`, a `StringBuilder` variable. The names in
  the template come from `data`, a reference to a record. A fourth argument,
  a string, names Jinja2's whitespace options, separated by spaces:
  `@template("path", data, out, "trim_blocks lstrip_blocks");`.
  A template translates with `{% catalog messages %}`, which names a function
  that gives a `Standard.I18n` catalog, and then with
  `{{ _("Greeting", name=user) }}` or
  `{% trans count=n %}Items{% pluralize %}{% endtrans %}`. A key is a case of
  the union of the catalog's keys, so an unknown key does not compile; the
  language is the slot `lang` of `data`. The module imports `Standard.I18n`.
- `@query(&!db, "SQL", arguments) for row: Row do ... else error do ... end for;`
  is a statement for SQL that returns rows. The first block runs once for each
  row; the block after `else` runs when the query fails. The `else` part is
  required.
- `@execute(&!db, "SQL", arguments)` is an expression for SQL that returns no
  rows.
- `@migrations` is an expression: the migration files beside the module,
  `migrations/1-name.sql` and so on, put into the program.

In `@query` and `@execute` the database is written `&!db` or `&~db`. The SQL
is checked when the program is compiled, against the tables the migration
files create.

Difference from Austral: all of these except `@embed` are new in Hilde.
