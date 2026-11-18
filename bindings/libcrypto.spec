# The OpenSSL functions Standard.Libcrypto calls, read
# from the copy of the headers in fixtures/ (scripts/crypto/check-header.sh
# holds that copy against the real headers).  Only Bindings.Libcrypto
# should import the generated module.
module     Bindings.C.Libcrypto
header     fixtures/libcrypto.h
output     generated/Libcrypto
library    crypto
# __owur stands before most declarations and is empty here; the
# preprocessor takes it off.
preprocess yes
opaque     EVP_CIPHER
opaque     EVP_CIPHER_CTX
opaque     EVP_MD
opaque     EVP_MD_CTX
opaque     EVP_PKEY
opaque     EVP_PKEY_CTX
opaque     ENGINE
# Every number OpenSSL defines comes from the system header of the
# machine that compiles the program, never from the copy in fixtures/:
# OpenSSL 3.5.7 numbers X25519 1034 and Ed25519 1087, LibreSSL 4.3.0 950 and
# 952.  EVP_PKEY_X25519 and EVP_PKEY_ED25519 are the names the key functions
# document for their `type' argument; both headers define them as the NID.
system-header   openssl/evp.h
# OpenSSL_version and OPENSSL_VERSION are declared in crypto.h, which evp.h
# does not include itself.
system-header   openssl/crypto.h
system-constant OPENSSL_VERSION Int32
system-constant EVP_CTRL_AEAD_SET_IVLEN Int32
system-constant EVP_CTRL_AEAD_GET_TAG Int32
system-constant EVP_CTRL_AEAD_SET_TAG Int32
system-constant EVP_PKEY_X25519 Int32
system-constant EVP_PKEY_ED25519 Int32
function   EVP_CIPHER_CTX_new
function   EVP_CIPHER_CTX_free
function   EVP_CIPHER_CTX_ctrl
function   EVP_aes_256_gcm
function   EVP_chacha20_poly1305
function   EVP_EncryptInit_ex
function   EVP_EncryptUpdate
function   EVP_EncryptFinal_ex
function   EVP_DecryptInit_ex
function   EVP_DecryptUpdate
function   EVP_DecryptFinal_ex
function   EVP_PKEY_new_raw_private_key
function   EVP_PKEY_new_raw_public_key
function   EVP_PKEY_get_raw_public_key
function   EVP_PKEY_free
function   EVP_PKEY_CTX_new
function   EVP_PKEY_CTX_free
function   EVP_PKEY_derive_init
function   EVP_PKEY_derive_set_peer
function   EVP_PKEY_derive
function   EVP_MD_CTX_new
function   EVP_MD_CTX_free
function   EVP_DigestSignInit
function   EVP_DigestSign
function   EVP_DigestVerifyInit
function   EVP_DigestVerify
# Bytes from the library's own secure random source, for
# the salts of password hashes.  LibreSSL takes them from arc4random.
function   RAND_bytes
# SHA-256 and HMAC-SHA256, one call each.
function   EVP_sha256
# SHA-384, SHA-512, SHA3-256 and SHA3-512, and HMAC
# with each, through the same two calls.
function   EVP_sha384
function   EVP_sha512
function   EVP_sha3_256
function   EVP_sha3_512
function   EVP_Digest
function   HMAC
# SHA-1 for HMAC-SHA1 only, which HOTP and TOTP name (RFC 4226,
# RFC 6238); no plain SHA-1 digest is offered.
function   EVP_sha1
# The version the programme runs with, for version --full.
function   OpenSSL_version
