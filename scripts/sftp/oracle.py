#!/usr/bin/env python3
"""The oracle for the end-to-end tests of Standard.Sftp.

    python3 scripts/sftp/oracle.py <sftp-server> <empty-work-dir> > exchange.txt

Runs OpenSSH's sftp-server as a child, in <empty-work-dir>, and plays the
scenario of the recorded-server test against it: every request is written
the way Standard.Sftp writes it, and every byte that goes either way is
printed as one line of hex -- `>' a request, `<' a reply.  That test's fake
server replays that file: it checks each request of the Hilde client against the
recorded one byte for byte, and answers with the recorded reply.  So the
client is held to what the real server was sent and answered.

The work directory must be empty and is empty again at the end; a reply
that is not the one the scenario needs stops the script with exit 1.
Runs where sftp-server is -- a host; the gate image has none.
"""
import os
import struct
import subprocess
import sys

if len(sys.argv) != 3:
    print(__doc__, file=sys.stderr)
    sys.exit(9)
program, work = sys.argv[1], sys.argv[2]
if os.listdir(work):
    print("ABORT: %s is not empty" % work, file=sys.stderr)
    sys.exit(9)

server = subprocess.Popen([program], cwd=work, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
next_id = [1]

# The two files of the scenario: a short one, and one of 32800 bytes, which
# takes two WRITEs and two READs at the client's chunk of 32768.
SHORT = b"hello, sftp\n"
LONG = bytes((i * 7 + 3) % 251 for i in range(32800))
CHUNK = 32768


def u32(n):
    return struct.pack(">I", n)


def u64(n):
    return struct.pack(">Q", n)


def s(data):
    if isinstance(data, str):
        data = data.encode()
    return u32(len(data)) + data


def send(kind, payload, with_id=True):
    body = bytes([kind])
    if with_id:
        body += u32(next_id[0])
        next_id[0] += 1
    body += payload
    packet = u32(len(body)) + body
    print(">", packet.hex())
    server.stdin.write(packet)
    server.stdin.flush()


def receive():
    head = server.stdout.read(4)
    (length,) = struct.unpack(">I", head)
    body = server.stdout.read(length)
    print("<", (head + body).hex())
    return body


def status(body):
    if body[0] != 101:
        print("ABORT: expected STATUS, got type %d" % body[0], file=sys.stderr)
        sys.exit(1)
    return struct.unpack(">I", body[5:9])[0]


def handle(body):
    if body[0] != 102:
        print("ABORT: expected HANDLE, got type %d" % body[0], file=sys.stderr)
        sys.exit(1)
    (n,) = struct.unpack(">I", body[5:9])
    return body[9:9 + n]


def write_file(path, data):
    send(3, s(path) + u32(0x02 | 0x08 | 0x10) + u32(0x04) + u32(0o600))
    h = handle(receive())
    offset = 0
    while offset < len(data):
        piece = data[offset:offset + CHUNK]
        send(6, s(h) + u64(offset) + s(piece))
        assert status(receive()) == 0
        offset += len(piece)
    send(4, s(h))
    assert status(receive()) == 0


def read_file(path):
    send(3, s(path) + u32(0x01) + u32(0))
    h = handle(receive())
    got = b""
    while True:
        send(5, s(h) + u64(len(got)) + u32(CHUNK))
        body = receive()
        if body[0] == 103:
            (n,) = struct.unpack(">I", body[5:9])
            got += body[9:9 + n]
        else:
            assert status(body) == 1
            break
    send(4, s(h))
    assert status(receive()) == 0
    return got


send(1, u32(3), with_id=False)
assert receive()[0] == 2
write_file("hello.txt", SHORT)
assert read_file("hello.txt") == SHORT
write_file("long.bin", LONG)
assert read_file("long.bin") == LONG
send(17, s("hello.txt"))
assert receive()[0] == 105
send(17, s("missing.txt"))
assert status(receive()) == 2
send(14, s("sub") + u32(0x04) + u32(0o700))
assert status(receive()) == 0
send(11, s("."))
h = handle(receive())
while True:
    send(12, s(h))
    body = receive()
    if body[0] != 104:
        assert status(body) == 1
        break
send(4, s(h))
assert status(receive()) == 0
send(18, s("hello.txt") + s("moved.txt"))
assert status(receive()) == 0
send(13, s("moved.txt"))
assert status(receive()) == 0
send(13, s("long.bin"))
assert status(receive()) == 0
send(15, s("sub"))
assert status(receive()) == 0
send(13, s("moved.txt"))
assert status(receive()) == 2
server.stdin.close()
code = server.wait()
left = os.listdir(work)
print("# sftp-server exit=%d, left in the work directory: %d" % (code, len(left)), file=sys.stderr)
sys.exit(0 if code == 0 and not left else 1)
