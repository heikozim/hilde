# learn-log

## What it shows

What a service does around its work.

- `Standard.Log` writes entries with a level and named fields, as text or
  as JSON, to standard error, a file or syslog.
- `Standard.Signal` catches a signal the process sends itself.
- `Standard.Resource` reads the limits and the usage of the process.

Only what is the same on every run is printed: an entry formatted for a
fixed instant, and whether each call answered.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-log
make
./main
```

## What comes out

```
as text: time=2026-09-28T01:00:00.000Z level=INFO msg="request served" path=/index.html status=200 cached=false
as JSON: {"time":"2026-09-28T01:00:00.000Z","level":"INFO","msg":"request served","path":"/index.html","status":200,"cached":false}
the log takes debug: false
the log takes errors: true
an error written: true
the entry of a request written: true
closed: true
the log file removed: true
sent USR1 to itself: true
USR1 taken: true
taken again: false
watch stopped: true
open files, the soft limit within the hard: true
the usage of the process was read
the system is up: true
```
