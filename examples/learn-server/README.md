# learn-server

## What it shows

The application's side of FastCGI, over a real socket.

- `Standard.FcgiServer` listens on a Unix domain socket in the example's
  directory, accepts the one connection a task of the programme makes as
  a web server would, hands the request to a handler and writes the
  handler's CGI output back.  The loop stops after one connection, as its
  limits say, and serves the connections it took to their end.
- `Standard.File` binds a TCP listener to 127.0.0.1 on a port the kernel
  chooses.

Nothing leaves the machine, and the socket file is removed again.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-server
make
./main
```

## What comes out

```
connections accepted: 1
what the web server got back, its CR LF printed as LF:
Status: 200 OK
Content-Type: text/plain

hello, name=hilde
listener closed: true
a TCP port was chosen: true
TCP listener closed: true
```
