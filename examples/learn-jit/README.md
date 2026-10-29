# learn-jit

## What it shows

`Standard.PcreJit` asks the JIT of PCRE2 to compile a pattern to machine
code.  The import is the declaration: a programme that imports only
`Standard.Pcre` never makes machine code at run time, one that imports
`Standard.PcreJit` does.

The pattern that `compile` gives back is a `Regex` of `Standard.Pcre`,
searched with that module's functions, and the searches find the same with
machine code as without it.  `fallBack` says why the JIT gave no machine
code, when it gave none; the interpreter of PCRE2 searches then.

The programme finds the time of every line of a log that holds a warning
or a fatal error, with machine code.  Then it compiles a pattern the JIT
refuses, a callout right before the assertion of a condition, and the
interpreter finds its matches.

The PCRE2 that Hilde builds maps no page writable and executable at once,
so the JIT works where the system forbids such pages, as OpenBSD does.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-jit
make
./main
```

PCRE2 with its JIT has to be installed.

## What comes out

```
the JIT is built in: true
warnings: machine code
  12:01
  12:03
with a callout: the interpreter, because Standard.Pcre: feature is not supported by the JIT compiler
  Warning
  FATAL
```
