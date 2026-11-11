# learn-map

## What it shows

A stock of fruit, counted as the boxes come in.  Each box carries the
name of its fruit as a string.

- `Standard.Sort` takes the buffer of boxes and hands it back in the order
  of the names.  The sort is stable, and `isSorted` says whether a buffer
  is in order.
- `binarySearch` looks for a name in the sorted boxes and says where it
  stands, or where it would have to go when it is missing.
- `Standard.Map` keeps one count per name.  Its entries always come in
  the order of their keys, so walking it gives the same lines on every
  run.
- A string cannot be lost in Hilde: the map takes each name over, and
  before the map ends every name is taken out again and destroyed.

Strings are ordered by `Standard.Order`, and the programme imports it for
that; without the import the compiler refuses the sort and the map.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-map
make
./main
```

## What comes out

```
sorted: apple apple apple fig pear pear plum
in order: true
pear: found at 4
kiwi: missing, it would go at 4
kinds of fruit: 4
apple 3
fig 1
pear 2
plum 1
```
