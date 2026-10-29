#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The certificates of a test of mutual TLS, made with openssl in a
# directory, so that no private key lies in the tree:
#
#     sh scripts/tls/mutual-certificates.sh <directory>
#
# ca.pem       an authority that signs the two below, CN Hilde Test CA
# server.pem   the server's certificate for localhost, key server-key.pem
# client.pem   a client's certificate, CN client.example, key client-key.pem
# stranger.pem a client certificate that signs itself, CN stranger.example,
#              key stranger-key.pem: no certificate of ca.pem
#
# Keys on the curve prime256v1, certificates good for two days.  Exit 0
# when every file is made, 9 when there is no directory, no openssl, or
# openssl failed: a certificate that was not made is not a refusal.
# POSIX sh.
set -u

[ $# -eq 1 ] && [ -d "$1" ] || { echo "usage: sh scripts/tls/mutual-certificates.sh <directory>" >&2; exit 9; }
command -v openssl > /dev/null 2>&1 || { echo "mutual-certificates: openssl is not on PATH" >&2; exit 9; }
T=$1
L=$T/openssl.log
: > "$L" || { echo "mutual-certificates: cannot write in $T" >&2; exit 9; }

fail() {
	echo "mutual-certificates: $1; the last lines of openssl:" >&2
	tail -n 5 "$L" >&2
	exit 9
}

newkey() {
	openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out "$1" >> "$L" 2>&1 || fail "no key $1"
}

printf '%s\n' 'basicConstraints = critical,CA:TRUE' 'keyUsage = critical,keyCertSign,cRLSign' > "$T/ca.ext"
printf '%s\n' 'basicConstraints = critical,CA:FALSE' 'keyUsage = critical,digitalSignature' \
	'extendedKeyUsage = serverAuth' 'subjectAltName = DNS:localhost' > "$T/server.ext"
printf '%s\n' 'basicConstraints = critical,CA:FALSE' 'keyUsage = critical,digitalSignature' \
	'extendedKeyUsage = clientAuth' > "$T/client.ext"

newkey "$T/ca-key.pem"
openssl req -new -key "$T/ca-key.pem" -subj "/CN=Hilde Test CA" -out "$T/ca.csr" >> "$L" 2>&1 || fail "no request for the CA"
openssl x509 -req -in "$T/ca.csr" -signkey "$T/ca-key.pem" -days 2 -extfile "$T/ca.ext" -out "$T/ca.pem" >> "$L" 2>&1 || fail "no CA"

# signed <name> <subject>: a key and a certificate of ca.pem.
signed() {
	newkey "$T/$1-key.pem"
	openssl req -new -key "$T/$1-key.pem" -subj "$2" -out "$T/$1.csr" >> "$L" 2>&1 || fail "no request for $1"
	openssl x509 -req -in "$T/$1.csr" -CA "$T/ca.pem" -CAkey "$T/ca-key.pem" -CAcreateserial -days 2 \
		-extfile "$T/$3.ext" -out "$T/$1.pem" >> "$L" 2>&1 || fail "no certificate for $1"
}
signed server "/CN=localhost" server
signed client "/CN=client.example" client

newkey "$T/stranger-key.pem"
openssl req -new -key "$T/stranger-key.pem" -subj "/CN=stranger.example" -out "$T/stranger.csr" >> "$L" 2>&1 || fail "no request for the stranger"
openssl x509 -req -in "$T/stranger.csr" -signkey "$T/stranger-key.pem" -days 2 -extfile "$T/client.ext" -out "$T/stranger.pem" >> "$L" 2>&1 || fail "no stranger"

for f in ca.pem server.pem server-key.pem client.pem client-key.pem stranger.pem stranger-key.pem; do
	[ -s "$T/$f" ] || { echo "mutual-certificates: $T/$f is empty" >&2; exit 9; }
done
echo "mutual-certificates: seven files in $T"
