/*
** The part of libtls's tls.h that Standard.Tls binds.
**
** The declarations are copied from /usr/include/tls.h of libretls 3.8.1
** (Debian libtls-dev 3.8.1-2.1+b2), TLS_API 20200120, with the header's line
** number above each -- the same interface as OpenBSD's own libtls, whose
** tls.h says TLS_API 20200120 as well.  libtls is Copyright Joel Sing and
** Ted Unangst and licensed under the ISC licence; these are its
** declarations, quoted for the binding generator.
**
** One change, and it is not one C can see: the header writes struct tls
** and struct tls_config, and scripts/gen-bindings.py names an opaque type
** by a typedef name, so the two typedefs below are this file's own and the
** prototypes use them.  A typedef is another name for the same type, so a
** prototype here still has to be the header's prototype, exactly:
** scripts/tls/check-header.sh compiles this file together with a real
** tls.h, and C accepts a declaration twice only when both say the same.
*/
#include <sys/types.h>
#include <stddef.h>
#include <stdint.h>

/* this file's own names for the header's two structures */
typedef struct tls tls_t;
typedef struct tls_config tls_config_t;

/* tls.h lines 55-56 */
#define TLS_WANT_POLLIN		-2
#define TLS_WANT_POLLOUT	-3
#define TLS_PROTOCOL_TLSv1_3	(1 << 4)

/* tls.h line 94 */
int tls_init(void);

/* tls.h line 107 */
int tls_config_set_protocols(tls_config_t *_config, uint32_t _protocols);

/* tls.h lines 96-97 */
const char *tls_config_error(tls_config_t *_config);
const char *tls_error(tls_t *_ctx);

/* tls.h lines 99-100 */
tls_config_t *tls_config_new(void);
void tls_config_free(tls_config_t *_config);

/* tls.h line 115 */
int tls_config_set_ca_file(tls_config_t *_config, const char *_ca_file);
/* tls.h lines 117-118 */
int tls_config_set_ca_mem(tls_config_t *_config, const uint8_t *_ca,
    size_t _len);

/* tls.h lines 133-136 */
int tls_config_set_keypair_file(tls_config_t *_config,
    const char *_cert_file, const char *_key_file);
int tls_config_set_keypair_mem(tls_config_t *_config, const uint8_t *_cert,
    size_t _cert_len, const uint8_t *_key, size_t _key_len);

/* tls.h line 159 */
void tls_config_verify_client(tls_config_t *_config);
/* tls.h lines 171-173, 175 */
tls_t *tls_client(void);
tls_t *tls_server(void);
int tls_configure(tls_t *_ctx, tls_config_t *_config);
void tls_free(tls_t *_ctx);

/* tls.h line 179 */
int tls_accept_socket(tls_t *_ctx, tls_t **_cctx, int _socket);

/* tls.h line 182 */
int tls_connect(tls_t *_ctx, const char *_host, const char *_port);

/* tls.h line 187 */
int tls_connect_socket(tls_t *_ctx, int _s, const char *_servername);

/* tls.h lines 190-193 */
int tls_handshake(tls_t *_ctx);
ssize_t tls_read(tls_t *_ctx, void *_buf, size_t _buflen);
ssize_t tls_write(tls_t *_ctx, const void *_buf, size_t _buflen);
int tls_close(tls_t *_ctx);
/* tls.h line 195 */
int tls_peer_cert_provided(tls_t *_ctx);
/* tls.h line 198 */
const char *tls_peer_cert_hash(tls_t *_ctx);
/* tls.h line 200 */
const char *tls_peer_cert_subject(tls_t *_ctx);
