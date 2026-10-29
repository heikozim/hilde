#!/usr/bin/env python3
"""One FastCGI request over a Unix domain socket, sent as a web server
sends it: the other end of the end-to-end test of FastCGI over a Unix
domain socket.

    python3 scripts/socket/fcgi-client.py <socket-path>

Written from the FastCGI 1.0 specification with the standard library and
nothing else -- it shares no code with `Standard.Fcgi`, so a record that
both ends agree on is one that two readings of the specification agree on.

It sends BEGIN_REQUEST (responder), the parameters, an empty PARAMS, a
body in STDIN and an empty STDIN, and prints every record that comes back
until END_REQUEST, one line each.  One parameter value is 200 bytes long,
so that its length takes the four-byte form.
"""

import socket
import struct
import sys

VERSION = 1
BEGIN_REQUEST = 1
END_REQUEST = 3
PARAMS = 4
STDIN = 5
NAMES = {3: "END_REQUEST", 6: "STDOUT", 7: "STDERR"}
REQUEST_ID = 1
RESPONDER = 1


def record(kind, content):
    padding = (8 - len(content) % 8) % 8
    header = struct.pack(">BBHHBx", VERSION, kind, REQUEST_ID, len(content), padding)
    return header + content + b"\0" * padding


def length(n):
    if n < 128:
        return bytes([n])
    return struct.pack(">I", n | 0x80000000)


def pairs(items):
    return b"".join(length(len(k)) + length(len(v)) + k + v for k, v in items)


def read_exactly(sock, n):
    data = b""
    while len(data) < n:
        chunk = sock.recv(n - len(data))
        if not chunk:
            raise SystemExit("fcgi-client: the connection closed after %d of %d bytes" % (len(data), n))
        data += chunk
    return data


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: fcgi-client.py <socket-path>")
    params = [
        (b"REQUEST_METHOD", b"POST"),
        (b"SCRIPT_NAME", b"/greet"),
        (b"QUERY_STRING", b"name=hilde"),
        (b"CONTENT_LENGTH", b"11"),
        (b"HTTP_X_LONG", b"v" * 200),
    ]
    body = b"hello there"
    request = (record(BEGIN_REQUEST, struct.pack(">HB5x", RESPONDER, 0))
               + record(PARAMS, pairs(params)) + record(PARAMS, b"")
               + record(STDIN, body) + record(STDIN, b""))
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(sys.argv[1])
    sock.sendall(request)
    print("sent %d bytes in 5 records" % len(request))
    while True:
        version, kind, rid, clen, plen = struct.unpack(">BBHHBx", read_exactly(sock, 8))
        content = read_exactly(sock, clen)
        read_exactly(sock, plen)
        if version != VERSION:
            raise SystemExit("fcgi-client: version %d" % version)
        if kind == END_REQUEST:
            app, proto = struct.unpack(">IB3x", content)
            print("END_REQUEST id=%d app-status=%d protocol-status=%d" % (rid, app, proto))
            break
        print("%s id=%d length=%d padding=%d %r"
              % (NAMES.get(kind, str(kind)), rid, clen, plen, content.decode("ascii")))
    rest = sock.recv(1)
    print("after END_REQUEST: %s" % ("closed" if rest == b"" else "more bytes"))
    sock.close()


if __name__ == "__main__":
    main()
