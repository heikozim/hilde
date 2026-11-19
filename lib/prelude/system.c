/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The terminal, the system log, resource limits, the platform, accounts
 * and secrets read from the terminal.
 */

#include "internal.h"

/*
 * The terminal.
 */

int hilde_terminal_is(int fd) {
  return isatty(fd) ? 1 : 0;
}

/* The echo of the terminal at fd switched on (on is 1) or off (0), as
   readpassphrase(3) does it: ECHO and ECHONL together, with TCSAFLUSH,
   which also drops what was typed before the switch.  1 on success. */
int hilde_terminal_echo(int fd, int on) {
#if defined(__wasi__)
  /* WASI has no settings of a terminal. */
  (void) fd;
  (void) on;
  return 0;
#else
  struct termios t;

  if (tcgetattr(fd, &t) != 0) {
    return 0;
  }
  if (on != 0) {
    t.c_lflag |= (tcflag_t) ECHO;
  } else {
    t.c_lflag &= ~((tcflag_t) ECHO | (tcflag_t) ECHONL);
  }
  return (tcsetattr(fd, TCSAFLUSH, &t) == 0) ? 1 : 0;
#endif
}

/* The columns of the terminal at fd, or 0 when it is none or does not say. */
uint32_t hilde_terminal_width(int fd) {
#if defined(__wasi__)
  (void) fd;
  return 0;
#else
  struct winsize w;

  memset(&w, 0, sizeof w);
  if (ioctl(fd, TIOCGWINSZ, &w) != 0) {
    return 0;
  }
  return (uint32_t) w.ws_col;
#endif
}

/* What waits to be read on the terminal at fd, dropped with tcflush(3).
   1 on success, and for an fd that is no terminal, which has nothing of
   the kind. */
int hilde_terminal_drain(int fd) {
  if (!isatty(fd)) {
    return 1;
  }
#if defined(__wasi__)
  /* WASI cannot drop what waits on a terminal. */
  return 0;
#else
  return (tcflush(fd, TCIFLUSH) == 0) ? 1 : 0;
#endif
}

/* ------------------------------------------------------------------------
   The system log, for Standard.Log through Bindings.SystemLog.

   openlog(3) keeps the pointer to its name and reads it at every syslog(3),
   so the name lives here, in a buffer of this file, and not in a Hilde
   string that is freed.  A longer name is cut to 63 bytes.  LOG_NDELAY
   connects at once, before a sandbox could close the way to the log.  The
   facilities and priorities are passed as indexes and turned into the
   values of this system's syslog.h here, so no number of one system is
   written into a Hilde source.  syslog(3) gets the text through "%.*s",
   never as its format: a per cent sign in a message stays a per cent sign.
   ------------------------------------------------------------------------ */

#if defined(__wasi__)
/* WASI has no system log: the three functions do nothing there, and a
   log written to a file is untouched. */
void hilde_syslog_open(const uint8_t* name, size_t length, uint8_t facility) {
  (void) name;
  (void) length;
  (void) facility;
}

void hilde_syslog_write(uint8_t priority, const uint8_t* text, size_t length) {
  (void) priority;
  (void) text;
  (void) length;
}

void hilde_syslog_close(void) {
}
#else
static char hilde_syslog_name[64];

static const int hilde_syslog_facilities[] = {
  LOG_USER, LOG_DAEMON, LOG_LOCAL0, LOG_LOCAL1, LOG_LOCAL2,
  LOG_LOCAL3, LOG_LOCAL4, LOG_LOCAL5, LOG_LOCAL6, LOG_LOCAL7
};

static const int hilde_syslog_priorities[] = {
  LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERR
};

void hilde_syslog_open(const uint8_t* name, size_t length, uint8_t facility) {
  size_t kept = length;

  if (kept > sizeof hilde_syslog_name - 1) {
    kept = sizeof hilde_syslog_name - 1;
  }
  closelog();
  if (kept > 0) {
    memcpy(hilde_syslog_name, name, kept);
  }
  hilde_syslog_name[kept] = '\0';
  if (facility >= sizeof hilde_syslog_facilities / sizeof hilde_syslog_facilities[0]) {
    facility = 0;
  }
  openlog(hilde_syslog_name, LOG_PID | LOG_NDELAY, hilde_syslog_facilities[facility]);
}

void hilde_syslog_write(uint8_t priority, const uint8_t* text, size_t length) {
  int shown = (length > (size_t) INT32_MAX) ? INT32_MAX : (int) length;

  if (priority >= sizeof hilde_syslog_priorities / sizeof hilde_syslog_priorities[0]) {
    priority = 3;
  }
  syslog(hilde_syslog_priorities[priority], "%.*s", shown, (const char*) text);
}

void hilde_syslog_close(void) {
  closelog();
}
#endif

/*
 * Resource limits and usage, and how long the system has been up.
 */

/* The RLIMIT_ number of which: 0 the data segment, 1 open files, 2 the
   size of a core file; -1 for any other. */
#if !defined(__wasi__)
static int hilde_resource_number(uint32_t which) {
  switch (which) {
  case 0:
    return RLIMIT_DATA;
  case 1:
    return RLIMIT_NOFILE;
  case 2:
    return RLIMIT_CORE;
  default:
    return -1;
  }
}
#endif

/* A limit as the caller writes it: RLIM_INFINITY as the largest 64-bit
   number on every platform, since it is that number on Linux and 2^63 - 1
   on OpenBSD. */
#if !defined(__wasi__)
static uint64_t hilde_resource_out(rlim_t value) {
  return (value == RLIM_INFINITY) ? UINT64_MAX : (uint64_t) value;
}
#endif

/* A limit as the kernel takes it, into out: the largest 64-bit number as
   RLIM_INFINITY.  0 for a number rlim_t cannot hold, anything from
   RLIM_INFINITY up that is not the largest number. */
#if !defined(__wasi__)
static int hilde_resource_in(uint64_t value, rlim_t* out) {
  if (value == UINT64_MAX) {
    *out = RLIM_INFINITY;
    return 1;
  }
  if (value >= (uint64_t) RLIM_INFINITY) {
    return 0;
  }
  *out = (rlim_t) value;
  return 1;
}
#endif

/* The soft and the hard limit of which, with getrlimit(2), into pair.  1
   on success. */
int hilde_resource_limit(uint32_t which, uint64_t* pair) {
#if defined(__wasi__)
  (void) which;
  (void) pair;
  return 0;
#else
  struct rlimit limit;
  int number = hilde_resource_number(which);

  if (number < 0) {
    return 0;
  }
  if (getrlimit(number, &limit) != 0) {
    return 0;
  }
  pair[0] = hilde_resource_out(limit.rlim_cur);
  pair[1] = hilde_resource_out(limit.rlim_max);
  return 1;
#endif
}

/* The soft and the hard limit of which set with setrlimit(2).  1 on
   success; 0 for a value no limit can have, a soft limit above the hard
   one, or a refusal of the kernel, which raising a hard limit without
   privilege is. */
int hilde_resource_set_limit(uint32_t which, uint64_t soft, uint64_t hard) {
#if defined(__wasi__)
  (void) which;
  (void) soft;
  (void) hard;
  return 0;
#else
  struct rlimit limit;
  int number = hilde_resource_number(which);

  if (number < 0 || soft > hard) {
    return 0;
  }
  if (!hilde_resource_in(soft, &limit.rlim_cur) || !hilde_resource_in(hard, &limit.rlim_max)) {
    return 0;
  }
  return (setrlimit(number, &limit) == 0) ? 1 : 0;
#endif
}

/* What the process has used, with getrusage(2), into three slots: the CPU
   time in the process and in the kernel for it, in microseconds, and the
   largest resident set so far in bytes.  ru_maxrss counts kilobytes on
   Linux and OpenBSD.  1 on success. */
int hilde_resource_usage(uint64_t* slots) {
#if defined(__wasi__)
  (void) slots;
  return 0;
#else
  struct rusage usage;

  if (getrusage(RUSAGE_SELF, &usage) != 0) {
    return 0;
  }
  slots[0] = ((uint64_t) usage.ru_utime.tv_sec * 1000000) + (uint64_t) usage.ru_utime.tv_usec;
  slots[1] = ((uint64_t) usage.ru_stime.tv_sec * 1000000) + (uint64_t) usage.ru_stime.tv_usec;
  slots[2] = (usage.ru_maxrss < 0) ? 0 : (uint64_t) usage.ru_maxrss * 1024;
  return 1;
#endif
}

/* Nanoseconds since the system started, time asleep included, or -1
   where there is no such clock.

   The clock is CLOCK_BOOTTIME, and its number is written as a literal for
   the reason hilde_time_monotonic_nanos gives: glibc's headers hide
   clock_gettime and the CLOCK_ constants under -std=c17.  With a
   feature-test macro the header says CLOCK_BOOTTIME is 7 with glibc (gcc
   14.2.0, aarch64) and 6 on OpenBSD (clang 19.1.7).  FreeBSD (15.1, clang
   19.1.7) defines it as CLOCK_MONOTONIC, which is 4.  With the literal, no
   macro and the declaration below, clock_gettime answers 0 and gives the
   uptime on all three, while an unknown number such as 4711 answers -1.
   On macOS CLOCK_MONOTONIC starts at boot and counts on while the system
   sleeps, and its header declares it under -std=c17. */
int64_t hilde_time_boot_nanos(void) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__)
  {
    extern int clock_gettime(int clock_id, struct timespec* ts);
    struct timespec ts;
#if defined(__linux__)
    const int boot = 7;
#elif defined(__FreeBSD__)
    const int boot = 4;
#else
    const int boot = 6;
#endif

    if (clock_gettime(boot, &ts) != 0) {
      return -1;
    }
    return ((int64_t) ts.tv_sec * 1000000000) + (int64_t) ts.tv_nsec;
  }
#elif defined(__APPLE__)
  {
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
      return -1;
    }
    return ((int64_t) ts.tv_sec * 1000000000) + (int64_t) ts.tv_nsec;
  }
#else
  return -1;
#endif
}

/* The system and the machine this programme was compiled for, from the
   macros the C compiler defines for its target: what Standard.Platform
   answers, and where Standard.Paths puts a programme's files.  unknown
   when the compiler names neither. */
hilde_span_t hilde_platform_system(void) {
#if defined(__linux__)
  static const char name[] = "linux";
#elif defined(__OpenBSD__)
  static const char name[] = "openbsd";
#elif defined(__FreeBSD__)
  static const char name[] = "freebsd";
#elif defined(__APPLE__)
  static const char name[] = "macos";
#elif defined(__wasi__)
  static const char name[] = "wasi";
#else
  static const char name[] = "unknown";
#endif
  return (hilde_span_t){ .data = (void*) (uintptr_t) name, .size = sizeof name - 1 };
}

hilde_span_t hilde_platform_machine(void) {
#if defined(__x86_64__)
  static const char name[] = "x86_64";
#elif defined(__aarch64__)
  static const char name[] = "aarch64";
#elif defined(__i386__)
  static const char name[] = "i386";
#elif defined(__arm__)
  static const char name[] = "arm";
#elif defined(__riscv) && (__riscv_xlen == 64)
  static const char name[] = "riscv64";
#elif defined(__powerpc64__)
  static const char name[] = "ppc64";
#elif defined(__wasm32__)
  static const char name[] = "wasm32";
#else
  static const char name[] = "unknown";
#endif
  return (hilde_span_t){ .data = (void*) (uintptr_t) name, .size = sizeof name - 1 };
}

/* The name of the host the programme runs on, asked of the kernel once,
   the first time, and kept: unknown when gethostname fails or gives an
   empty name.  A longer name is cut at 255 bytes.  gethostname is
   declared here, as kill is: glibc hides it under -std=c17. */
static char hilde_platform_host_name[256];
static size_t hilde_platform_host_size;

static void hilde_platform_host_once(void) {
  extern int gethostname(char* name, size_t size);
  char name[256];
  size_t n = 0;

  memset(name, 0, sizeof name);
  if ((gethostname(name, sizeof name - 1) != 0) || (name[0] == '\0')) {
    memcpy(hilde_platform_host_name, "unknown", 7);
    hilde_platform_host_size = 7;
    return;
  }
  while ((n < sizeof name - 1) && (name[n] != '\0')) {
    n++;
  }
  memcpy(hilde_platform_host_name, name, n);
  hilde_platform_host_size = n;
}

hilde_span_t hilde_platform_host(void) {
  static pthread_once_t once = PTHREAD_ONCE_INIT;
  if (pthread_once(&once, hilde_platform_host_once) != 0) {
    hilde_abort_internal("Prelude error: pthread_once failed.");
  }
  return (hilde_span_t){ .data = (void*) hilde_platform_host_name, .size = hilde_platform_host_size };
}

/* The user number (group false) or the group number (group true) of the
   account name in the password database: -1 when there is no such account
   or the name holds a zero byte or is longer than 255 bytes, -2 when the
   lookup failed.  getpwnam_r is declared here, as kill is: glibc hides it
   under -std=c17. */
int64_t hilde_account_number(const uint8_t* name, size_t size, int group) {
#if defined(__wasi__)
  /* WASI has no password database, so the lookup fails. */
  (void) name;
  (void) size;
  (void) group;
  return -2;
#else
  extern int getpwnam_r(const char* name, struct passwd* entry, char* storage, size_t capacity, struct passwd** found);
  char wanted[256];
  char storage[4096];
  struct passwd entry;
  struct passwd* found = NULL;

  if ((size == 0) || (size >= sizeof wanted) || (memchr(name, 0, size) != NULL)) {
    return -1;
  }
  memcpy(wanted, name, size);
  wanted[size] = '\0';
  if (getpwnam_r(wanted, &entry, storage, sizeof storage, &found) != 0) {
    return -2;
  }
  if (found == NULL) {
    return -1;
  }
  return group ? (int64_t) entry.pw_gid : (int64_t) entry.pw_uid;
#endif
}

/* The effective user number of the process. */
uint32_t hilde_account_effective(void) {
  extern uid_t geteuid(void);

  return (uint32_t) geteuid();
}

/* A secret read from the terminal of the process, /dev/tty, never from
   standard input or an argument, with the echo off and nothing shown in its
   place.  prompt is written first.  Up to capacity bytes go into buffer, a
   line feed ends the input and is not kept.  The length, or -1 when the
   process has no terminal, -2 when the line was longer than capacity, -3
   when reading failed.  On -2 and -3 the buffer is wiped.

   The BSDs and macOS have readpassphrase(3), which does all of it.  On
   Linux the same is done here: the terminal opened, its echo switched off,
   and the signals that end or stop the process caught while it is off; the
   echo goes back on before such a signal is raised again, so that it is
   never left off. */
#if defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
#if defined(__has_include)
#if __has_include(<readpassphrase.h>)
#include <readpassphrase.h>
#else
/* The header is not in every set of headers of a toolchain that builds for
   the system (zig's libc for macOS has none); the function and the flag
   are the same on OpenBSD, FreeBSD and macOS. */
extern char* readpassphrase(const char* prompt, char* buf, size_t bufsiz, int flags);
#define RPP_REQUIRE_TTY 0x02
#endif
#else
#include <readpassphrase.h>
#endif

int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  char text[256];
  char line[1026];
  size_t n;

  if (prompt_size >= sizeof text || capacity + 2 > sizeof line) {
    return -3;
  }
  memcpy(text, prompt, prompt_size);
  text[prompt_size] = '\0';
  errno = 0;
  if (readpassphrase(text, line, capacity + 2, RPP_REQUIRE_TTY) == NULL) {
    int no_tty = (errno == ENOTTY || errno == ENXIO || errno == ENOENT);
    hilde_wipe(line, sizeof line);
    return no_tty ? -1 : -3;
  }
  n = strlen(line);
  if (n > capacity) {
    hilde_wipe(line, sizeof line);
    hilde_wipe(buffer, capacity);
    return -2;
  }
  memcpy(buffer, line, n);
  hilde_wipe(line, sizeof line);
  return (int64_t) n;
}
#elif defined(__linux__)
static volatile sig_atomic_t hilde_secret_signal = 0;

static void hilde_secret_caught(int number) {
  hilde_secret_signal = number;
}

int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  extern int kill(pid_t pid, int sig);
  static const int caught[] = {
    SIGINT, SIGHUP, SIGQUIT, SIGTERM, SIGTSTP, SIGTTIN, SIGTTOU
  };
  enum { kinds = sizeof caught / sizeof caught[0] };
  hilde_sigaction_t act;
  hilde_sigaction_t saved[kinds];
  int installed[kinds];
  struct termios before;
  struct termios quiet;
  int64_t result = 0;
  size_t used = 0;
  int over = 0;
  int fd;
  int i;

  do {
    fd = open("/dev/tty", O_RDWR | O_NOCTTY);
  } while (fd < 0 && errno == EINTR);
  fd = hilde_file_mark_close_on_exec(fd);
  if (fd < 0) {
    return -1;
  }
  if (tcgetattr(fd, &before) != 0) {
    close(fd);
    return -1;
  }
  hilde_secret_signal = 0;
  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = hilde_secret_caught;
  /* A kind whose handler the kernel refused keeps the action it has, and
     only the kinds whose handler went in get their saved action back. */
  for (i = 0; i < kinds; i++) {
    installed[i] = (hilde_libc_sigaction(caught[i], &act, &saved[i]) == 0);
  }
  quiet = before;
  quiet.c_lflag &= ~((tcflag_t) ECHO | (tcflag_t) ECHONL);
  if (hilde_file_write_all(fd, prompt, prompt_size) != 1
      || tcsetattr(fd, TCSAFLUSH, &quiet) != 0) {
    result = -3;
  }
  while (result == 0 && hilde_secret_signal == 0) {
    uint8_t byte;
    ssize_t got = read(fd, &byte, 1);
    if (got < 0) {
      if (errno == EINTR) {
        continue;
      }
      result = -3;
      break;
    }
    if (got == 0 || byte == '\n' || byte == '\r') {
      break;
    }
    if (used < capacity) {
      buffer[used++] = byte;
    } else {
      over = 1;
    }
  }
  (void) tcsetattr(fd, TCSAFLUSH, &before);
  (void) hilde_file_write_all(fd, (const uint8_t*) "\n", 1);
  /* The buffer is wiped while the handlers are still the reading's own: a
     signal that comes once a handler is put back takes its default action
     and may end the process at once, and then nothing wipes it.  A signal
     caught after this test and before its handler is put back is seen by
     the second test below. */
  if (hilde_secret_signal != 0 || result != 0 || over) {
    hilde_wipe(buffer, capacity);
  }
  for (i = 0; i < kinds; i++) {
    if (installed[i]) {
      (void) hilde_libc_sigaction(caught[i], &saved[i], NULL);
    }
  }
  close(fd);
  if (hilde_secret_signal != 0) {
    hilde_wipe(buffer, capacity);
    kill(getpid(), hilde_secret_signal);
    return -3;
  }
  if (result != 0 || over) {
    return over ? -2 : result;
  }
  return (int64_t) used;
}
#else
int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  (void) prompt;
  (void) prompt_size;
  (void) buffer;
  (void) capacity;
  return -1;
}
#endif

/* One line of a secret from fd, standard input for --password-stdin: up to
   capacity bytes into buffer, the line feed not kept.  The length, -2 when
   the line was longer (the buffer is wiped), -3 when reading failed. */
int64_t hilde_secret_read_fd(int fd, uint8_t* buffer, size_t capacity) {
  size_t used = 0;
  int over = 0;

  for (;;) {
    uint8_t byte;
    ssize_t got = read(fd, &byte, 1);
    if (got < 0) {
      if (errno == EINTR) {
        continue;
      }
      hilde_wipe(buffer, capacity);
      return -3;
    }
    if (got == 0 || byte == (uint8_t) 10) {
      break;
    }
    if (used < capacity) {
      buffer[used++] = byte;
    } else {
      over = 1;
    }
  }
  if (over) {
    hilde_wipe(buffer, capacity);
    return -2;
  }
  return (int64_t) used;
}
