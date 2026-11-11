# learn-testing

## What it shows

The assertions of `Standard.Testing`, used in a plain programme.

A test file of the standard library is written the same way, as a file
named after its module with `.test.hiq`, and `hilde test` runs it, under
the thread checker or the memory checkers when asked.  Each assertion
prints what it checks and `ok`; one that fails ends the programme with a
message, so a failing test cannot pass unnoticed.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-testing
make
./main
```

## What comes out

```
        Assert: 2024 is a leap year ok
        Assert: 2026 is not ok
        Assert: 1900, a century, is not ok
        Assert: 2000, divided by 400, is ok
        Assert: every case of the rule reached ok
```
