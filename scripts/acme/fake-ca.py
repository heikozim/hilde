#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""A small ACME server after RFC 8555 for the tests of Standard.Acme.

    python3 scripts/acme/fake-ca.py

Run by a test programme as its child, in the test's working directory.  It
makes a CA certificate for the name localhost with the openssl command,
listens on 127.0.0.1 with TLS, prints its port as five digits and a
newline, and serves until its standard input ends.

What it holds the client to, for every POST: a body of three base64url
fields; a protected header with alg ES256, a nonce it issued and that was
not used, the URL the request went to, and a jwk for newAccount and the
account's kid for everything else; and a signature that openssl dgst
verifies under the key of the jwk.  The first POST is answered with
badNonce on purpose, so that the client's retry is held too.  The CSR of
the finalize is verified with openssl req and must ask for exactly the
names of the order; the certificate is made from it by openssl x509 -req.
The expected TXT value of dns-01 is written to expected-dns.txt for the
test to compare.  Each request is printed in one line, and every line is
the same from run to run.
"""
import base64
import hashlib
import json
import os
import socket
import ssl
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

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

SPKI_PREFIX = bytes.fromhex("3059301306072a8648ce3d020106082a8648ce3d030107034200") + b"\x04"


def b64url_decode(text):
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def der_integer(value):
    value = value.lstrip(b"\x00") or b"\x00"
    if value[0] & 0x80:
        value = b"\x00" + value
    return b"\x02" + bytes([len(value)]) + value


def run(arguments, data=None):
    return subprocess.run(arguments, input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


class State:
    def __init__(self, base):
        self.base = base
        self.nonces = set()
        self.counter = 0
        self.jwk = None
        self.account = base + "/acct/1"
        self.names = []
        self.token = "tokentokentokentokentokentoken0123456789ab"
        self.authorized = False
        self.order_status = "pending"
        self.bad_nonce_left = 1
        self.lock = threading.Lock()

    def nonce(self):
        with self.lock:
            self.counter += 1
            value = b64url(hashlib.sha256(b"nonce %d" % self.counter).digest()[:16])
            self.nonces.add(value)
            return value

    def order(self):
        body = {
            "status": self.order_status,
            "identifiers": [{"type": "dns", "value": n} for n in self.names],
            "authorizations": [self.base + "/authz/1"],
            "finalize": self.base + "/finalize/1",
        }
        if self.order_status == "valid":
            body["certificate"] = self.base + "/cert/1"
        return body


def verify_signature(jwk, signing_input, signature):
    if jwk.get("kty") != "EC" or jwk.get("crv") != "P-256":
        return False
    x, y = b64url_decode(jwk["x"]), b64url_decode(jwk["y"])
    if len(x) != 32 or len(y) != 32 or len(signature) != 64:
        return False
    spki = SPKI_PREFIX + x + y
    pem = b"-----BEGIN PUBLIC KEY-----\n" + base64.encodebytes(spki) + b"-----END PUBLIC KEY-----\n"
    der = b"\x30" + bytes([len(der_integer(signature[:32]) + der_integer(signature[32:]))]) + \
        der_integer(signature[:32]) + der_integer(signature[32:])
    with open("jws-key.pem", "wb") as stream:
        stream.write(pem)
    with open("jws-signature.der", "wb") as stream:
        stream.write(der)
    with open("jws-input.txt", "wb") as stream:
        stream.write(signing_input)
    done = run(["openssl", "dgst", "-sha256", "-verify", "jws-key.pem", "-signature", "jws-signature.der", "jws-input.txt"])
    return done.returncode == 0


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *args):
        pass

    def send(self, status, body=b"", content_type="application/json", extra=()):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Replay-Nonce", self.server.state.nonce())
        self.send_header("Connection", "close")
        for name, value in extra:
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(body)

    def problem(self, kind, detail):
        print("  refused: %s %s" % (kind, detail), flush=True)
        body = json.dumps({"type": "urn:ietf:params:acme:error:" + kind, "detail": detail}).encode()
        self.send(400, body, "application/problem+json")

    def do_GET(self):
        state = self.server.state
        if self.path == "/directory":
            print("GET /directory", flush=True)
            body = json.dumps({"newNonce": state.base + "/new-nonce", "newAccount": state.base + "/new-account",
                               "newOrder": state.base + "/new-order"}).encode()
            self.send(200, body)
        elif self.path == "/new-nonce":
            print("GET /new-nonce", flush=True)
            self.send(200)
        else:
            self.send(404)

    def do_POST(self):
        state = self.server.state
        size = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(size)
        print("POST %s" % self.path, flush=True)
        if self.headers.get("Content-Type") != "application/jose+json":
            return self.problem("malformed", "not application/jose+json")
        try:
            body = json.loads(raw)
            protected = json.loads(b64url_decode(body["protected"]))
            payload_text = body["payload"]
            signature = b64url_decode(body["signature"])
        except (ValueError, KeyError):
            return self.problem("malformed", "not a JWS")
        if protected.get("alg") != "ES256":
            return self.problem("badSignatureAlgorithm", protected.get("alg"))
        nonce = protected.get("nonce")
        with state.lock:
            known = nonce in state.nonces
            state.nonces.discard(nonce)
            if known and state.bad_nonce_left > 0:
                state.bad_nonce_left -= 1
                known = False
        if not known:
            return self.problem("badNonce", "the nonce is not one of this server")
        if protected.get("url") != state.base + self.path:
            return self.problem("unauthorized", "the url of the header is not the url of the request")
        if self.path == "/new-account":
            if "jwk" not in protected or "kid" in protected:
                return self.problem("malformed", "newAccount needs jwk and no kid")
            jwk = protected["jwk"]
        else:
            if protected.get("kid") != state.account or "jwk" in protected:
                return self.problem("malformed", "the kid is not the account")
            jwk = state.jwk
        signing_input = (body["protected"] + "." + payload_text).encode()
        if not verify_signature(jwk, signing_input, signature):
            return self.problem("malformed", "the signature does not verify")
        print("  the JWS holds", flush=True)
        payload = json.loads(b64url_decode(payload_text)) if payload_text else None
        if self.path == "/new-account":
            if payload.get("termsOfServiceAgreed") is not True:
                return self.problem("userActionRequired", "the terms are not agreed")
            state.jwk = jwk
            print("  account with contact %s" % payload.get("contact"), flush=True)
            self.send(201, json.dumps({"status": "valid"}).encode(), extra=[("Location", state.account)])
        elif self.path == "/new-order":
            state.names = [i["value"] for i in payload["identifiers"] if i["type"] == "dns"]
            print("  order for %s" % ",".join(state.names), flush=True)
            canonical = json.dumps({"crv": state.jwk["crv"], "kty": "EC", "x": state.jwk["x"], "y": state.jwk["y"]},
                                   separators=(",", ":"), sort_keys=True).encode()
            thumb = b64url(hashlib.sha256(canonical).digest())
            authorization = state.token + "." + thumb
            with open("expected-dns.txt", "w") as stream:
                stream.write(b64url(hashlib.sha256(authorization.encode()).digest()) + "\n")
            with open("expected-http.txt", "w") as stream:
                stream.write(authorization + "\n")
            self.send(201, json.dumps(state.order()).encode(), extra=[("Location", state.base + "/order/1")])
        elif self.path == "/authz/1":
            if payload is not None:
                return self.problem("malformed", "an authorization is fetched with POST-as-GET")
            body = {
                "status": "valid" if state.authorized else "pending",
                "identifier": {"type": "dns", "value": state.names[0]},
                "challenges": [
                    {"type": "http-01", "url": state.base + "/chall/http", "token": state.token, "status": "pending"},
                    {"type": "dns-01", "url": state.base + "/chall/dns", "token": state.token, "status": "pending"},
                ],
            }
            self.send(200, json.dumps(body).encode())
        elif self.path == "/chall/dns":
            if payload != {}:
                return self.problem("malformed", "a challenge is answered with {}")
            state.authorized = True
            print("  the dns-01 challenge is taken", flush=True)
            self.send(200, json.dumps({"type": "dns-01", "status": "valid"}).encode())
        elif self.path == "/finalize/1":
            if not state.authorized:
                return self.problem("orderNotReady", "not authorized")
            with open("request.der", "wb") as stream:
                stream.write(b64url_decode(payload["csr"]))
            if run(["openssl", "req", "-inform", "DER", "-in", "request.der", "-noout", "-verify"]).returncode != 0:
                return self.problem("badCSR", "the signature of the request does not verify")
            text = run(["openssl", "req", "-inform", "DER", "-in", "request.der", "-noout", "-text"]).stdout.decode()
            asked = sorted(part.strip()[4:] for line in text.splitlines() if "DNS:" in line for part in line.split(","))
            if asked != sorted(state.names):
                return self.problem("badCSR", "the request asks for %s" % ",".join(asked))
            done = run(["openssl", "x509", "-req", "-inform", "DER", "-in", "request.der", "-CA", "server-cert.pem",
                        "-CAkey", "server-key.pem", "-days", "1", "-copy_extensions", "copy", "-out", "issued.pem"])
            if done.returncode != 0:
                return self.problem("serverInternal", "openssl x509 -req failed")
            print("  the request asks for exactly the names of the order", flush=True)
            state.order_status = "valid"
            self.send(200, json.dumps(state.order()).encode())
        elif self.path == "/order/1":
            self.send(200, json.dumps(state.order()).encode())
        elif self.path == "/cert/1":
            with open("issued.pem", "rb") as stream:
                chain = stream.read()
            with open("server-cert.pem", "rb") as stream:
                chain += stream.read()
            self.send(200, chain, "application/pem-certificate-chain")
        else:
            self.send(404)


def main():
    with open("ca.cnf", "w") as stream:
        stream.write(CONFIG)
    done = run(["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-nodes",
                "-keyout", "server-key.pem", "-out", "server-cert.pem", "-days", "1", "-config", "ca.cnf"])
    if done.returncode != 0:
        sys.stderr.write("openssl req failed: %s\n" % done.stderr.decode("utf-8", "replace"))
        sys.exit(9)
    server = HTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    server.state = State("https://localhost:%d" % port)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain("server-cert.pem", "server-key.pem")
    server.socket = context.wrap_socket(server.socket, server_side=True)
    sys.stdout.write("%05d\n" % port)
    sys.stdout.flush()
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    sys.stdin.read()
    server.shutdown()
    print("served", flush=True)


if __name__ == "__main__":
    main()
