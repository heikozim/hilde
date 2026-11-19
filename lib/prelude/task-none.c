/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The task functions of a programme without the task runtime: one
 * thread, where a wait runs to its end and a spawn starts nothing.
 */

#include "internal.h"

#if !defined(HILDE_TASKS)

#define HILDE_PREEMPT_POINT() ((void) 0)

static void hilde_task_blocking(void (*fn)(void*), void* arg) {
  fn(arg);
}

/* No task support on this platform: one thread, one fiber.  A wait can only
   ever be a deadlock, and the locks guard nothing but are taken all the
   same so that the channel code below is the same code everywhere. */
static void hilde_task_park(const void* key, pthread_mutex_t* lock) {
  (void) key;
  (void) lock;
  hilde_stop_with("Hilde: deadlock -- a task waits on a platform without tasks");
}

static void hilde_task_park2(const void* key, pthread_mutex_t* first, pthread_mutex_t* second) {
  (void) key;
  (void) first;
  (void) second;
  hilde_stop_with("Hilde: deadlock -- a task waits on a platform without tasks");
}

static void hilde_task_wake_key(const void* key) {
  (void) key;
}

static void hilde_task_lock(pthread_mutex_t* lock) {
  if (pthread_mutex_lock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}

static void hilde_task_unlock(pthread_mutex_t* lock) {
  if (pthread_mutex_unlock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}


/* One thread: nothing else can wake it, so it waits until deadline. */
static void hilde_task_park_until(const void* key, pthread_mutex_t* lock, int64_t deadline) {
  (void) key;
  hilde_task_unlock(lock);
  hilde_task_sleep_alone(deadline - hilde_task_now());
}

hilde_unit_t hilde_task_sleep_ns(int64_t nanos) {
  hilde_task_sleep_alone(nanos);
  return nil;
}

void* hilde_task_spawn(void* scope, hilde_fnptr_t entry, uint8_t* argument) {
  (void) scope;
  (void) entry;
  (void) argument;
  return NULL;
}

hilde_unit_t hilde_task_join(void* raw) {
  (void) raw;
  return nil;
}

/* Without tasks a task ran to its end when it was started. */
int32_t hilde_task_done(void* raw) {
  (void) raw;
  return 1;
}

hilde_unit_t hilde_task_scope_wait_below(void* raw, size_t count) {
  (void) raw;
  (void) count;
  return nil;
}

/* Without tasks there is only the programme's own stack. */
size_t hilde_task_stack_left(void) {
  return SIZE_MAX;
}

hilde_unit_t hilde_task_yield(void) {
  return nil;
}

int hilde_task_wait_fd(int fd, int what) {
  struct pollfd p;
  int rc;

  p.fd = fd;
  p.events = (what == 2) ? POLLOUT : POLLIN;
  p.revents = 0;
  do {
    rc = poll(&p, 1, -1);
  } while (rc < 0 && errno == EINTR);
  return hilde_task_poll_answer(rc, p.revents, what);
}

/* Without tasks a read has no worker to give back. */
static void hilde_task_before_read(int fd) {
  (void) fd;
}

void* hilde_task_scope_open(void) {
  extern void* calloc(size_t count, size_t size);

  return calloc(1, 1);
}

void* hilde_task_scope_open_sized(size_t stack) {
  (void) stack;
  return hilde_task_scope_open();
}

static __attribute__((unused)) void* hilde_task_lending_open_sized(size_t stack) {
  return hilde_task_scope_open_sized(stack);
}

static __attribute__((unused)) void* hilde_task_lending_open(void) {
  return hilde_task_scope_open();
}

hilde_unit_t hilde_task_scope_close(void* raw) {
  extern void free(void* ptr);

  free(raw);
  return nil;
}

int hilde_task_available(void) {
  return 0;
}

/* Without tasks a library has no workers to stop. */
static void hilde_task_library_stop(void) {
}

int32_t hilde_task_test_sleepers(void) {
  return 0;
}

int32_t hilde_task_test_wake_two(void) {
  return 0;
}

int32_t hilde_task_test_touch_guard(void) {
  return 0;
}

int64_t hilde_task_test_runs(void) {
  return 0;
}

int32_t hilde_task_workers_running(void) {
  return 1;
}

int32_t hilde_task_worker_index(void) {
  return 0;
}

#endif
