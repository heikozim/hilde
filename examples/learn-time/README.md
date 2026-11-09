# learn-time

## What it shows

Time and the calendar.

- `Standard.Time` reads the clocks of the system; only whether they
  answered is printed, since their values change from run to run.
- `Standard.Calendar` turns an instant into a date and a time of day, in
  UTC and in a zone, reads and writes RFC 3339, and finds the hour a clock
  skips when summer time begins.

The zone comes from a POSIX rule, so the programme does not depend on the
zone files of the system and prints the same on every run.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-time
make
./main
```

## What comes out

```
the wall clock runs: true
a monotonic clock: true
in UTC: 2026-09-28 01:00:00
the weekday, 1 for Monday: 1
as RFC 3339: 2026-09-28T01:00:00Z
with a clock two hours east: 2026-09-28T03:00:00+02:00
read back, seconds since 1970: 1790557200
and nanoseconds: 500000000
February 30 is refused
in Berlin: 2026-09-28 03:00:00
offset in seconds: 7200
summer time: true
abbreviation: CEST
02:30 on 2026-03-29: skipped, the clocks go from 02:00 to 03:00
```
