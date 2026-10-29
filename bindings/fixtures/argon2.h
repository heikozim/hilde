/*
** The part of libargon2's argon2.h that Bindings.Argon2 binds.
**
** The declarations are copied from /usr/include/argon2.h of the Argon2
** reference implementation, release 20190702 (Debian libargon2-dev
** 0~20190702+dfsg-4+b2), with the header's line numbers above each.  The
** reference implementation is Copyright 2015 Daniel Dinu, Dmitry
** Khovratovich, Jean-Philippe Aumasson and Samuel Neves, under CC0 1.0 or the
** Apache License 2.0; these are its declarations, quoted for the binding
** generator.
**
** Two differences, and C sees neither.  The header writes ARGON2_PUBLIC in
** front of each function; it expands to nothing unless A2_VISCTL is
** defined, and it is left out here.  The header defines the structure
** argon2_context with its fields; scripts/gen-bindings.py names an opaque
** type by a typedef name and needs no fields, so this file has the typedef
** alone.  C takes a typedef twice when both name the same type, and a
** prototype twice when both say the same: scripts/argon2/check-header.sh
** compiles this file together with a real argon2.h.
*/
#include <stdint.h>
#include <stddef.h>

/* argon2.h lines 191 and 218, the structure's tag and its typedef name */
typedef struct Argon2_Context argon2_context;

/* argon2.h lines 314-319 */
int argon2id_hash_raw(const uint32_t t_cost,
                                    const uint32_t m_cost,
                                    const uint32_t parallelism, const void *pwd,
                                    const size_t pwdlen, const void *salt,
                                    const size_t saltlen, void *hash,
                                    const size_t hashlen);

/* argon2.h line 379 */
int argon2id_ctx(argon2_context *context);
