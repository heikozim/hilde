# learn-data

## What it shows

One order in three formats, and its sum.

- `Standard.Csv` reads the lines of the order.
- `Standard.Decimal` adds their prices exactly, without the rounding of
  binary floating point.
- `Standard.Json` writes the order and reads a field back by its JSON
  pointer.
- `Standard.Ini` reads the settings of the shop.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-data
make
./main
```

## What comes out

```
lines of the order: 2
sum: 7.30
with tax, rounded: 8.69
as JSON: {"lines":[{"name":"coffee","price":4.20},{"name":"tea, green","price":3.10}],"total":7.30,"items":2}
the second line: tea, green
lines in the JSON: 2
name: Corner Cafe
open: true
```
