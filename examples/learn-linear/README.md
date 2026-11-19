# learn-linear

## What it shows

Linear types: a value that is used exactly once.

- `Ticket` is a linear record: it cannot be copied, and a function cannot end still holding one it did
  not hand on.
- `peek` takes a read reference `&[Ticket, R]` and only looks; the caller keeps the ticket.
- `use` takes the ticket by value and consumes it: it takes the record apart. Any use of the ticket
  after that line is a compile error.
- The programme prints the seat twice through `peek` and once through `use`.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-linear
make
./main
```

## What comes out

```
12
12
12
```
