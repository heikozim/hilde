/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Mutexes and atomic words that tasks share.
 */

#include "internal.h"

/*
 * Mutexes.
 *
 * A lock that tasks share through a lent reference, to take turns at a
 * value they all change.  As with a channel, the bookkeeping lives here
 * and the value lives in Hilde, beside the lock.  A task that finds the
 * lock held parks on it as a receive parks on an empty channel: its
 * worker runs other tasks meanwhile, and a lock that is never given back
 * ends in the deadlock message.  The lock of the mutex is what carries
 * the value from one thread to the next: release writes the value back
 * before it takes the lock, acquire reads it after.
 */

typedef struct hilde_mutex {
  pthread_mutex_t lock;
  int held;
} hilde_mutex_t;

/* A mutex that is not held.  NULL when out of memory. */
void* hilde_mutex_open(void) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_mutex_t* mutex;

  mutex = (hilde_mutex_t*) calloc(1, sizeof(hilde_mutex_t));
  if (mutex == NULL) {
    return NULL;
  }
  if (pthread_mutex_init(&mutex->lock, NULL) != 0) {
    free(mutex);
    return NULL;
  }
  HILDE_WITNESS_NAME(&mutex->lock, HILDE_WITNESS_MUTEX);
  return (void*) mutex;
}

/* Wait until the mutex is not held, then hold it. */
hilde_unit_t hilde_mutex_acquire(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  hilde_task_lock(&mutex->lock);
  while (mutex->held) {
    hilde_task_park(raw, &mutex->lock);
    hilde_task_lock(&mutex->lock);
  }
  mutex->held = 1;
  hilde_task_unlock(&mutex->lock);
  return nil;
}

/* Hold the mutex when it is not held: 1, and 0 without waiting when it is. */
int32_t hilde_mutex_try(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;
  int32_t took;

  hilde_task_lock(&mutex->lock);
  took = mutex->held ? 0 : 1;
  mutex->held = 1;
  hilde_task_unlock(&mutex->lock);
  return took;
}

/* Let the mutex go and wake the tasks that wait for it. */
hilde_unit_t hilde_mutex_release(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  hilde_task_lock(&mutex->lock);
  mutex->held = 0;
  hilde_task_wake_key(raw);
  hilde_task_unlock(&mutex->lock);
  return nil;
}

/* Whether the mutex is held now. */
int32_t hilde_mutex_held(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;
  int32_t held;

  hilde_task_lock(&mutex->lock);
  held = mutex->held ? 1 : 0;
  hilde_task_unlock(&mutex->lock);
  return held;
}

hilde_unit_t hilde_mutex_free(void* raw) {
  extern void free(void* ptr);
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  HILDE_WITNESS_FORGET(&mutex->lock);
  pthread_mutex_destroy(&mutex->lock);
  free(raw);
  return nil;
}

/* Atomic operations on a word of 64 bits that Hilde allocated, each
   sequentially consistent: every task sees the operations on one word in
   one order. */

int64_t hilde_atomic_load(void* word) {
  return __atomic_load_n((int64_t*) word, __ATOMIC_SEQ_CST);
}

hilde_unit_t hilde_atomic_store(void* word, int64_t value) {
  __atomic_store_n((int64_t*) word, value, __ATOMIC_SEQ_CST);
  return nil;
}

int64_t hilde_atomic_exchange(void* word, int64_t value) {
  return __atomic_exchange_n((int64_t*) word, value, __ATOMIC_SEQ_CST);
}

/* 1 when the word held expected and now holds desired, 0 when it held
   something else and is unchanged. */
int32_t hilde_atomic_compare_swap(void* word, int64_t expected, int64_t desired) {
  return __atomic_compare_exchange_n((int64_t*) word, &expected, desired, 0,
                                     __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST) ? 1 : 0;
}
