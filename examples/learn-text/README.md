# learn-text

## What it shows

Text: `String`, `StringBuilder` and spans.

- `fromLiteral` makes a `String` of a literal; a `StringBuilder` joins two strings and a byte, and
  `finalize` consumes the builder and hands out the result.
- `print` takes a span, not a `String`: `getSpan` gives one, with the last index inclusive, and an empty
  string is asked about first, since it has no span.
- A `String` owns memory. It is linear and ends with `destroyString`, each one by name.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-text
make
./main
```

## What comes out

```
Hello, Hilde!
length: 13
```
