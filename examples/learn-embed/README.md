# learn-embed

## What it shows

Two forms that begin with an at sign.

- `@bytes("motto.txt")` puts the bytes of the file beside the module into
  the programme when it is compiled.  The programme does not need the file
  when it runs.
- `@embed(Int32, "$1 * $2", a, b)` pastes a C expression into the
  programme, with `$1` and so on for its arguments.  It can do anything C
  can, so only a module marked `pragma Unsafe_Module;` may use it.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-embed
make
./main
```

## What comes out

```
the motto, read when the programme was compiled: Simple things done well.
its bytes: 25
6 times 7, computed by C: 42
a pointer has 32 or 64 bits: true
```
