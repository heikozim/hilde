# learn-toml

## What it shows

Reading a server's configuration in TOML with `Standard.Toml`.  The whole
text is read and checked first; values are then asked for by paths such
as `server.port` or `server.route[1].upstream.host`.

- A bare key, a quoted one, a table with a header, an array of tables
  with `[[...]]` and an inline table are all reached by one kind of path.
- Integers come as `Int64`, with their underscores gone; a date and time
  comes as its text.
- A path to nothing gives None, not a stop.
- A text TOML does not allow is refused with the line and the column of
  the first thing that is wrong: a key defined twice, and an integer with
  a leading zero.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-toml
make
./main
```

## What comes out

```
title: example
host: 0.0.0.0
port: 8080
tls: true
started: 2026-09-28T01:00:00Z
routes: 2
first route: /
its root: /var/www
second route goes to: 127.0.0.1
on port: 9000
the second key of server: port
a key that is not there: (none)
refused: something defined twice at line 2, column 1
refused: a bad number at line 2, column 8
```
