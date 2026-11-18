# learn-network

## What it shows

The network modules, as far as they work without a network, so that the
output is the same on every machine.

- `Standard.Ip` reads, masks and anonymises addresses.
- `Standard.Resolve` checks host names and looks up `localhost`.
- `Standard.HttpClient` reads the https URLs it will fetch and refuses
  others.
- `Standard.Tls` is refused by a port on this machine where nothing
  listens.
- `Standard.Smtp` composes a message for a fixed time.
- `Standard.Sftp` says what the error codes of a server mean.

None of them stops the programme on bad input.

## How to build it

From the root of the repository, after the compiler is built:

```
cd examples/learn-network
make
./main
```

## What comes out

```
198.51.100.20: IPv6 false, private or reserved true
8.8.8.8: IPv6 false, private or reserved false
2001:db8::1: IPv6 true, private or reserved true
300.1.1.1: no address
anonymised: 198.51.100.0
in 198.51.100.0/24: true
example.org is a host name: true
bad_name is a host name: false
localhost is 127.0.0.1: true
https://example.org:8443/news?page=2#top: host example.org, port 8443, path /news?page=2
https://[2001:db8::1]/: host 2001:db8::1, port 443, path /
http://example.org/: refused
header lines are well formed: true
a header line with a line feed in its value: false
TLS to 127.0.0.1 port 9: refused
ann@example.org is an address: true
the message's first line: Date: Mon, 28 Sep 2026 01:00:00 +0000
its bytes: 207
SFTP 2: no such file
SFTP 3: permission denied
SFTP -1: the server went away
```
