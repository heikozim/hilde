# learn-http

## What it shows

The web server's side, in memory.

- `Standard.Http` reads the header lines of a request, up to the empty
  line.
- `Standard.Fcgi` reads and writes the records a web server such as
  Hiawatha sends a FastCGI application, and turns a header's name into the
  variable a CGI programme would see.

No socket is opened.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-http
make
./main
```

## What comes out

```
header lines: 4
the first name: Host
Host: example.org
the connection is to be upgraded: true
as a CGI variable: HTTP_CONTENT_TYPE
a name with a byte out of place: none
pairs in the block: 1
its name: SCRIPT_NAME
its value: /index.hiq
the record: 32 bytes, a multiple of eight
kind 4, request 1, content 23 bytes, the whole record 32
the end of the request: 16 bytes
```
