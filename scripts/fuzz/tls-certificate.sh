#!/bin/sh
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# The certificate of the relay that the fuzz readers smtp-implicit and
# smtp-starttls talk to:
#
#     sh scripts/fuzz/tls-certificate.sh <directory>
#
# It makes server-key.pem and server-cert.pem in the directory with openssl,
# a key on the curve prime256v1 and a certificate that signs itself, for the
# name localhost, good for two days, so that no private key lies in the tree
# and the programme can trust the certificate as its own authority.  The
# directory is the one that FUZZ_TLS_DIR names for the relay; the file
# server-cert.pem is the one that FUZZ_TLS_CA names for the programme.
#
# Exit 0 when both files are made, 9 when there is no directory, no openssl,
# or openssl made nothing: a certificate that was not made is not a refusal.
# POSIX sh.
set -u

[ $# -eq 1 ] && [ -d "$1" ] || { echo "usage: sh scripts/fuzz/tls-certificate.sh <directory>" >&2; exit 9; }
command -v openssl > /dev/null 2>&1 || { echo "tls-certificate: openssl is not on PATH" >&2; exit 9; }
T=$1
printf '%s\n' '[req]' 'distinguished_name = dn' 'x509_extensions = v3' 'prompt = no' \
	'[dn]' 'CN = localhost' \
	'[v3]' 'basicConstraints = critical,CA:TRUE' 'keyUsage = digitalSignature,keyCertSign' \
	'subjectAltName = DNS:localhost' > "$T/server.cnf" || { echo "tls-certificate: cannot write in $T" >&2; exit 9; }
if ! openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
	-keyout "$T/server-key.pem" -out "$T/server-cert.pem" -days 2 -config "$T/server.cnf" > "$T/openssl.log" 2>&1; then
	echo "tls-certificate: openssl made no certificate; the first lines:" >&2
	head -n 5 "$T/openssl.log" >&2
	exit 9
fi
[ -s "$T/server-key.pem" ] && [ -s "$T/server-cert.pem" ] || { echo "tls-certificate: a file is empty" >&2; exit 9; }
echo "tls-certificate: $T/server-cert.pem and $T/server-key.pem"
exit 0
