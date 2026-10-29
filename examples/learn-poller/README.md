# learn-poller

## What it shows

A server and its client in one programme.  They talk over a Unix socket in
the working directory, so nothing goes to the network, and the socket is
gone when the programme ends.

`Standard.Poller` waits until a descriptor has something to read: the
server waits for the client's `hello`, the client for the server's
`world`.  Neither side reads before the other has written.

The poller is built on epoll on Linux and on kqueue on OpenBSD, FreeBSD
and macOS, and the programme first names the one it has.  For what this
programme waits on, both give the same events, so everything after that
first line is the same on Linux and OpenBSD.  On a system with neither,
the programme says so and ends.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-poller
make
./main
```

## What comes out

On Linux:

```
poller:      epoll
client wrote: true
server watched: true
server ready: 1
server readable: true
server read: hello
server wrote: true
client watched: true
client ready: 1
client readable: true
client read: world
server closed: true
client closed: true
listener closed: true
```

On OpenBSD, where the backend is kqueue:

```
poller:      kqueue
client wrote: true
server watched: true
server ready: 1
server readable: true
server read: hello
server wrote: true
client watched: true
client ready: 1
client readable: true
client read: world
server closed: true
client closed: true
listener closed: true
```
