# learn-context

## What it shows

Cancellation that reaches down a chain, after the context of Go.

- `Standard.Context` starts at the background, which is never done.
- A request gets a context below the top of the chain, and two workers,
  tasks of a lending scope, are lent it and work until it is done.  One
  cancel at the top stops both, and the request's own context reports
  that it was cancelled.
- A context with a deadline of 50 ms ends a wait of 10 seconds after 50
  milliseconds.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-context
make
./main
```

## What comes out

```
the background: not done
the top of the chain is cancelled
both workers stopped after doing some work: true
the request's context: cancelled
a context of 50 ms, waited on for 10 s: past its deadline
```
