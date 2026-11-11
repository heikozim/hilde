/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The working memory of libargon2 and the check of a bcrypt hash.
 */

#include "internal.h"

/* The working memory of libargon2, which Bindings.Argon2 hands it through
   allocate_cbk and free_cbk: two blocks are kept and handed out again, so
   that a hash does not fault in 64 MiB of new pages each time.  libargon2
   wipes the memory before it gives it back.

   Ownership: one lock guards the table of kept blocks, and the table is
   read and written nowhere else, so no thread sees a half-written slot.
   The thread that takes a slot with the lock keeps its block until it
   gives the block back under the lock, and only that thread reads and
   writes the block's bytes.  A kept block is never given back to malloc,
   so its address belongs to its slot for the life of the process and
   malloc cannot hand that address out again: the free finds the slot by
   the address alone, and the lock makes the match and the clearing of the
   taken flag one step.  A request for a size a slot does not hold, and a
   request while both slots are taken, takes memory from malloc and gives
   it back to free.  The lock is held over a few instructions, and the
   first time a slot is filled over its malloc as well. */
#define HILDE_ARGON2_KEPT 2

struct hilde_argon2_kept {
  uint8_t* memory;  /* NULL until the first request fills the slot */
  size_t bytes;     /* the size the block was made with */
  int taken;        /* one while one thread holds the block */
};

static struct hilde_argon2_kept hilde_argon2_kept[HILDE_ARGON2_KEPT];
static int hilde_argon2_table_lock;

/* Takes the lock of the table; hilde_argon2_unlock_table gives it back. */
static void hilde_argon2_lock_table(void) {
  int expected = 0;

  while (!__atomic_compare_exchange_n(&hilde_argon2_table_lock, &expected, 1, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
    expected = 0;
  }
}

static void hilde_argon2_unlock_table(void) {
  __atomic_store_n(&hilde_argon2_table_lock, 0, __ATOMIC_RELEASE);
}

int hilde_argon2_allocate(uint8_t** memory, size_t bytes) {
  extern void* malloc(size_t size);
  int i;

  hilde_argon2_lock_table();
  for (i = 0; i < HILDE_ARGON2_KEPT; i++) {
    struct hilde_argon2_kept* kept = &hilde_argon2_kept[i];

    if (kept->taken) {
      continue;
    }
    if (kept->memory == NULL) {
      kept->memory = (uint8_t*) malloc(bytes);
      if (kept->memory == NULL) {
        continue;
      }
      kept->bytes = bytes;
    }
    if (kept->bytes != bytes) {
      continue;
    }
    kept->taken = 1;
    *memory = kept->memory;
    hilde_argon2_unlock_table();
    return 0;
  }
  hilde_argon2_unlock_table();
  *memory = (uint8_t*) malloc(bytes);
  return (*memory == NULL) ? -1 : 0;
}

void hilde_argon2_free(uint8_t* memory, size_t bytes) {
  extern void free(void* ptr);
  int i;

  (void) bytes;
  if (memory == NULL) {
    return;
  }
  hilde_argon2_lock_table();
  for (i = 0; i < HILDE_ARGON2_KEPT; i++) {
    if (hilde_argon2_kept[i].memory == memory) {
      /* The taker gives the slot back.  The block stays in the slot and
         never passes to free, so no other allocation can have this
         address. */
      hilde_argon2_kept[i].taken = 0;
      hilde_argon2_unlock_table();
      return;
    }
  }
  hilde_argon2_unlock_table();
  free(memory);
}


/* Checks a password against a bcrypt hash.  A bcrypt hash is only ever
   checked here, never made: an old hash is checked through the system's
   own library, so that a programme can store the password again with
   Argon2id.  That library is crypt_checkpass of OpenBSD's libc, and
   crypt_rn of libxcrypt on Linux, which Bindings.Bcrypt links there and
   nowhere else, and crypt_r of libcrypt on FreeBSD.  The C library of
   macOS has only the old form of crypt with a two-letter salt and neither
   function, so there
   every check answers -1.

   Static, and unused in a programme that does not call it: then it is not
   emitted and references neither function, so a programme without
   Bindings.Bcrypt does not need libxcrypt.  This holds with gcc 14 and
   clang 19; the attribute keeps clang from warning about the unused
   function.

   Both texts come as spans without a terminating zero, and a copy with one
   is made for C.  A password holding a zero byte does not match: C would
   read it only up to that byte.  Returns 1 when the password matches, 0
   when it does not, and -1 when it cannot be checked: no library, no
   memory, a hash the library does not take. */
static inline __attribute__((unused))
hilde_int32_t hilde_bcrypt_check(hilde_span_t password, hilde_span_t hash) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);

  if (password.size > 0 && memchr(password.data, 0, password.size) != NULL) {
    return 0;
  }
  if (hash.size == 0 || memchr(hash.data, 0, hash.size) != NULL) {
    return -1;
  }
  char* pw = calloc(password.size + 1, 1);
  char* stored = calloc(hash.size + 1, 1);
  if (pw == NULL || stored == NULL) {
    free(pw);
    free(stored);
    return -1;
  }
  if (password.size > 0) {
    memcpy(pw, password.data, password.size);
  }
  memcpy(stored, hash.data, hash.size);
  hilde_int32_t result = -1;
#if defined(__OpenBSD__)
  {
    extern int crypt_checkpass(const char* password, const char* hash);

    /* -1 with EACCES is a password that does not match; -1 with any other
       errno is a hash the library cannot check. */
    if (crypt_checkpass(pw, stored) == 0) {
      result = 1;
    } else if (errno == EACCES) {
      result = 0;
    }
  }
#elif defined(__linux__)
  {
    extern char* crypt_rn(const char* phrase, const char* setting, void* data, int size);
    /* sizeof (struct crypt_data) in libxcrypt 4.4.38.  A later libxcrypt
       that wants more answers NULL, which is -1 here and not a wrong
       answer. */
    const int data_size = 32768;
    void* data = calloc(1, (size_t) data_size);

    if (data != NULL) {
      const char* made = crypt_rn(pw, stored, data, data_size);

      if (made != NULL) {
        size_t made_size = strlen(made);
        size_t common = made_size < hash.size ? made_size : hash.size;
        unsigned char differ = (made_size == hash.size) ? 0 : 1;

        for (size_t i = 0; i < common; i++) {
          differ |= (unsigned char) (made[i] ^ stored[i]);
        }
        result = (differ == 0) ? 1 : 0;
      }
      hilde_wipe(data, (size_t) data_size);
      free(data);
    }
  }
#elif defined(__FreeBSD__)
  {
    /* FreeBSD's libcrypt (linked with -lcrypt) hashes the phrase under the
       stored hash as its setting and answers the hash that comes out;
       unistd.h declares crypt_r and its struct crypt_data.  An answer of
       NULL is -1 and not a wrong answer. */
    struct crypt_data data;
    const char* made;

    memset(&data, 0, sizeof data);
    made = crypt_r(pw, stored, &data);
    if (made != NULL) {
      size_t made_size = strlen(made);
      size_t common = made_size < hash.size ? made_size : hash.size;
      unsigned char differ = (made_size == hash.size) ? 0 : 1;

      for (size_t i = 0; i < common; i++) {
        differ |= (unsigned char) (made[i] ^ stored[i]);
      }
      result = (differ == 0) ? 1 : 0;
    }
    hilde_wipe(&data, sizeof data);
  }
#endif
  hilde_wipe(pw, password.size + 1);
  free(pw);
  free(stored);
  return result;
}
