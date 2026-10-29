# learn-library

## What it shows

The library mode.

- `Gauge.hiq` exports three functions to C with
  `pragma Foreign_Export`.  A span of bytes crosses as a pointer and a
  length.
- `hilde compile --target-type=static` writes `libgauge.a` and its header
  `libgauge.h`; the header also names the libraries the archive needs.
- `caller.c` calls `hilde_start` before the first function of the library
  and `hilde_end` after the last.

For the warning count and the memory runs of the checks, `make c` writes
the same programme as one C file: the library's C, then the caller.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-library
make
./main
```

## What comes out

```
sum of the readings: 680
readings above 100: 3
an empty span sums to: 0
300 is a reading: no
42 is a reading: yes
```
