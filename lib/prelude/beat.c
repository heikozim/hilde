/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Heartbeats written by a thread of their own.
 */

#include "internal.h"

#if !defined(__wasi__)

/*
 * Heartbeats.
 *
 * A connection is registered with the bytes of one frame, a function that
 * writes to it and its descriptor.  A thread of its own writes that frame
 * on every registered connection once per interval, so that a peer that
 * waits for this process hears from it while the programme computes and
 * calls nothing.  The runtime knows nothing of the protocol: the function
 * is the library's write call, which answers the bytes it took, -2 when it
 * must wait until the descriptor can be read, -3 until it can be written,
 * and anything else below 1 for a failure.
 *
 * A connection of a library such as libtls must not be used by two threads
 * at once, so the programme and the thread take turns.  The programme
 * takes its turn with hilde_beat_enter around every call on a registered
 * connection and gives it back with hilde_beat_leave; the thread waits for
 * a turn before each round and is served before the programme's next turn,
 * so a programme that reads in a loop cannot starve it.  A frame the
 * programme writes is written in one turn, so a heartbeat never lands
 * inside it.
 *
 * Every variable below is guarded by hilde_beat_lock.  The list of
 * connections changes only during the programme's turn, and the thread
 * walks it only during its own, so the walk needs no lock.
 */

typedef long (*hilde_beat_write_fn)(void* context, const void* bytes, size_t length);

typedef struct hilde_beat_link {
  /* Borrowed: the library's connection, valid until hilde_beat_drop,
     which the owner calls before it frees the connection. */
  void* context;
  int fd;
  /* Owned: a copy of the frame, freed by hilde_beat_drop. */
  uint8_t* frame;
  size_t length;
  hilde_beat_write_fn write;
  /* 1 after a write failed or ran out of time; no more beats on it. */
  int failed;
  struct hilde_beat_link* next;
} hilde_beat_link_t;

/* Owner of the turn: 0 nobody, 1 the programme, 2 the thread. */
#define HILDE_BEAT_FREE 0
#define HILDE_BEAT_PROGRAMME 1
#define HILDE_BEAT_THREAD 2

/* How long one heartbeat may take to be written before its connection
   counts as failed: a peer whose buffers stay full that long reads
   nothing. */
#define HILDE_BEAT_WRITE_LIMIT_MS 30000

static pthread_mutex_t hilde_beat_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t hilde_beat_turn = PTHREAD_COND_INITIALIZER;
static pthread_cond_t hilde_beat_wake = PTHREAD_COND_INITIALIZER;
static int hilde_beat_owner = HILDE_BEAT_FREE;
static int hilde_beat_waiting = 0;
static int hilde_beat_running = 0;
static int hilde_beat_stop = 0;
static uint32_t hilde_beat_interval_ms = 1000;
static uint64_t hilde_beat_rounds = 0;
static hilde_beat_link_t* hilde_beat_links = NULL;
static pthread_t hilde_beat_thread;
static pthread_once_t hilde_beat_named = PTHREAD_ONCE_INIT;

/* The lock of the heartbeats is of a kind of its own for the lock-order
   checker of a build with it; named once, before its first use. */
static void hilde_beat_name(void) {
  HILDE_WITNESS_NAME(&hilde_beat_lock, HILDE_WITNESS_BEAT);
}

static void hilde_beat_take(void) {
  if (pthread_once(&hilde_beat_named, hilde_beat_name) != 0) {
    hilde_task_die("Hilde: the lock of the heartbeats could not be named");
  }
  hilde_task_lock(&hilde_beat_lock);
}

/* The frame of link written whole, waiting on its descriptor while the
   library asks for that.  0, or -1 when a write failed or the limit ran
   out. */
static int hilde_beat_write_link(hilde_beat_link_t* link) {
  size_t sent = 0;
  int64_t started = hilde_time_monotonic_nanos();

  while (sent < link->length) {
    long n = link->write(link->context, link->frame + sent, link->length - sent);
    if (n == -2 || n == -3) {
      struct pollfd want;
      int64_t now = hilde_time_monotonic_nanos();
      int64_t left_ms = HILDE_BEAT_WRITE_LIMIT_MS - (now - started) / 1000000;
      if (started < 0 || now < 0 || left_ms <= 0) {
        return -1;
      }
      want.fd = link->fd;
      want.events = (short) (n == -2 ? POLLIN : POLLOUT);
      want.revents = 0;
      if (poll(&want, 1, (int) left_ms) < 0 && errno != EINTR) {
        return -1;
      }
      continue;
    }
    if (n <= 0 || (size_t) n > link->length - sent) {
      return -1;
    }
    sent += (size_t) n;
  }
  return 0;
}

/* The deadline interval_ms from now on the wall clock, which
   pthread_cond_timedwait reads. */
static struct timespec hilde_beat_deadline(uint32_t interval_ms) {
  struct timespec at;
  uint64_t nanos = hilde_time_wall_nanos() + (uint64_t) interval_ms * 1000000u;

  at.tv_sec = (time_t) (nanos / 1000000000u);
  at.tv_nsec = (long) (nanos % 1000000000u);
  return at;
}

static void* hilde_beat_main(void* unused) {
  (void) unused;
  hilde_beat_take();
  while (!hilde_beat_stop) {
    struct timespec at = hilde_beat_deadline(hilde_beat_interval_ms);
    int waited = 0;
    while (!hilde_beat_stop && waited != ETIMEDOUT) {
      HILDE_WITNESS_WAIT(&hilde_beat_lock);
      waited = pthread_cond_timedwait(&hilde_beat_wake, &hilde_beat_lock, &at);
    }
    if (hilde_beat_stop) {
      break;
    }
    hilde_beat_waiting = 1;
    while (!hilde_beat_stop && hilde_beat_owner != HILDE_BEAT_FREE) {
      HILDE_WITNESS_WAIT(&hilde_beat_lock);
      pthread_cond_wait(&hilde_beat_turn, &hilde_beat_lock);
    }
    hilde_beat_waiting = 0;
    if (hilde_beat_stop) {
      pthread_cond_broadcast(&hilde_beat_turn);
      break;
    }
    hilde_beat_owner = HILDE_BEAT_THREAD;
    hilde_task_unlock(&hilde_beat_lock);
    for (hilde_beat_link_t* link = hilde_beat_links; link != NULL; link = link->next) {
      if (!link->failed && hilde_beat_write_link(link) != 0) {
        link->failed = 1;
      }
    }
    hilde_beat_take();
    hilde_beat_rounds += 1;
    hilde_beat_owner = HILDE_BEAT_FREE;
    pthread_cond_broadcast(&hilde_beat_turn);
  }
  hilde_task_unlock(&hilde_beat_lock);
  return NULL;
}

/* The programme's turn: waits while the thread writes or waits to. */
hilde_unit_t hilde_beat_enter(void) {
  hilde_beat_take();
  while (hilde_beat_owner != HILDE_BEAT_FREE || hilde_beat_waiting) {
    HILDE_WITNESS_WAIT(&hilde_beat_lock);
    pthread_cond_wait(&hilde_beat_turn, &hilde_beat_lock);
  }
  hilde_beat_owner = HILDE_BEAT_PROGRAMME;
  hilde_task_unlock(&hilde_beat_lock);
  return (hilde_unit_t) 0;
}

/* Gives the programme's turn back. */
hilde_unit_t hilde_beat_leave(void) {
  hilde_beat_take();
  hilde_beat_owner = HILDE_BEAT_FREE;
  pthread_cond_broadcast(&hilde_beat_turn);
  hilde_task_unlock(&hilde_beat_lock);
  return (hilde_unit_t) 0;
}

/* Registers a connection: context and fd of the library, the frame of
   length bytes (copied), write the library's write call.  Starts the
   thread with the first connection.  The handle for hilde_beat_drop, or a
   null pointer when there is no memory, length is 0, or the thread cannot
   be started; nothing is registered then. */
void* hilde_beat_add(void* context, int32_t fd, const uint8_t* frame, size_t length, hilde_beat_write_fn write) {
  extern void* calloc(size_t count, size_t size);
  extern void* malloc(size_t size);
  extern void free(void* ptr);
  hilde_beat_link_t* link;

  if (context == NULL || fd < 0 || frame == NULL || length == 0 || write == NULL) {
    return NULL;
  }
  link = (hilde_beat_link_t*) calloc(1, sizeof(hilde_beat_link_t));
  if (link == NULL) {
    return NULL;
  }
  link->frame = (uint8_t*) malloc(length);
  if (link->frame == NULL) {
    free(link);
    return NULL;
  }
  memcpy(link->frame, frame, length);
  link->length = length;
  link->context = context;
  link->fd = fd;
  link->write = write;
  hilde_beat_enter();
  hilde_beat_take();
  if (!hilde_beat_running) {
    hilde_beat_stop = 0;
    if (pthread_create(&hilde_beat_thread, NULL, hilde_beat_main, NULL) != 0) {
      hilde_task_unlock(&hilde_beat_lock);
      hilde_beat_leave();
      free(link->frame);
      free(link);
      return NULL;
    }
    hilde_beat_running = 1;
  }
  hilde_task_unlock(&hilde_beat_lock);
  link->next = hilde_beat_links;
  hilde_beat_links = link;
  hilde_beat_leave();
  return (void*) link;
}

/* The write call of libtls for hilde_beat_add, and the registration of a
   connection of libtls.  Both are static inline and unused unless called,
   so a programme that does not register a connection of libtls needs no
   -ltls.  The prototype is the one the binding of libtls declares, in its
   types, so that the two declarations agree. */
hilde_int64_t tls_write(hilde_unit_t* v_ctx, hilde_unit_t* v_buf, hilde_index_t v_buflen);

static inline __attribute__((unused))
long hilde_beat_tls_write(void* context, const void* bytes, size_t length) {
  return (long) tls_write((hilde_unit_t*) context, (hilde_unit_t*) bytes, (hilde_index_t) length);
}

static inline __attribute__((unused))
void* hilde_beat_add_tls(void* context, int32_t fd, const uint8_t* frame, size_t length) {
  return hilde_beat_add(context, fd, frame, length, hilde_beat_tls_write);
}

/* Removes the connection of handle and frees its copy of the frame; with
   the last one the thread ends and is joined.  The owner calls it before
   it frees the connection. */
hilde_unit_t hilde_beat_drop(void* handle) {
  extern void free(void* ptr);
  hilde_beat_link_t* link = (hilde_beat_link_t*) handle;
  hilde_beat_link_t** at;
  int last = 0;

  if (link == NULL) {
    return (hilde_unit_t) 0;
  }
  hilde_beat_enter();
  for (at = &hilde_beat_links; *at != NULL; at = &(*at)->next) {
    if (*at == link) {
      *at = link->next;
      break;
    }
  }
  last = hilde_beat_links == NULL;
  free(link->frame);
  link->frame = NULL;
  free(link);
  hilde_beat_leave();
  if (last) {
    int join = 0;
    hilde_beat_take();
    if (hilde_beat_running && hilde_beat_links == NULL) {
      hilde_beat_stop = 1;
      hilde_beat_running = 0;
      join = 1;
      pthread_cond_broadcast(&hilde_beat_wake);
      pthread_cond_broadcast(&hilde_beat_turn);
    }
    hilde_task_unlock(&hilde_beat_lock);
    if (join) {
      pthread_join(hilde_beat_thread, NULL);
    }
  }
  return (hilde_unit_t) 0;
}

/* Sets the interval between two rounds, at least 10 ms; the thread takes
   it from its next round on. */
hilde_unit_t hilde_beat_set_interval(uint32_t milliseconds) {
  hilde_beat_take();
  hilde_beat_interval_ms = milliseconds < 10 ? 10 : milliseconds;
  pthread_cond_broadcast(&hilde_beat_wake);
  hilde_task_unlock(&hilde_beat_lock);
  return (hilde_unit_t) 0;
}

/* 1 when the heartbeat of handle failed and stopped, else 0. */
int32_t hilde_beat_failed(void* handle) {
  hilde_beat_link_t* link = (hilde_beat_link_t*) handle;
  int32_t failed;

  if (link == NULL) {
    return 0;
  }
  hilde_beat_enter();
  failed = (int32_t) link->failed;
  hilde_beat_leave();
  return failed;
}

/* How many rounds the thread has written since the programme started. */
uint64_t hilde_beat_round_count(void) {
  uint64_t rounds;

  hilde_beat_take();
  rounds = hilde_beat_rounds;
  hilde_task_unlock(&hilde_beat_lock);
  return rounds;
}

#endif
