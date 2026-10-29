#!/usr/bin/env python3
"""Stand in for an SFTP server by replaying a recorded exchange.

    python3 scripts/sftp/replay.py <exchange.txt>

<exchange.txt> is what scripts/sftp/oracle.py recorded against OpenSSH's
sftp-server: `>' lines are the requests the server was sent, `<' lines the
replies it gave, each one packet as hex.  This script reads a packet from
its standard input for every `>' line and compares it with the recorded one
byte for byte, and writes every `<' line to its standard output.  So a
client that talks to it is held to exactly what the real server was sent.

Exit 0 when every line was used and every request matched; 3 at the first
request that differs (the two are written to standard error); 4 when the
client stopped before the exchange was over or sent more after it.
Written in Python and not in Hilde on purpose: the thing that checks the
client should not share its code.
"""
import struct
import sys

if len(sys.argv) != 2:
    print(__doc__, file=sys.stderr)
    sys.exit(9)
lines = [line.split() for line in open(sys.argv[1]) if line.strip() and not line.startswith("#")]
stdin = sys.stdin.buffer
stdout = sys.stdout.buffer


def read_exactly(n):
    got = b""
    while len(got) < n:
        piece = stdin.read(n - len(got))
        if not piece:
            return None
        got += piece
    return got


for number, (direction, data) in enumerate(lines, 1):
    expected = bytes.fromhex(data)
    if direction == ">":
        head = read_exactly(4)
        if head is None:
            print("replay: the client stopped before request %d" % number, file=sys.stderr)
            sys.exit(4)
        (length,) = struct.unpack(">I", head)
        body = read_exactly(length)
        if body is None or head + body != expected:
            print("replay: request %d differs" % number, file=sys.stderr)
            print("  expected %s" % expected.hex()[:200], file=sys.stderr)
            print("  got      %s" % (head + (body or b"")).hex()[:200], file=sys.stderr)
            sys.exit(3)
    elif direction == "<":
        stdout.write(expected)
        stdout.flush()
    else:
        print("replay: line %d is neither > nor <" % number, file=sys.stderr)
        sys.exit(9)
if stdin.read(1):
    print("replay: the client sent more after the exchange was over", file=sys.stderr)
    sys.exit(4)
sys.exit(0)
