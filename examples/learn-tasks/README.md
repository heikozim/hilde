# learn-tasks

## What it shows

Work done at the same time by tasks.

- Four tasks add up the squares of 1 to 1000, a quarter each.  A task
  gets its argument copied in and shares nothing with the others.
- All tasks are started in a scope, and the scope ends only when every
  task in it has ended: no task is left running.
- `join` waits for a task and gives back its result.  The four are joined
  in a fixed order, so the output is the same on every run, although the
  tasks may finish in any order.
- A fifth task gets an arena of its own, memory that belongs to that task
  and ends with it.  It writes the squares of 1 to 100 into the arena and
  adds them up.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-tasks
make
./main
```

## What comes out

```
5239625
36552125
99114625
192927125
333833500
338350
```

The first four lines are the four quarters, the fifth their sum, which is
1000 * 1001 * 2001 / 6.  The last line is the arena task's sum,
100 * 101 * 201 / 6.
