# learn-records

## What it shows

Records and the references into them.

- `Example.Interval`, beside the programme, has an opaque type with the
  invariant `low <= high`.  It is checked at each return of a public
  function of that module; every one of them keeps it.
- A `Day` holds two intervals.  `&!(day->evening)` is a write reference to
  one of them, made from a write reference to the whole day.
- `borrow view: &[Day, V] := &day do ... end borrow;` names the region the
  reference lives in, for as long as its block runs.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-records
make
./main
```

## What comes out

```
an interval from 9 to 5: refused, the low end is above the high end
hours in the day: 7
the evening stretched by two: true
stretched past the largest number: false
the evening ends at: 21
hours now: 9
```
