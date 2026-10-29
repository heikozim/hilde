/*
** The part of OpenSSL's libcrypto headers that Standard.Libcrypto binds.
**
** Every declaration below is copied word for word from the
** headers of OpenSSL 3.5.7 (Debian libssl-dev 3.5.7-1~deb13u2), with the
** header and line number in the comment above it.  OpenSSL is Copyright
** The OpenSSL Project Authors and licensed under the Apache License 2.0;
** these are its declarations, quoted for the binding generator.
**
** Why a copy: the checks of this repository read no file of the machine
** they run on, and the container image they run in has no OpenSSL headers.
** scripts/crypto/check-header.sh compiles this file together with the real
** headers, and C accepts a declaration, a typedef or a macro twice only
** when both say the same.
*/
#ifndef __owur
/* e_os2.h line 217 */
# define __owur
#endif

/* types.h lines 110-122, 197 */
typedef struct evp_cipher_st EVP_CIPHER;
typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
typedef struct evp_md_st EVP_MD;
typedef struct evp_md_ctx_st EVP_MD_CTX;
typedef struct evp_pkey_st EVP_PKEY;
typedef struct evp_pkey_ctx_st EVP_PKEY_CTX;
typedef struct engine_st ENGINE;

/* No #define of OpenSSL's is copied here: the numbers differ between
   OpenSSL and LibreSSL, so the binding takes each one from the system
   header when the program is compiled, through the system-constant lines of
   ../libcrypto.spec. */

/* evp.h lines 714-716 */
EVP_MD_CTX *EVP_MD_CTX_new(void);
void EVP_MD_CTX_free(EVP_MD_CTX *ctx);

/* evp.h lines 733-735 */
__owur int EVP_Digest(const void *data, size_t count,
    unsigned char *md, unsigned int *size,
    const EVP_MD *type, ENGINE *impl);

/* evp.h lines 772-802 */
__owur int EVP_EncryptInit_ex(EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *cipher, ENGINE *impl,
    const unsigned char *key,
    const unsigned char *iv);
__owur int EVP_EncryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl, const unsigned char *in, int inl);
__owur int EVP_EncryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl);
__owur int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *cipher, ENGINE *impl,
    const unsigned char *key,
    const unsigned char *iv);
__owur int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl, const unsigned char *in, int inl);
__owur int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *outm,
    int *outl);

/* evp.h lines 847-859 */
__owur int EVP_DigestSign(EVP_MD_CTX *ctx, unsigned char *sigret,
    size_t *siglen, const unsigned char *tbs,
    size_t tbslen);
__owur int EVP_DigestVerify(EVP_MD_CTX *ctx, const unsigned char *sigret,
    size_t siglen, const unsigned char *tbs,
    size_t tbslen);

/* evp.h lines 865-878 */
__owur int EVP_DigestSignInit(EVP_MD_CTX *ctx, EVP_PKEY_CTX **pctx,
    const EVP_MD *type, ENGINE *e,
    EVP_PKEY *pkey);
__owur int EVP_DigestVerifyInit(EVP_MD_CTX *ctx, EVP_PKEY_CTX **pctx,
    const EVP_MD *type, ENGINE *e,
    EVP_PKEY *pkey);

/* evp.h lines 913-918 */
EVP_CIPHER_CTX *EVP_CIPHER_CTX_new(void);
void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *c);
int EVP_CIPHER_CTX_ctrl(EVP_CIPHER_CTX *ctx, int type, int arg, void *ptr);

/* evp.h line 955 */
const EVP_MD *EVP_sha1(void);

/* evp.h lines 957-959 */
const EVP_MD *EVP_sha256(void);
const EVP_MD *EVP_sha384(void);
const EVP_MD *EVP_sha512(void);

/* evp.h lines 963 and 965 */
const EVP_MD *EVP_sha3_256(void);
const EVP_MD *EVP_sha3_512(void);

/* evp.h line 1096 */
const EVP_CIPHER *EVP_aes_256_gcm(void);

/* evp.h line 1168 */
const EVP_CIPHER *EVP_chacha20_poly1305(void);

/* evp.h line 1431 */
void EVP_PKEY_free(EVP_PKEY *pkey);

/* evp.h lines 1855-1863 */
EVP_PKEY_CTX *EVP_PKEY_CTX_new(EVP_PKEY *pkey, ENGINE *e);
void EVP_PKEY_CTX_free(EVP_PKEY_CTX *ctx);

/* evp.h lines 1896-1908 */
EVP_PKEY *EVP_PKEY_new_raw_private_key(int type, ENGINE *e,
    const unsigned char *priv,
    size_t len);
EVP_PKEY *EVP_PKEY_new_raw_public_key(int type, ENGINE *e,
    const unsigned char *pub,
    size_t len);
int EVP_PKEY_get_raw_public_key(const EVP_PKEY *pkey, unsigned char *pub,
    size_t *len);

/* evp.h lines 2024-2029 */
int EVP_PKEY_derive_init(EVP_PKEY_CTX *ctx);
int EVP_PKEY_derive_set_peer(EVP_PKEY_CTX *ctx, EVP_PKEY *peer);
int EVP_PKEY_derive(EVP_PKEY_CTX *ctx, unsigned char *key, size_t *keylen);

/* hmac.h lines 54-56 */
unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
    const unsigned char *data, size_t data_len,
    unsigned char *md, unsigned int *md_len);

/* rand.h line 63 */
int RAND_bytes(unsigned char *buf, int num);

/* crypto.h line 166; its argument, OPENSSL_VERSION, comes from the system
   header like every number of OpenSSL's */
const char *OpenSSL_version(int type);
