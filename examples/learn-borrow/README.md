# learn-borrow

## What it shows

References: reading and writing a value without taking it.

- `bump` takes a write reference `&![Counter, R]` and changes the caller's counter; the caller keeps it.
- A write reference passed on is used up. `bumpTwice` passes `&~counter` first, a new reference that
  leaves `counter` usable, and hands on `counter` itself in its last use.
- A write reference is taken from a `var`; at the end the record is taken apart, which is how a linear
  value ends.
- Three bumps in all: the programme prints 3.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-borrow
make
./main
```

## What comes out

```
3
```
