/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Signals: watching them through a pipe, sending them, and the alarm.
 */

#include "internal.h"

/* ------------------------------------------------------------------------
   Signals, for Standard.Signal through Bindings.Signal.

   The handler does two things only, both async-signal-safe: it adds one to
   the count of its kind with a GNU atomic builtin, as the task runtime
   does, and it writes one byte to the write end of a pipe the runtime
   keeps.  A programme reads the counts and waits on the pipe; it never
   runs its own code in the handler.  The pipe is made at the first watch
   and never closed: closing it would let a handler that is still running
   on another thread write into whatever file the kernel gives that number
   next.  Both ends are non-blocking, so a full pipe drops a byte instead
   of stopping the handler, and close-on-exec.

   A watch and a stop hold hilde_signal_lock, so that two threads that
   watch at once make one pipe and install one watch.  The handler never
   takes the lock: it reads the write end with an atomic load, and the
   watch stores the end before it installs the handler.

   The struct of sigaction and the call are declared in internal.h, for
   glibc with its layout.  The mask is set to zero with memset, which
   leaves none of the five signals in it on either system, as sigismember
   confirms.  glibc's own sigemptyset clears only the first 8 bytes, the 64
   signals of the kernel, and leaves the rest as it was, so the runtime
   does not copy that and clears the whole mask.
   ------------------------------------------------------------------------ */

#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
static const int hilde_signal_numbers[HILDE_SIGNAL_KINDS] = {
  SIGHUP, SIGINT, SIGTERM, SIGUSR1, SIGUSR2
};
static uint32_t hilde_signal_counts[HILDE_SIGNAL_KINDS];
static int hilde_signal_pipe[2] = { -1, -1 };
static uint8_t hilde_signal_mask = 0;
static pthread_mutex_t hilde_signal_lock = PTHREAD_MUTEX_INITIALIZER;

static void hilde_signal_handler(int number) {
  int saved = errno;
  const uint8_t byte = 0;

  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if (hilde_signal_numbers[i] == number) {
      __atomic_add_fetch(&hilde_signal_counts[i], 1, __ATOMIC_SEQ_CST);
    }
  }
  if (write(__atomic_load_n(&hilde_signal_pipe[1], __ATOMIC_SEQ_CST), &byte, 1) < 0) {
    /* A full pipe: a byte is waiting already, which is all a wait needs. */
  }
  errno = saved;
}

/* Makes fd non-blocking and close-on-exec.  0 on success, -1 otherwise. */
static int hilde_signal_mark(int fd) {
  int flags = fcntl(fd, F_GETFL);

  if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) != 0) {
    return -1;
  }
  return (fcntl(fd, F_SETFD, FD_CLOEXEC) == 0) ? 0 : -1;
}

static void hilde_signal_take_lock(void) {
  if (pthread_mutex_lock(&hilde_signal_lock) != 0) {
    hilde_abort_internal("Hilde: the lock of the signal watch failed");
  }
}

static void hilde_signal_let_go(void) {
  if (pthread_mutex_unlock(&hilde_signal_lock) != 0) {
    hilde_abort_internal("Hilde: the lock of the signal watch failed");
  }
}

/* Every watched kind back to its default action, with the lock held.  1
   when the kernel took each one back, 0 when it refused one; the watch is
   over either way. */
static int32_t hilde_signal_stop_held(void) {
  hilde_sigaction_t act;
  int32_t all = 1;

  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = SIG_DFL;
  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if ((hilde_signal_mask & (1u << i)) != 0
        && hilde_libc_sigaction(hilde_signal_numbers[i], &act, NULL) != 0) {
      all = 0;
    }
  }
  hilde_signal_mask = 0;
  return all;
}

/* Every watched kind back to its default action.  1 when the kernel took
   each one back, 0 when it refused one; the watch is over either way. */
int32_t hilde_signal_stop(void) {
  int32_t all;

  hilde_signal_take_lock();
  all = hilde_signal_stop_held();
  hilde_signal_let_go();
  return all;
}

/* hilde_signal_watch with the lock held. */
static int32_t hilde_signal_watch_held(uint8_t mask) {
  hilde_sigaction_t act;

  if (hilde_signal_mask != 0 || mask == 0 || mask >= (1u << HILDE_SIGNAL_KINDS)) {
    return 0;
  }
  if (hilde_signal_pipe[0] < 0) {
    int ends[2];

    if (pipe(ends) != 0) {
      return 0;
    }
    if (hilde_signal_mark(ends[0]) != 0 || hilde_signal_mark(ends[1]) != 0) {
      close(ends[0]);
      close(ends[1]);
      return 0;
    }
    __atomic_store_n(&hilde_signal_pipe[1], ends[1], __ATOMIC_SEQ_CST);
    __atomic_store_n(&hilde_signal_pipe[0], ends[0], __ATOMIC_SEQ_CST);
  }
  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = hilde_signal_handler;
  HILDE_SIGACTION_FLAGS(act) = HILDE_SA_RESTART;
  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if ((mask & (1u << i)) != 0) {
      if (hilde_libc_sigaction(hilde_signal_numbers[i], &act, NULL) != 0) {
        /* The watch failed, and 0 says so whatever the undoing of the
           kinds installed before it answers. */
        hilde_signal_stop_held();
        return 0;
      }
      hilde_signal_mask = (uint8_t) (hilde_signal_mask | (1u << i));
    }
  }
  return 1;
}

/* Installs the handler for every kind whose bit is set in mask.  1 on
   success; 0 when a watch is in place, the pipe could not be made, or the
   kernel refused a kind -- and then the kinds installed before it get their
   default action back. */
int32_t hilde_signal_watch(uint8_t mask) {
  int32_t done;

  /* In a library the handlers would take the host programme's signals. */
  if (HILDE_IN_LIBRARY) {
    return 0;
  }
  hilde_signal_take_lock();
  done = hilde_signal_watch_held(mask);
  hilde_signal_let_go();
  return done;
}

uint32_t hilde_signal_count(uint8_t kind) {
  if (kind >= HILDE_SIGNAL_KINDS) {
    return 0;
  }
  return __atomic_load_n(&hilde_signal_counts[kind], __ATOMIC_SEQ_CST);
}

/* Reads every byte the pipe holds. */
void hilde_signal_drain(void) {
  uint8_t bytes[64];
  int fd = __atomic_load_n(&hilde_signal_pipe[0], __ATOMIC_SEQ_CST);

  if (fd < 0) {
    return;
  }
  while (read(fd, bytes, sizeof bytes) > 0) {
  }
}

/* Waits with poll(2) until the pipe holds a byte or milliseconds have
   passed, then empties it.  1 when a byte was there. */
int32_t hilde_signal_wait(uint32_t milliseconds) {
  struct pollfd watched;
  int timeout = (milliseconds > (uint32_t) INT32_MAX) ? INT32_MAX : (int) milliseconds;
  int ready;

  watched.fd = __atomic_load_n(&hilde_signal_pipe[0], __ATOMIC_SEQ_CST);
  if (watched.fd < 0) {
    return 0;
  }
  watched.events = POLLIN;
  watched.revents = 0;
  ready = poll(&watched, 1, timeout);
  if (ready < 0 && errno == EINTR) {
    /* The signal that ended the wait may be the watched one: its handler
       has written its byte by now, and poll does not restart on Linux. */
    watched.revents = 0;
    ready = poll(&watched, 1, 0);
  }
  hilde_signal_drain();
  return (ready > 0 && (watched.revents & POLLIN) != 0) ? 1 : 0;
}

/* kill(2) with the signal of kind, declared here as in
   hilde_process_terminate.  0 for a number below 1, which kill reads as
   a process group.  Kind HILDE_SIGNAL_KINDS, one past the watched ones,
   is SIGKILL: it can be sent but never watched, so it has no count and
   no bit in a mask. */
int32_t hilde_signal_send(int32_t pid, uint8_t kind) {
  extern int kill(pid_t pid, int sig);
  int number;

  if (pid < 1 || kind > HILDE_SIGNAL_KINDS) {
    return 0;
  }
  number = (kind == HILDE_SIGNAL_KINDS) ? SIGKILL : hilde_signal_numbers[kind];
  return (kill((pid_t) pid, number) == 0) ? 1 : 0;
}

#else
int32_t hilde_signal_watch(uint8_t mask) {
  (void) mask;
  return 0;
}

uint32_t hilde_signal_count(uint8_t kind) {
  (void) kind;
  return 0;
}

void hilde_signal_drain(void) {
}

int32_t hilde_signal_wait(uint32_t milliseconds) {
  (void) milliseconds;
  return 0;
}

int32_t hilde_signal_stop(void) {
  return 1;
}

int32_t hilde_signal_send(int32_t pid, uint8_t kind) {
  (void) pid;
  (void) kind;
  return 0;
}
#endif

/* alarm(2): the kernel sends SIGALRM after seconds, whose default action
   ends the process; 0 takes an alarm back.  The seconds that were left. */
uint32_t hilde_signal_alarm(uint32_t seconds) {
#if defined(__wasi__)
  (void) seconds;
  return 0;
#else
  /* In a library, SIGALRM's default action would end the host's process. */
  if (HILDE_IN_LIBRARY) {
    hilde_stop_with("Hilde: alarm(2) is not available in a library: SIGALRM would end the host's process");
  }
  return (uint32_t) alarm((unsigned int) seconds);
#endif
}

int32_t hilde_process_number(void) {
  return (int32_t) getpid();
}
