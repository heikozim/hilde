# learn-errors

## What it shows

Errors as values: `Option`, the `?` after a call, and `ignore`.

- `halve` gives `Some` of half an even number and `None` for an odd one.
- `eighth` halves three times. A `?` after a call, as the whole right side of a `let`, returns `None`
  at once when the call gave `None`, and otherwise gives the value inside.
- `show` looks at the result with a `case` over both variants.
- An `Option` or `Either` that nobody looks at is a compile error; a result that really does not matter
  is thrown away by name, with `ignore`.
- 40 is halved three times to 5; 12 becomes 3 on the second step, which is odd.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-errors
make
./main
```

## What comes out

```
5
odd on the way
```
