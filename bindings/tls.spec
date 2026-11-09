# The libtls functions Standard.Tls calls, read from the
# copy in fixtures/ (scripts/tls/check-header.sh holds it against the real
# tls.h).  Only Standard.Tls should import the generated module.
module     Bindings.C.Tls
header     fixtures/tls.h
output     generated/Tls
# The library's file name; Debian's pkg-config calls it libtls, and the
# compiler and the runner ask for that too.  OpenBSD has libtls in
# the base system and no .pc file: -ltls.
library    tls
opaque     tls_t
opaque     tls_config_t
# tls_read and tls_write answer these when they must be called again: on
# the blocking socket tls_connect makes as well (measured:
# suite 052 failed when the answer was taken as a failure; a record that
# holds no data, such as a session ticket of TLS 1.3, is a likely cause,
# not a measured one), and on the non-blocking socket of
# tls_connect_socket whenever the socket has nothing to give or take.
constant   TLS_WANT_POLLIN Int64
constant   TLS_WANT_POLLOUT Int64
# The version a Sperli connection is limited to: 1.3 only.
constant   TLS_PROTOCOL_TLSv1_3 Int64
function   tls_init
function   tls_config_error
function   tls_error
function   tls_config_new
function   tls_config_free
function   tls_config_set_ca_file
function   tls_client
function   tls_configure
function   tls_free
function   tls_connect
function   tls_connect_socket
function   tls_handshake
function   tls_read
function   tls_write
function   tls_close
# The server side, a key pair from files or from memory and a
# connection accepted over a socket the caller accepted.
function   tls_config_set_keypair_file
function   tls_config_set_keypair_mem
function   tls_server
function   tls_accept_socket
# Mutual TLS: a server that asks the client for a certificate and verifies
# it against a CA, from a file or from memory, and what a connection knows
# of its peer's certificate.
function   tls_config_set_ca_mem
function   tls_config_verify_client
function   tls_peer_cert_provided
function   tls_peer_cert_hash
function   tls_peer_cert_subject
# The protocols a configuration allows; Standard.Tls limits a connection to 1.3 with it.
function   tls_config_set_protocols
