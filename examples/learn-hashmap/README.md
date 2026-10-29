# learn-hashmap

## What it shows

Counting the words of a sentence with `Standard.HashMap`.  The map hashes
its keys with SipHash-1-3 under a key that the system's secure random
source gives every map, so the slots a key falls on differ from run to
run; the entries stand one after another in the order they came in, and
`keyAt` and `valueAt` reach them by position, so the output is the same on
every run.

- A key type must be `Hashable` and have a `TotalOrder`; the instances
  for `String` are seen through imports from `Standard.Hash` and
  `Standard.Order`.
- `put` gives back the old key and value when the key was there already.
- `remove` takes an entry out, and the last entry moves into its place.
- A word that is not in the map is looked up without a stop.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-hashmap
make
./main
```

## What comes out

```
different words: 5
  the 4
  cat 2
  saw 2
  dog 2
  and 1
removed saw, counted 2
after the removal, the last entry in its place:
  the 4
  cat 2
  and 1
  dog 2
bird: 0
```
