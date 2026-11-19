#!/usr/bin/env python3
"""An SMTP relay for the end-to-end tests of Standard.Smtp.

    python3 scripts/smtp/server.py <mode>

Run by a test programme as its child, in the test's working directory, as
scripts/http/server.py is: it makes two self-signed certificates for the
name `localhost' with the system's `openssl' command -- `server-cert.pem',
the one it presents, and `other-cert.pem', one it does not -- so no
private key lies in the repository; listens on 127.0.0.1; prints its port
as five digits and a newline -- the test reads exactly six bytes -- and
takes ONE connection.  What it does with it is the mode:

    starttls    a greeting of two lines, EHLO offering STARTTLS, TLS,
                EHLO offering AUTH LOGIN PLAIN, then the login, the
                envelope, the data and QUIT, all accepted
    nostarttls  as starttls, but EHLO offers no STARTTLS; a STARTTLS
                sent anyway is still answered, so that a client that
                does not check the offer is seen to go on
    injection   as starttls, but the 220 to STARTTLS comes with another
                reply line in the same write, before TLS
    implicit    TLS from the first byte, then as starttls after TLS
    cleartext   no TLS at all; EHLO offers STARTTLS, which is not used
    authfail    as starttls, but the login is refused, and the refusal
                quotes the login back
    rejectrcpt  as starttls, but the second RCPT is refused
    stall       takes the connection and says nothing
    drip        a greeting of 60 bytes, one byte every 100 ms: every
                read of the client gets a byte in time, and only a
                limit on the whole dialogue ends it
    badreply    a greeting without a code

The login it takes is the user `mailer' with the password `s3cret-pass'.

Last it prints what it saw, in words that do not depend on the TLS
library or on the port: each command, the login only as whether it was
right, and each line of the data as it came, dots and all.  A test
compares its output on Linux and OpenBSD alike.

Exit 0 when the connection came, 1 when none came within 20 seconds, 2
for an unknown mode, 9 when the certificate could not be made.
"""
import base64
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

MODES = ("starttls", "nostarttls", "injection", "implicit", "cleartext",
         "authfail", "rejectrcpt", "stall", "drip", "badreply")

LOGIN = b"\0mailer\0s3cret-pass"


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


class Lines:
    """Lines from a socket, plain or TLS, without their line ends."""

    def __init__(self, stream):
        self.stream = stream
        self.data = b""

    def line(self):
        """The next line, or None when the client closed."""
        while b"\n" not in self.data:
            chunk = self.stream.recv(4096)
            if not chunk:
                return None
            self.data += chunk
        line, _, self.data = self.data.partition(b"\n")
        return line.rstrip(b"\r")


def say(text):
    print("server: " + text)


def wait_for_close(connection):
    """Read until the client closes, at most 20 seconds."""
    connection.settimeout(20)
    try:
        while connection.recv(4096):
            pass
    except (ssl.SSLError, OSError):
        pass


def ehlo_offers(secure):
    """The reply to EHLO: STARTTLS before TLS, the login after it."""
    if secure:
        return (b"250-smtp.test\r\n250-AUTH LOGIN PLAIN\r\n"
                b"250 SIZE 10240000\r\n")
    return (b"250-smtp.test\r\n250-PIPELINING\r\n250-STARTTLS\r\n"
            b"250 8BITMIME\r\n")


def read_data(lines, stream):
    """The data up to the line with a single dot, each line printed."""
    count = 0
    while True:
        line = lines.line()
        if line is None:
            say("the client closed during the data")
            return False
        if line == b".":
            say("end of data after %d lines" % count)
            stream.sendall(b"250 2.0.0 queued\r\n")
            return True
        count += 1
        say(("| " + line.decode("latin-1")) if line else "|")


def converse(lines, stream, mode, secure):
    """From the first EHLO over this stream to the end.  The stream to
    go on with after STARTTLS, or None when the dialogue is over."""
    recipients = 0
    while True:
        line = lines.line()
        if line is None:
            say("the client closed")
            return None
        verb = line.split(b" ")[0].upper()
        if verb == b"AUTH":
            words = line.split(b" ")
            try:
                right = (len(words) == 3 and words[1].upper() == b"PLAIN"
                         and base64.b64decode(words[2], validate=True) == LOGIN)
            except ValueError:
                right = False
            say("AUTH PLAIN (the login is %s)" % ("right" if right else "wrong"))
        else:
            say(line.decode("latin-1"))
        if verb == b"EHLO":
            offers = ehlo_offers(secure)
            if mode == "nostarttls":
                offers = offers.replace(b"250-STARTTLS\r\n", b"")
            stream.sendall(offers)
        elif verb == b"STARTTLS":
            if secure:
                stream.sendall(b"503 5.5.1 TLS already\r\n")
                continue
            if lines.data:
                say("the client sent more before TLS")
            if mode == "injection":
                stream.sendall(b"220 2.0.0 go ahead\r\n250 injected\r\n")
            else:
                stream.sendall(b"220 2.0.0 go ahead\r\n")
            return "tls"
        elif verb == b"AUTH":
            if mode == "authfail":
                stream.sendall(b"535 5.7.8 rejected: " + line.split(b" ")[-1] + b"\r\n")
            else:
                stream.sendall(b"235 2.7.0 accepted\r\n")
        elif verb == b"MAIL":
            stream.sendall(b"250 2.1.0 sender ok\r\n")
        elif verb == b"RCPT":
            recipients += 1
            if mode == "rejectrcpt" and recipients == 2:
                stream.sendall(b"550 5.1.1 no such user here\r\n")
            else:
                stream.sendall(b"250 2.1.5 recipient ok\r\n")
        elif verb == b"DATA":
            stream.sendall(b"354 go on\r\n")
            if not read_data(lines, stream):
                return None
        elif verb == b"QUIT":
            stream.sendall(b"221 2.0.0 bye\r\n")
            say("the dialogue ended with QUIT")
            return None
        else:
            stream.sendall(b"500 5.5.2 what\r\n")


def handshake(connection, context):
    """TLS over connection, or None when the handshake failed."""
    try:
        return context.wrap_socket(connection, server_side=True)
    except (ssl.SSLError, OSError):
        say("the handshake failed")
        return None


def serve(connection, context, mode):
    if mode == "stall":
        wait_for_close(connection)
        say("nothing said, the client closed")
        return
    if mode == "drip":
        greeting = b"220 " + b"x" * 56 + b"\r\n"
        try:
            for byte in greeting:
                time.sleep(0.1)
                connection.sendall(bytes([byte]))
        except OSError:
            say("the client closed while the greeting dripped")
            return
        wait_for_close(connection)
        say("the whole greeting dripped")
        return
    if mode == "badreply":
        connection.sendall(b"hello there\r\n")
        wait_for_close(connection)
        say("a greeting without a code, the client closed")
        return
    stream = connection
    secure = False
    if mode == "implicit":
        stream = handshake(connection, context)
        if stream is None:
            return
        secure = True
    stream.sendall(b"220-smtp.test ESMTP\r\n220 ready\r\n")
    lines = Lines(stream)
    going = converse(lines, stream, mode, secure)
    if going == "tls":
        stream = handshake(connection, context)
        if stream is None:
            return
        say("TLS began")
        lines = Lines(stream)
        converse(lines, stream, mode, True)
    try:
        stream.close()
    except (ssl.SSLError, OSError):
        pass


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in MODES:
        sys.stderr.write("usage: server.py <%s>\n" % "|".join(MODES))
        sys.exit(2)
    mode = sys.argv[1]
    make_certificate("server")
    make_certificate("other")
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain("server-cert.pem", "server-key.pem")
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
    connection.settimeout(20)
    try:
        serve(connection, context, mode)
    except (ssl.SSLError, OSError) as error:
        say("the connection failed: %s" % type(error).__name__)
    connection.close()


if __name__ == "__main__":
    main()
