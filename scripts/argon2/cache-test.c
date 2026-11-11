/*
    Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/* The working memory cache of libargon2 under several threads, never part
   of a programme.  Every thread takes memory with hilde_argon2_allocate,
   writes over it and gives it back with hilde_argon2_free, asking for three
   sizes one after the other.  More sizes than slots means that a request
   almost always asks a slot for a size its block does not have, which is
   the path on which the cache once gave a block back to malloc and took a
   new one while another thread was in it.  A block that two threads hold
   at the same time is a fault and is printed.  Built with
   -fsanitize=thread, a data race of the cache ends the run as well.

   The runtime is included whole, so that
   the static cache of crypto.c and its own helpers are in this one
   translation unit.

   Exit 0: no block was held by two threads at once.  Exit 1: one was, or
   no thread started. */
#include "../../lib/prelude/all.c"

/* No <stdio.h>: the runtime declares fputc, fgetc and fflush itself with a
   void pointer, and the header's own declarations beside them are a
   conflicting types error.  The two lines the test writes go through
   write(2), which unistd.h declares. */
#define TEST_THREADS 8
#define TEST_ROUNDS 2000
#define TEST_SIZES 3

static const size_t test_sizes[TEST_SIZES] = { 4096, 16384, 65536 };

/* The blocks held right now, one entry per thread at most, and the flag
   that says one was held twice.  The lock is the test's own and has
   nothing to do with the cache: it only lets the threads compare their
   handles. */
static pthread_mutex_t test_lock = PTHREAD_MUTEX_INITIALIZER;
static uint8_t* test_held[TEST_THREADS];
static int test_held_count;
static int test_shared;

/* Registers a block as held, or sets the fault when another thread has it. */
static void test_take(uint8_t* block) {
  int i;

  pthread_mutex_lock(&test_lock);
  for (i = 0; i < test_held_count; i++) {
    if (test_held[i] == block) {
      test_shared = 1;
      pthread_mutex_unlock(&test_lock);
      return;
    }
  }
  test_held[test_held_count] = block;
  test_held_count++;
  pthread_mutex_unlock(&test_lock);
}

/* Takes a block out of the held set again; a block that was given to two
   threads is in it once and leaves it once. */
static void test_release(uint8_t* block) {
  int i;

  pthread_mutex_lock(&test_lock);
  for (i = 0; i < test_held_count; i++) {
    if (test_held[i] == block) {
      test_held[i] = test_held[test_held_count - 1];
      test_held_count--;
      break;
    }
  }
  pthread_mutex_unlock(&test_lock);
}

static void* test_worker(void* argument) {
  long id = (long) argument;
  int torn = 0;
  int round;

  for (round = 0; round < TEST_ROUNDS; round++) {
    size_t bytes = test_sizes[(int) ((id + round) % TEST_SIZES)];
    uint8_t value = (uint8_t) ((id + round) & 0xff);
    uint8_t* block = NULL;

    if (hilde_argon2_allocate(&block, bytes) != 0 || block == NULL) {
      static const char message[] = "cache-test: no memory\n";

      (void) write(2, message, sizeof message - 1);
      _exit(1);
    }
    test_take(block);
    memset(block, value, bytes);
    /* The byte is read back, so that the write is not dead and a second
       thread writing the same block shows in the contents as well. */
    if (block[round % (int) bytes] != value) {
      torn = 1;
    }
    test_release(block);
    hilde_argon2_free(block, bytes);
  }
  if (torn) {
    pthread_mutex_lock(&test_lock);
    test_shared = 1;
    pthread_mutex_unlock(&test_lock);
  }
  return NULL;
}

int main(void) {
  static const char started_fault[] = "cache-test: a thread did not start\n";
  static const char shared_fault[] = "cache-test: a block was held by two threads at once\n";
  static const char passed[] = "cache-test: no block was held by two threads at once\n";
  pthread_t threads[TEST_THREADS];
  int i;

  for (i = 0; i < TEST_THREADS; i++) {
    if (pthread_create(&threads[i], NULL, test_worker, (void*) (long) i) != 0) {
      (void) write(2, started_fault, sizeof started_fault - 1);
      return 1;
    }
  }
  for (i = 0; i < TEST_THREADS; i++) {
    pthread_join(threads[i], NULL);
  }
  if (test_shared) {
    (void) write(2, shared_fault, sizeof shared_fault - 1);
    return 1;
  }
  (void) write(1, passed, sizeof passed - 1);
  return 0;
}
