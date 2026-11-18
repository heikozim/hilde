#!/usr/bin/env python3
"""An HTTPS server for the end-to-end tests of Standard.HttpClient.

    python3 scripts/http/server.py <mode>

Run by a test programme as its child, in the test's working directory, as
scripts/tls/server.py is: it makes two self-signed certificates for the
name `localhost' with the system's `openssl' command -- `server-cert.pem',
the one it presents, and `other-cert.pem', one it does not -- so no
private key lies in the repository; listens on 127.0.0.1; prints its port
as five digits and a newline -- the test reads exactly six bytes -- and
takes ONE connection.  What it does with it is the mode:

    length      200 with a Content-Length and the body
    chunked     200 with a chunked body, a chunk extension and a trailer
    close       200 with no length: the body ends when the server closes
    announced   200 announcing 1000 bytes, more than the test allows
    flood       200 with no length and 4096 bytes, more than allowed
    stall       reads the request and answers nothing
    drip        a header announcing 100 bytes, then one byte every 100 ms
    badstatus   a status line of HTTP/2.0
    echo        200 with the request's method, target, one header and body
    interim     100 Continue, then 200 with a body
    nohello     takes the TCP connection and never answers the handshake
    trickle     the answer as one TLS record, sent one byte every 100 ms:
                every read(2) of the client gets a byte in time, and only
                a limit on the whole call ends it
    twolengths  two Content-Length lines that disagree
    badchunk    a chunked body whose size line is not hexadecimal
    mutual      asks for a client certificate, trusts only a third
                self-signed one it makes, `client-cert.pem' with
                `client-key.pem', and answers as length

Last it prints what it saw, in words that do not depend on the TLS
library or on the port: the request line and its header lines, the Host
header's port written PORT.  A test compares its output on Linux and
OpenBSD alike.

Exit 0 when the connection came, 1 when none came within 20 seconds, 2
for an unknown mode, 9 when the certificate could not be made.
"""
import socket
import ssl
import subprocess
import sys
import time

CONFIG = """[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = localhost
[v3]
basicConstraints = critical,CA:TRUE
keyUsage = digitalSignature,keyCertSign
subjectAltName = DNS:localhost
"""

MODES = ("length", "chunked", "close", "announced", "flood", "stall",
         "drip", "badstatus", "echo", "interim", "nohello", "trickle",
         "twolengths", "badchunk", "mutual")


def make_certificate(name):
    """name-cert.pem and name-key.pem, self-signed, one day."""
    config = name + ".cnf"
    with open(config, "w") as stream:
        stream.write(CONFIG)
    done = subprocess.run(
        ["openssl", "req", "-x509", "-newkey", "ec",
         "-pkeyopt", "ec_paramgen_curve:prime256v1", "-nodes",
         "-keyout", name + "-key.pem", "-out", name + "-cert.pem",
         "-days", "1", "-config", config],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if done.returncode != 0:
        sys.stderr.write("openssl req failed: %s\n" % done.stderr.decode("utf-8", "replace"))
        sys.exit(9)


def read_request(tls):
    """The request's head and body: the head up to the empty line, the
    body by its Content-Length.  None when the client closed first."""
    data = b""
    while b"\r\n\r\n" not in data:
        chunk = tls.recv(4096)
        if not chunk:
            return None
        data += chunk
    head, _, body = data.partition(b"\r\n\r\n")
    length = 0
    for line in head.split(b"\r\n")[1:]:
        name, _, value = line.partition(b":")
        if name.strip().lower() == b"content-length":
            length = int(value.strip())
    while len(body) < length:
        chunk = tls.recv(4096)
        if not chunk:
            break
        body += chunk
    return head, body


def shown(head):
    """The request head as lines, the Host header's port written PORT."""
    lines = []
    for line in head.split(b"\r\n"):
        text = line.decode("latin-1")
        if text.lower().startswith("host:") and ":" in text[5:]:
            text = text[:text.rindex(":")] + ":PORT"
        lines.append(text)
    return lines


def wait_for_close(connection):
    """Read until the client closes, at most 20 seconds."""
    connection.settimeout(20)
    try:
        while connection.recv(4096):
            pass
    except (ssl.SSLError, OSError):
        pass


def answer(tls, mode, request):
    """Send the mode's answer; the words for what happened."""
    head, body = request
    if mode in ("length", "mutual"):
        tls.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 11\r\n"
                    b"X-Mode: length\r\n\r\nhello world")
    elif mode == "chunked":
        tls.sendall(b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
                    b"3;ext=1\r\nhel\r\n3\r\nlo \r\n5\r\nworld\r\n0\r\n"
                    b"X-Trailer: 1\r\n\r\n")
    elif mode == "close":
        tls.sendall(b"HTTP/1.0 200 OK\r\n\r\nuntil the end")
    elif mode == "announced":
        tls.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 1000\r\n\r\n")
    elif mode == "flood":
        # Whether the kernel took all of it before the client closed
        # depends on its buffers, so both ends are reported alike.
        try:
            tls.sendall(b"HTTP/1.1 200 OK\r\n\r\n" + b"x" * 4096)
        except (ssl.SSLError, OSError):
            pass
        return "flooded"
    elif mode == "stall":
        wait_for_close(tls)
        return "nothing answered, the client closed"
    elif mode == "drip":
        try:
            tls.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\n")
            for _ in range(100):
                time.sleep(0.1)
                tls.sendall(b"x")
        except (ssl.SSLError, OSError):
            return "the client closed while the body dripped"
        return "all 100 bytes dripped"
    elif mode == "badstatus":
        tls.sendall(b"HTTP/2.0 200 OK\r\nContent-Length: 2\r\n\r\nno")
    elif mode == "echo":
        method, target = head.split(b"\r\n")[0].split(b" ")[:2]
        extra = b""
        for line in head.split(b"\r\n")[1:]:
            name, _, value = line.partition(b":")
            if name.strip().lower() == b"x-test":
                extra = value.strip()
        reply = method + b" " + target + b" x-test=" + extra + b" body=" + body
        tls.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: %d\r\n\r\n" % len(reply) + reply)
    elif mode == "interim":
        tls.sendall(b"HTTP/1.1 100 Continue\r\n\r\n"
                    b"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nafter")
    elif mode == "twolengths":
        tls.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 5\r\n"
                    b"Content-Length: 7\r\n\r\nhello, ")
    elif mode == "badchunk":
        tls.sendall(b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n"
                    b"zz\r\nhello\r\n0\r\n\r\n")
    return "answered"


def trickle(connection, context):
    """TLS through memory buffers, so that the server decides what goes on
    the wire and when: the handshake and the request as usual, then the
    whole answer encrypted into one record and that record sent one byte
    every 100 ms.  The words for what happened."""
    incoming = ssl.MemoryBIO()
    outgoing = ssl.MemoryBIO()
    tls = context.wrap_bio(incoming, outgoing, server_side=True)

    def flush():
        data = outgoing.read()
        if data:
            connection.sendall(data)

    def pump():
        chunk = connection.recv(4096)
        if not chunk:
            raise EOFError()
        incoming.write(chunk)

    try:
        while True:
            try:
                tls.do_handshake()
                break
            except ssl.SSLWantReadError:
                flush()
                pump()
        flush()
        data = b""
        while b"\r\n\r\n" not in data:
            try:
                chunk = tls.read(4096)
            except ssl.SSLWantReadError:
                flush()
                pump()
                continue
            # The client closed: read answers nothing from then on, and
            # asking again would never end.
            if not chunk:
                raise EOFError()
            data += chunk
    except (ssl.SSLError, OSError, EOFError):
        return None, "no request came"
    head = data.partition(b"\r\n\r\n")[0]
    tls.write(b"HTTP/1.1 200 OK\r\nContent-Length: 60\r\n\r\n" + b"y" * 60)
    record = outgoing.read()
    try:
        for byte in record:
            time.sleep(0.1)
            connection.sendall(bytes([byte]))
    except OSError:
        return head, "the client closed while the record trickled"
    return head, "the whole record trickled"


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in MODES:
        sys.stderr.write("usage: server.py <%s>\n" % "|".join(MODES))
        sys.exit(2)
    mode = sys.argv[1]
    make_certificate("server")
    make_certificate("other")
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain("server-cert.pem", "server-key.pem")
    if mode == "mutual":
        make_certificate("client")
        context.verify_mode = ssl.CERT_REQUIRED
        context.load_verify_locations("client-cert.pem")
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(20)
    sys.stdout.write("%05d\n" % listener.getsockname()[1])
    sys.stdout.flush()
    try:
        connection, _ = listener.accept()
    except socket.timeout:
        print("server: no connection came")
        sys.exit(1)
    if mode == "nohello":
        wait_for_close(connection)
        connection.close()
        print("server: the handshake was never answered, the client closed")
        return
    connection.settimeout(20)
    if mode == "trickle":
        head, what = trickle(connection, context)
        if head is not None:
            for line in shown(head):
                print("server: " + line)
        connection.close()
        print("server: " + what)
        return
    try:
        tls = context.wrap_socket(connection, server_side=True)
    except (ssl.SSLError, OSError):
        print("server: the handshake failed")
        connection.close()
        return
    try:
        request = read_request(tls)
    except (ssl.SSLError, OSError):
        request = None
    if request is None:
        print("server: no request came")
        tls.close()
        return
    for line in shown(request[0]):
        print("server: " + line)
    if mode == "mutual":
        print("server: client certificate presented: %s" % bool(tls.getpeercert()))
    print("server: body of %d bytes" % len(request[1]))
    try:
        what = answer(tls, mode, request)
    except (ssl.SSLError, OSError):
        what = "the answer could not be sent"
    try:
        tls.unwrap()
    except (ssl.SSLError, OSError):
        pass
    tls.close()
    print("server: " + what)


if __name__ == "__main__":
    main()
