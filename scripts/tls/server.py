#!/usr/bin/env python3
"""A TLS server for the end-to-end tests of Standard.Tls.

    python3 scripts/tls/server.py [--rsa <bits>]

Run by a test programme as its child, in the test's working directory.  It
makes two self-signed certificates for the name `localhost' with the
system's `openssl' command -- `server-cert.pem', the one it presents, and
`other-cert.pem', one it does not -- so no private key lies in the
repository: each is made for one run and removed with the test's
directory.  Then it listens on 127.0.0.1, prints its port as five
digits and a newline -- the test reads exactly six bytes -- and takes ONE
connection: it reads a line, answers "echo: " and the line, and closes.
What it saw it prints last, in words that do not depend on the TLS
library: a test compares its output on Linux (OpenSSL) and OpenBSD
(LibreSSL) alike.

The keys are on P-256.  With --rsa the key of `server-cert.pem' is RSA of
that many bits, and the server prints last the size openssl reads back
from the certificate.

Exit 0 when the connection came and was served or refused, 1 when none
came within 20 seconds, 9 when a certificate could not be made.
"""
import socket
import ssl
import subprocess
import sys

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


def make_certificate(name, rsa_bits=0):
    """name-cert.pem and name-key.pem, self-signed, one day; RSA of
    rsa_bits bits when that is not 0, else P-256."""
    config = name + ".cnf"
    with open(config, "w") as stream:
        stream.write(CONFIG)
    if rsa_bits:
        key = ["-newkey", "rsa:%d" % rsa_bits]
    else:
        key = ["-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1"]
    done = subprocess.run(
        ["openssl", "req", "-x509"] + key + ["-nodes",
         "-keyout", name + "-key.pem", "-out", name + "-cert.pem",
         "-days", "1", "-config", config],
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if done.returncode != 0:
        sys.stderr.write("openssl req failed: %s\n" % done.stderr.decode("utf-8", "replace"))
        sys.exit(9)


def key_bits(certificate):
    """The size of the key in certificate as openssl reads it, or 0."""
    done = subprocess.run(
        ["openssl", "x509", "-in", certificate, "-noout", "-text"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    for line in done.stdout.decode("utf-8", "replace").splitlines():
        words = line.replace("(", " ").split()
        if "Public-Key:" in words and len(words) > words.index("Public-Key:") + 1:
            return int(words[words.index("Public-Key:") + 1])
    return 0


def main():
    rsa_bits = 0
    if len(sys.argv) == 3 and sys.argv[1] == "--rsa":
        rsa_bits = int(sys.argv[2])
    elif len(sys.argv) != 1:
        sys.stderr.write("usage: server.py [--rsa <bits>]\n")
        sys.exit(9)
    make_certificate("server", rsa_bits)
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
        tls = context.wrap_socket(connection, server_side=True)
    except (ssl.SSLError, OSError):
        print("server: the handshake failed")
        connection.close()
        return
    line = b""
    while not line.endswith(b"\n"):
        chunk = tls.recv(1024)
        if not chunk:
            break
        line += chunk
    tls.sendall(b"echo: " + line)
    try:
        tls.unwrap()
    except (ssl.SSLError, OSError):
        pass
    tls.close()
    print("server: handshake done, %d bytes read and echoed" % len(line))
    if rsa_bits:
        print("server: the key of server-cert.pem has %d bits" % key_bits("server-cert.pem"))


if __name__ == "__main__":
    main()
