/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/* Controls of the runtime's signal handling, never part of a programme.
   Each is built with one SIGNAL_CONTROL, from the root of the tree, by
   scripts/signal/check-controls.sh, and ends with 0 when the runtime does
   what it must.

     1  a library: hilde_start leaves the host's SIGPIPE as it was.
     2  a programme: hilde_store_cli_args ignores SIGPIPE.
     3  two threads that watch at once: one watch wins, and the runtime
        holds one pipe, never two.
     4  hilde_secret_read_tty when the kernel refuses one handler: the
        kinds whose handler went in get theirs back, the refused kind is
        not touched again.  Linux only, on a pseudo-terminal.

   The runtime is included whole, so that its static parts can be
   called. */
#include "../../lib/prelude/all.c"

#ifndef SIGNAL_CONTROL
#error "SIGNAL_CONTROL is a number from 1 to 4"
#endif

extern pid_t fork(void);
extern pid_t waitpid(pid_t pid, int* status, int options);
extern pid_t setsid(void);

/* The action the kernel holds for SIGPIPE: 0 default, 1 ignore, 2 other. */
static __attribute__((unused)) int control_sigpipe_action(void) {
  hilde_sigaction_t old;

  if (hilde_libc_sigaction(SIGPIPE, NULL, &old) != 0) {
    return -1;
  }
  if (HILDE_SIGACTION_HANDLER(old) == SIG_DFL) {
    return 0;
  }
  return (HILDE_SIGACTION_HANDLER(old) == SIG_IGN) ? 1 : 2;
}

#if SIGNAL_CONTROL == 1
#if !defined(HILDE_LIBRARY)
#error "control 1 is built with -DHILDE_LIBRARY"
#endif
int main(void) {
  signal(SIGPIPE, SIG_DFL);
  hilde_start();
  return (control_sigpipe_action() == 0) ? 0 : 1;
}

#elif SIGNAL_CONTROL == 2
int main(int argc, char** argv) {
  signal(SIGPIPE, SIG_DFL);
  hilde_store_cli_args(argc, argv);
  return (control_sigpipe_action() == 1) ? 0 : 1;
}

#elif SIGNAL_CONTROL == 3
static int control_go = 0;
static int control_won = 0;

static void* control_watch(void* unused) {
  (void) unused;
  while (!__atomic_load_n(&control_go, __ATOMIC_SEQ_CST)) {
  }
  if (hilde_signal_watch(1) == 1) {
    __atomic_add_fetch(&control_won, 1, __ATOMIC_SEQ_CST);
  }
  return NULL;
}

static int control_open_files(void) {
  int count = 0;

  for (int fd = 0; fd < 256; fd++) {
    if (fcntl(fd, F_GETFD) >= 0) {
      count++;
    }
  }
  return count;
}

/* One round in a child of its own, so that each round makes the pipe
   anew: 0 when one watch won and two files were opened. */
static int control_round(void) {
  pthread_t threads[2];
  int before = control_open_files();

  for (int i = 0; i < 2; i++) {
    if (pthread_create(&threads[i], NULL, control_watch, NULL) != 0) {
      return 2;
    }
  }
  __atomic_store_n(&control_go, 1, __ATOMIC_SEQ_CST);
  for (int i = 0; i < 2; i++) {
    pthread_join(threads[i], NULL);
  }
  if (control_won != 1 || control_open_files() != before + 2) {
    return 1;
  }
  return 0;
}

int main(void) {
  for (int round = 0; round < 2000; round++) {
    int status = 0;
    pid_t child = fork();

    if (child < 0) {
      return 2;
    }
    if (child == 0) {
      _exit(control_round());
    }
    if (waitpid(child, &status, 0) != child || !WIFEXITED(status)) {
      return 2;
    }
    if (WEXITSTATUS(status) != 0) {
      return WEXITSTATUS(status);
    }
  }
  return 0;
}

#elif SIGNAL_CONTROL == 4
#if !defined(__linux__)
#error "control 4 runs on Linux"
#endif
extern int posix_openpt(int flags);
extern int grantpt(int fd);
extern int unlockpt(int fd);
extern char* ptsname(int fd);
extern int control_real_sigaction(int number, const hilde_sigaction_t* act,
                                  hilde_sigaction_t* old) __asm__("__sigaction");

/* The calls that set an action, per signal number. */
static int control_sets[65];

/* Takes the place of libc's sigaction: refuses the runtime's handler for
   SIGQUIT and counts every call that sets an action. */
int control_sigaction(int number, const hilde_sigaction_t* act,
                      hilde_sigaction_t* old) __asm__("sigaction");
int control_sigaction(int number, const hilde_sigaction_t* act,
                      hilde_sigaction_t* old) {
  if (act != NULL && number > 0 && number < 65) {
    control_sets[number]++;
    if (number == SIGQUIT && HILDE_SIGACTION_HANDLER(*act) == hilde_secret_caught) {
      errno = EINVAL;
      return -1;
    }
  }
  return control_real_sigaction(number, act, old);
}

/* Types a line into the terminal every 50 ms: the read flushes what was
   typed before it turns the echo off, so one line must come after. */
static void* control_type(void* master) {
  for (;;) {
    (void) hilde_file_write_all(*(int*) master, (const uint8_t*) "abc\n", 4);
    (void) poll(NULL, 0, 50);
  }
  return NULL;
}

static int control_child(int master) {
  static const int installed[] = { SIGINT, SIGHUP, SIGTERM, SIGTSTP, SIGTTIN, SIGTTOU };
  const char* name;
  uint8_t buffer[16];
  pthread_t typist;
  int slave;
  int64_t got;

  if (setsid() < 0 || (name = ptsname(master)) == NULL) {
    return 2;
  }
  /* The first terminal a session leader opens becomes its terminal. */
  slave = open(name, O_RDWR);
  if (slave < 0) {
    return 2;
  }
  if (pthread_create(&typist, NULL, control_type, &master) != 0) {
    return 2;
  }
  got = hilde_secret_read_tty((const uint8_t*) "p: ", 3, buffer, sizeof buffer);
  if (got != 3) {
    return 2;
  }
  for (size_t i = 0; i < sizeof installed / sizeof installed[0]; i++) {
    if (control_sets[installed[i]] != 2) {
      return 1;
    }
  }
  return (control_sets[SIGQUIT] == 1) ? 0 : 1;
}

int main(void) {
  int status = 0;
  int master = posix_openpt(O_RDWR | O_NOCTTY);
  pid_t child;

  if (master < 0 || grantpt(master) != 0 || unlockpt(master) != 0) {
    return 2;
  }
  child = fork();
  if (child < 0) {
    return 2;
  }
  if (child == 0) {
    _exit(control_child(master));
  }
  if (waitpid(child, &status, 0) != child || !WIFEXITED(status)) {
    return 2;
  }
  return WEXITSTATUS(status);
}
#else
#error "SIGNAL_CONTROL is a number from 1 to 4"
#endif
