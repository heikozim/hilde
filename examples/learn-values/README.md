# learn-values

## What it shows

Small values of the standard library.

- `Standard.Box` keeps a value on the heap.
- `Standard.Bounded` knows the least and the largest value of each number
  type.
- `Standard.Equality` is the type class of equal; the programme gives it
  an instance for a point of its own.
- `Standard.Failure` carries what went wrong, and each caller wraps it with
  what it was doing.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-values
make
./main
```

## What comes out

```
in the box: 7
swapped out: 7
taken out: 11
the smallest Int8: -128
the largest Nat16: 65535
(1, 2) equals (1, 2): true
(1, 2) equals (2, 1): false
failure: load the configuration: open: no file named server.toml
steps in the chain: 2
as an HTTP status: 404
```
