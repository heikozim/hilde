# learn-match

## What it shows

A `case` that looks into a value with patterns.  The example is a
keyboard: an event is a key press, with or without shift, or a tick of
time, and a key is a character or one of two special keys.

- Patterns go two levels deep: `Press(Char(97 .. 122), false)` looks into
  the event and into its key at once.
- A range such as `97 .. 122` takes every value from 97 to 122, the small
  letters a to z.
- A bar `|` joins patterns that have the same answer.
- An underscore `_` takes any value without giving it a name.

The first pattern that fits is taken.  A case that leaves out a value is
refused by the compiler.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-match
make
./main
```

## What comes out

```
a small letter
a capital letter
a capital letter
a digit
another character
a key that is not a character
no time at all
a tick of 250 ms
```
