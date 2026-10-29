/*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   The three functions below follow libcrux-mlkem-mldsa.c of OpenSSH:

   Copyright (c) 2026 Damien Miller <djm@mindrot.org>

   Permission to use, copy, modify, and distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

/* ML-DSA of FIPS 204 from libcrux, written into a programme only when it
   compiles Bindings.MlDsa.  The text of vendor/libcrux/libcrux_internal.h
   takes the place of the include line below when the compiler is built.
   It needs the fixed-width integers, bool, memcpy and memcmp, which the
   prelude above has brought in, and the four names defined here first.
   Randomness is never drawn here: the seed of a key and the 32 bytes of
   a signature come from the caller, so that every result can be checked
   against fixed vectors. */
#include <stdbool.h>

/* libcrux stops through this on an internal error it cannot return. */
#define fatal_f(message) hilde_stop(message)


/* libcrux turns a word into big-endian bytes with htobe32, which not
   every system declares; this one does it byte by byte. */
static inline uint32_t hilde_mldsa_htobe32(uint32_t value) {
  uint8_t bytes[4] = { (uint8_t) (value >> 24), (uint8_t) (value >> 16), (uint8_t) (value >> 8), (uint8_t) value };
  uint32_t word;

  memcpy(&word, bytes, sizeof word);
  return word;
}
#undef htobe32
#define htobe32 hilde_mldsa_htobe32

/* gcc at -O2 leaves the arithmetic of libcrux slow, its verification at a
   quarter of the speed clang gives at -O2; -O3 for this text alone brings
   it level.  clang reads no optimize pragma and needs none. */
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC push_options
#pragma GCC optimize ("O3")
#endif

/* The generated code leaves parameters unused that its pattern of calls
   requires and defines helpers this programme does not call; those two
   warnings are silenced for that text alone.  Its pragma once is left out
   when the text takes the place of the include below. */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"

/* libcrux boxes nothing on the paths used here; a box would mean heap
   memory the caller does not wipe, so it is refused. */
static void* hilde_mldsa_no_heap(size_t size) {
  (void) size;
  return NULL;
}

static void* hilde_mldsa_no_heap_again(void* old, size_t size) {
  (void) old;
  (void) size;
  return NULL;
}

#define EURYDICE_MALLOC hilde_mldsa_no_heap
#define EURYDICE_REALLOC hilde_mldsa_no_heap_again

/* cppcheck reports three things in the generated text that are no
   faults: the dead inner test of the rejection sampling loops, which the
   translation from Rust writes inside the branch that already decided it;
   the right shift of a signed 32-bit word by 31 to take its sign, which C
   leaves to the implementation, not undefined, and every compiler here
   makes arithmetic; and load16_le, declared with a parameter of four
   bytes, called on an array of two, of which it reads two.  Those three
   ids are silenced for that text alone. */
/* cppcheck-suppress-begin oppositeInnerCondition */
/* cppcheck-suppress-begin shiftTooManyBitsSigned */
/* cppcheck-suppress-begin argumentSize */
#include "libcrux_internal.h"
/* cppcheck-suppress-end argumentSize */
/* cppcheck-suppress-end shiftTooManyBitsSigned */
/* cppcheck-suppress-end oppositeInnerCondition */
#pragma GCC diagnostic pop

/* The most stack each function needs, measured on a painted stack with
   gcc and clang at -O2 and -O3 and rounded up with room for the frames
   that called it: 256 KiB, and for a signature 384 KiB at level 65 and
   576 KiB at level 87.  In a task with less stack left the function
   refuses, rather than run over the guard pages. */
static int hilde_mldsa_stack_suffices(int32_t level, int signing) {
  size_t need = 256u * 1024u;

  if (signing && level == 65) {
    need = 384u * 1024u;
  }
  if (signing && level == 87) {
    need = 576u * 1024u;
  }
  return hilde_task_stack_left() >= need;
}

/* The sizes of FIPS 204 for the three parameter sets, by level 44, 65 or
   87; 0 for any other level. */
size_t hilde_mldsa_public_bytes(int32_t level) {
  return level == 44 ? 1312 : level == 65 ? 1952 : level == 87 ? 2592 : 0;
}

size_t hilde_mldsa_secret_bytes(int32_t level) {
  return level == 44 ? 2560 : level == 65 ? 4032 : level == 87 ? 4896 : 0;
}

size_t hilde_mldsa_signature_bytes(int32_t level) {
  return level == 44 ? 2420 : level == 65 ? 3309 : level == 87 ? 4627 : 0;
}

/* ML-DSA.KeyGen_internal of FIPS 204: the public and the expanded secret
   key of seed, 32 bytes, into pk and sk of the level's sizes.  1 when
   made, 0 for an unknown level or too little stack. */
int32_t hilde_mldsa_keypair(int32_t level, const uint8_t* seed, uint8_t* pk, uint8_t* sk) {
  if (!hilde_mldsa_stack_suffices(level, 0)) {
    return 0;
  }
#define HILDE_MLDSA_KEYPAIR(L)                                                  \
  do {                                                                          \
    libcrux_mldsa##L##_keypair_rnd rnd;                                         \
    libcrux_mldsa##L##_keypair made;                                            \
    memcpy(rnd.data, seed, sizeof(rnd.data));                                   \
    made = libcrux_ml_dsa_ml_dsa_##L##_portable_generate_key_pair(rnd);         \
    memcpy(pk, made.verification_key.data, sizeof(made.verification_key.data)); \
    memcpy(sk, made.signing_key.data, sizeof(made.signing_key.data));           \
    hilde_wipe(&made, sizeof(made));                                            \
    hilde_wipe(&rnd, sizeof(rnd));                                              \
    return 1;                                                                   \
  } while (0)
  if (level == 44) HILDE_MLDSA_KEYPAIR(44);
  if (level == 65) HILDE_MLDSA_KEYPAIR(65);
  if (level == 87) HILDE_MLDSA_KEYPAIR(87);
#undef HILDE_MLDSA_KEYPAIR
  return 0;
}

/* ML-DSA.Sign of FIPS 204, the pure form with a context of at most 255
   bytes: the signature of msg under the expanded secret key sk into sig,
   with rnd, 32 bytes, as the randomness; 32 zero bytes give the
   deterministic variant.  1 when signed, 0 for an unknown level, a
   context that is too long, too little stack or a refusal of libcrux. */
int32_t hilde_mldsa_sign(int32_t level, const uint8_t* sk, const uint8_t* msg, size_t msglen,
                         const uint8_t* ctx, size_t ctxlen, const uint8_t* rnd, uint8_t* sig) {
  if (ctxlen > 255 || !hilde_mldsa_stack_suffices(level, 1)) {
    return 0;
  }
#define HILDE_MLDSA_SIGN(L)                                                     \
  do {                                                                          \
    libcrux_mldsa##L##_sign_rnd randomness;                                     \
    libcrux_mldsa##L##_sk secret;                                               \
    libcrux_mldsa##L##_message message = { msg, msglen };                       \
    libcrux_mldsa##L##_message context = { ctx, ctxlen };                       \
    libcrux_mldsa##L##_sign_result result;                                      \
    int32_t ok = 0;                                                             \
    memcpy(secret.data, sk, sizeof(secret.data));                               \
    memcpy(randomness.data, rnd, sizeof(randomness.data));                      \
    result = libcrux_ml_dsa_ml_dsa_##L##_portable_sign(&secret, message,        \
                                                       context, randomness);    \
    if (result.tag == LIBCRUX_RESULT_OK) {                                      \
      memcpy(sig, result.val.case_Ok.data, sizeof(result.val.case_Ok.data));    \
      ok = 1;                                                                   \
    }                                                                           \
    hilde_wipe(&secret, sizeof(secret));                                        \
    hilde_wipe(&result, sizeof(result));                                        \
    hilde_wipe(&randomness, sizeof(randomness));                                \
    return ok;                                                                  \
  } while (0)
  if (level == 44) HILDE_MLDSA_SIGN(44);
  if (level == 65) HILDE_MLDSA_SIGN(65);
  if (level == 87) HILDE_MLDSA_SIGN(87);
#undef HILDE_MLDSA_SIGN
  return 0;
}

/* ML-DSA.Verify of FIPS 204, the pure form: 1 when sig is a signature of
   msg with the context ctx under the public key pk, 0 otherwise, also for
   an unknown level, a context over 255 bytes or too little stack. */
int32_t hilde_mldsa_verify(int32_t level, const uint8_t* pk, const uint8_t* msg, size_t msglen,
                           const uint8_t* ctx, size_t ctxlen, const uint8_t* sig) {
  if (ctxlen > 255 || !hilde_mldsa_stack_suffices(level, 0)) {
    return 0;
  }
#define HILDE_MLDSA_VERIFY(L)                                                   \
  do {                                                                          \
    libcrux_mldsa##L##_pk key;                                                  \
    libcrux_mldsa##L##_signature signature;                                     \
    libcrux_mldsa##L##_message message = { msg, msglen };                       \
    libcrux_mldsa##L##_message context = { ctx, ctxlen };                       \
    libcrux_mldsa##L##_verify_result result;                                    \
    memcpy(key.data, pk, sizeof(key.data));                                     \
    memcpy(signature.data, sig, sizeof(signature.data));                        \
    result = libcrux_ml_dsa_ml_dsa_##L##_portable_verify(&key, message,         \
                                                         context, &signature);  \
    return result.tag == LIBCRUX_RESULT_OK ? 1 : 0;                             \
  } while (0)
  if (level == 44) HILDE_MLDSA_VERIFY(44);
  if (level == 65) HILDE_MLDSA_VERIFY(65);
  if (level == 87) HILDE_MLDSA_VERIFY(87);
#undef HILDE_MLDSA_VERIFY
  return 0;
}

#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC pop_options
#endif
