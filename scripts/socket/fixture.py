#!/usr/bin/env python3
"""Put something at a path for `Standard.File.listenUnix` to find, or say
what is there, for the end-to-end test of what `listenUnix` refuses.

    python3 scripts/socket/fixture.py stale <path>    a socket nobody accepts on
    python3 scripts/socket/fixture.py fifo <path>     a named pipe
    python3 scripts/socket/fixture.py mode <path>     is it a socket, and its mode

`stale` binds a socket to the path and exits without removing it, which is
what a server that died leaves behind.  `fifo` makes something that is not
a socket and that connect(2) on Linux refuses exactly as it refuses a stale
socket -- the case in which the refusal alone would be the wrong test.
`mode` reads the file as the kernel has it, for the mode `listenUnix` was
asked to set.  The test removes what it made itself, with
`Standard.File.removeFile`.
"""

import os
import socket
import stat
import sys


def main():
    if len(sys.argv) != 3 or sys.argv[1] not in ("stale", "fifo", "mode"):
        raise SystemExit("usage: fixture.py stale|fifo|mode <path>")
    what, path = sys.argv[1], sys.argv[2]
    if what == "stale":
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.bind(path)
        sock.close()
        print("fixture: left a stale socket")
    elif what == "fifo":
        os.mkfifo(path, 0o600)
        print("fixture: left a fifo")
    else:
        info = os.lstat(path)
        kind = "a socket" if stat.S_ISSOCK(info.st_mode) else "not a socket"
        print("fixture: %s, mode %03o" % (kind, stat.S_IMODE(info.st_mode)))


if __name__ == "__main__":
    main()
