/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Child processes and the environment.
 */

#include "internal.h"

/*
 * A child process.
 */

/* This part is compiled on Linux, OpenBSD, FreeBSD and macOS only.
   Anywhere else hilde_process_spawn answers -1 and
   Standard.Process.spawnProcess answers None, as the poller does on a
   platform without a backend: a refusal, not a child that silently never
   starts. */
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)

/* Move a descriptor above the standard three.  A pipe made while the process
   has closed its stdin can come back as 0, and dup2 onto 0 in the child
   would then be a no-op on the wrong file.  Returns the (maybe new)
   descriptor, close-on-exec, or -1. */
static int hilde_process_lift(int fd) {
  int lifted;

  if (fd > 2) {
    return fd;
  }
  lifted = fcntl(fd, F_DUPFD, 3);
  close(fd);
  return hilde_file_mark_close_on_exec(lifted);
}

/* Make one pipe whose two ends are both above 2 and close-on-exec.
   1 or 0. */
static int hilde_process_pipe(int* ends) {
  int fds[2];

  if (hilde_pipe_open(fds) == 0) {
    return 0;
  }
  fds[0] = hilde_process_lift(fds[0]);
  fds[1] = hilde_process_lift(fds[1]);
  if (fds[0] < 0 || fds[1] < 0) {
    if (fds[0] >= 0) {
      close(fds[0]);
    }
    if (fds[1] >= 0) {
      close(fds[1]);
    }
    return 0;
  }
  ends[0] = fds[0];
  ends[1] = fds[1];
  return 1;
}

static void hilde_process_close_pair(int* ends) {
  close(ends[0]);
  close(ends[1]);
}

/* Send err to the parent through the status pipe fd.  Called in the child
   between fork and exec, so it uses write only, which is async-signal-safe.
   A write cut short by a signal is made again; the few bytes of an int go
   into a pipe in one piece, so there is no short write.  Any other failure
   cannot be handled in the child: the parent then reads end of file and
   learns from the exit status 127 that nothing ran. */
static void hilde_process_report(int fd, int err) {
  ssize_t put;

  do {
    put = write(fd, &err, sizeof(err));
  } while (put < 0 && errno == EINTR);
}

/* Start the programme at path with count arguments packed into block, each
   followed by a zero byte; the first is what the child sees as its own
   name.  A block of length bytes that does not hold count such texts is
   refused.  The child's standard input, output and error are three pipes; the
   parent's ends go into ends in that order (the end to write the child's
   input into, then the two ends to read from).  The process id, or -1 when
   anything failed, including a failure in the child between the fork and
   the exec or of execve(2) itself, which is reported back rather than
   discovered later as an exit status of 127.

   There is no PATH search: path is used as it stands, so a programme names
   its binary rather than letting the environment choose one.

   Every descriptor above 2 is closed in the child, whatever flags it
   carries (closefrom(3)): a descriptor opened by C code this file does not
   control, without close-on-exec, would otherwise reach every child.  One
   descriptor is kept until the exec: the status pipe, moved to 3 and
   marked close-on-exec, so that a successful exec closes it, and the
   child writes errno into it when any step before the exec fails or the
   exec itself does.

   envp is the environment the child gets, borrowed for the call: environ
   for hilde_process_spawn, a list of its own for hilde_process_spawn_env. */
static int32_t hilde_process_spawn_with(const uint8_t* path, const uint8_t* block,
                                        size_t length, size_t count, char** envp,
                                        int* ends) {
#if defined(__linux__) && !defined(__ANDROID__)
  /* glibc declares it void and hides it under -std=c17; OpenBSD's
     unistd.h declares it int and shows it, so a declaration of ours there
     would be a conflicting-types error.  bionic has no closefrom at any
     API level (NDK 30, levels 24 to 35; close_range from 34 on), and
     macOS has none either, so there the child closes the descriptors one
     by one, up to the limit read before the fork. */
  extern void closefrom(int lowfd);
#endif
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  char** argv;
  int input[2];
  int output[2];
  int errors[2];
  int status[2];
  pid_t pid;
#if defined(__ANDROID__) || defined(__APPLE__)
  long open_max;
  long fd;
#endif
  size_t i;
  size_t at;
  int child_errno;
  ssize_t got;

  if (count == 0 || !hilde_packed_holds(block, length, count)) {
    return -1;
  }
  argv = (char**) calloc(count + 1, sizeof(char*));
  if (argv == NULL) {
    return -1;
  }
  at = 0;
  for (i = 0; i < count; i++) {
    argv[i] = (char*) (block + at);
    at += strlen((const char*) (block + at)) + 1;
  }
  argv[count] = NULL;

  if (hilde_process_pipe(input) == 0) {
    free(argv);
    return -1;
  }
  if (hilde_process_pipe(output) == 0) {
    hilde_process_close_pair(input);
    free(argv);
    return -1;
  }
  if (hilde_process_pipe(errors) == 0) {
    hilde_process_close_pair(input);
    hilde_process_close_pair(output);
    free(argv);
    return -1;
  }
  if (hilde_process_pipe(status) == 0) {
    hilde_process_close_pair(input);
    hilde_process_close_pair(output);
    hilde_process_close_pair(errors);
    free(argv);
    return -1;
  }

#if defined(__ANDROID__) || defined(__APPLE__)
  open_max = sysconf(_SC_OPEN_MAX);
#endif
  pid = fork();
  if (pid < 0) {
    hilde_process_close_pair(input);
    hilde_process_close_pair(output);
    hilde_process_close_pair(errors);
    hilde_process_close_pair(status);
    free(argv);
    return -1;
  }
  if (pid == 0) {
    /* The child.  Only calls that are safe between fork and exec. */
    if (dup2(input[0], 0) < 0 || dup2(output[1], 1) < 0 ||
        dup2(errors[1], 2) < 0) {
      hilde_process_report(status[1], errno);
      _exit(127);
    }
    /* A failure from here to the exec is written into the status pipe as
       well, so that the parent sees a failed start and not an end of file,
       which it takes for a successful exec.  When the move to 3 fails, the
       pipe is still open under its own number. */
    if (status[1] != 3) {
      if (dup2(status[1], 3) < 0) {
        child_errno = errno;
        hilde_process_report(status[1], child_errno);
        _exit(127);
      }
    }
    if (fcntl(3, F_SETFD, FD_CLOEXEC) != 0) {
      child_errno = errno;
      hilde_process_report(3, child_errno);
      _exit(127);
    }
#if defined(__ANDROID__) || defined(__APPLE__)
    for (fd = 4; fd < open_max; fd++) {
      (void) close((int) fd);
    }
#else
    closefrom(4);
#endif
    /* An ignored signal stays ignored across an exec: the child gets the
       default for SIGPIPE back, which the programme ignores for itself. */
#ifdef SIGPIPE
    signal(SIGPIPE, SIG_DFL);
#endif
    execve((const char*) path, argv, envp);
    hilde_process_report(3, errno);
    _exit(127);
  }

  /* The parent.  Its copies of the child's ends are closed first: an input
     pipe whose read end the parent still holds never reports end of file to
     anyone, and an output pipe whose write end it holds never ends. */
  free(argv);
  close(input[0]);
  close(output[1]);
  close(errors[1]);
  close(status[1]);
  do {
    got = read(status[0], &child_errno, sizeof(child_errno));
  } while (got < 0 && errno == EINTR);
  close(status[0]);
  if (got != 0) {
    /* A step in the child failed, and nothing ran; or the read failed,
       and whether the child runs is not known, so it is ended.  Either way
       the process id is collected here so that it does not become a
       zombie, and a running child does not hold the wait. */
    extern int kill(pid_t pid, int sig);
    int reaped;

    if (got < 0) {
      (void) kill(pid, SIGKILL);
    }
    close(input[1]);
    close(output[0]);
    close(errors[0]);
    while (waitpid(pid, &reaped, 0) < 0 && errno == EINTR) {
    }
    return -1;
  }
  ends[0] = input[1];
  ends[1] = output[0];
  ends[2] = errors[0];
  return (int32_t) pid;
}

/* The child inherits the environment of this process. */
int32_t hilde_process_spawn(const uint8_t* path, const uint8_t* block,
                            size_t length, size_t count, int* ends) {
  extern char** environ;

  return hilde_process_spawn_with(path, block, length, count, environ, ends);
}

/* The child gets only the env_count texts of env_block, each "name=value"
   followed by a zero byte, nothing of the environment of this process; 0
   texts give it an empty environment.  A block that does not hold
   env_count such texts is refused with -1, as an argument block is. */
int32_t hilde_process_spawn_env(const uint8_t* path, const uint8_t* block,
                                size_t length, size_t count,
                                const uint8_t* env_block, size_t env_length,
                                size_t env_count, int* ends) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  /* Owned here, freed below on every path; the texts it points to belong
     to env_block, which the caller keeps for the call. */
  char** envp;
  size_t i;
  size_t at;
  int32_t pid;

  if (env_count == 0) {
    if (env_length != 0) {
      return -1;
    }
  } else if (!hilde_packed_holds(env_block, env_length, env_count)) {
    return -1;
  }
  if (env_count == SIZE_MAX) {
    return -1;
  }
  envp = (char**) calloc(env_count + 1, sizeof(char*));
  if (envp == NULL) {
    return -1;
  }
  at = 0;
  for (i = 0; i < env_count; i++) {
    envp[i] = (char*) (env_block + at);
    at += strlen((const char*) (env_block + at)) + 1;
  }
  envp[env_count] = NULL;
  pid = hilde_process_spawn_with(path, block, length, count, envp, ends);
  free(envp);
  return pid;
}

/* Wait for the child to end and say how.  The exit code (0 to 255) when it
   exited, 256 plus the signal number when a signal ended it, -1 when
   waitpid(2) failed.  One number rather than a structure, because Hilde
   receives one return value from C. */
typedef struct hilde_wait_call {
  pid_t pid;
  pid_t got;
  int status;
} hilde_wait_call_t;

static void hilde_process_wait_blocking(void* raw) {
  hilde_wait_call_t* call = (hilde_wait_call_t*) raw;

  do {
    call->got = waitpid(call->pid, &call->status, 0);
  } while (call->got < 0 && errno == EINTR);
}

int32_t hilde_process_wait(int32_t pid) {
  hilde_wait_call_t call;
  int status;

  call.pid = (pid_t) pid;
  call.got = -1;
  call.status = 0;
  hilde_task_blocking(hilde_process_wait_blocking, &call);
  status = call.status;
  if (call.got < 0) {
    return -1;
  }
  if (WIFEXITED(status)) {
    return (int32_t) WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 256 + (int32_t) WTERMSIG(status);
  }
  return -1;
}

/* Wait for the child at most milliseconds: waitpid(2) with WNOHANG, then
   10 ms of sleep, until the child ended or the time is up on the
   monotonic clock.  The encoding of hilde_process_wait, and -2 when the
   child still runs.  Without a monotonic clock the child is looked at
   once: a child that has not ended is still running, never a failed
   wait, so that it is not left unreaped behind a status. */
typedef struct hilde_wait_for_call {
  pid_t pid;
  uint32_t milliseconds;
  pid_t got;
  int status;
} hilde_wait_for_call_t;

static void hilde_process_wait_for_blocking(void* raw) {
  hilde_wait_for_call_t* call = (hilde_wait_for_call_t*) raw;
  int64_t start;
  int64_t now;

  start = hilde_time_monotonic_nanos();
  for (;;) {
    do {
      call->got = waitpid(call->pid, &call->status, WNOHANG);
    } while (call->got < 0 && errno == EINTR);
    if (call->got != 0) {
      return;
    }
    now = hilde_time_monotonic_nanos();
    if (start < 0 || now < 0) {
      return;
    }
    if ((now - start) / 1000000 >= (int64_t) call->milliseconds) {
      return;
    }
    /* poll(2) without descriptors sleeps 10 ms; an interrupted sleep is
       shorter, and the clock above decides the end. */
    (void) poll(NULL, 0, 10);
  }
}

int32_t hilde_process_wait_for(int32_t pid, uint32_t milliseconds) {
  hilde_wait_for_call_t call;
  int status;

  call.pid = (pid_t) pid;
  call.milliseconds = milliseconds;
  call.got = -1;
  call.status = 0;
  hilde_task_blocking(hilde_process_wait_for_blocking, &call);
  if (call.got == 0) {
    return -2;
  }
  if (call.got < 0) {
    return -1;
  }
  status = call.status;
  if (WIFEXITED(status)) {
    return (int32_t) WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 256 + (int32_t) WTERMSIG(status);
  }
  return -1;
}

/* End the child at once: SIGKILL.  1 when the signal was delivered. */
int hilde_process_kill(int32_t pid) {
  extern int kill(pid_t pid, int sig);

  return (kill((pid_t) pid, SIGKILL) == 0) ? 1 : 0;
}

/* Ask the child to end: SIGTERM.  1 when the signal was delivered. */
int hilde_process_terminate(int32_t pid) {
  extern int kill(pid_t pid, int sig);

  return (kill((pid_t) pid, SIGTERM) == 0) ? 1 : 0;
}

/* The number SIGTERM has on this platform, for a caller that wants to
   recognise its own request among the ways a child can end. */
int32_t hilde_process_sigterm(void) {
  return (int32_t) SIGTERM;
}

#else

int32_t hilde_process_spawn(const uint8_t* path, const uint8_t* block,
                            size_t length, size_t count, int* ends) {
  (void) path;
  (void) block;
  (void) length;
  (void) count;
  (void) ends;
  return -1;
}

int32_t hilde_process_spawn_env(const uint8_t* path, const uint8_t* block,
                                size_t length, size_t count,
                                const uint8_t* env_block, size_t env_length,
                                size_t env_count, int* ends) {
  (void) path;
  (void) block;
  (void) length;
  (void) count;
  (void) env_block;
  (void) env_length;
  (void) env_count;
  (void) ends;
  return -1;
}

int32_t hilde_process_wait(int32_t pid) {
  (void) pid;
  return -1;
}

int32_t hilde_process_wait_for(int32_t pid, uint32_t milliseconds) {
  (void) pid;
  (void) milliseconds;
  return -1;
}

int hilde_process_kill(int32_t pid) {
  (void) pid;
  return 0;
}

int hilde_process_terminate(int32_t pid) {
  (void) pid;
  return 0;
}

int32_t hilde_process_sigterm(void) {
  return (int32_t) SIGTERM;
}

#endif

/* The value of the environment variable name of this process
   (Standard.File.environmentValue): -1 when it is not set, otherwise its
   length in bytes, with the first min(length, capacity) bytes copied to
   into.  A length above capacity is the caller's to refuse: a value cut to
   fit would be another value.  getenv is ISO C; it is declared here rather
   than through <stdlib.h>, as calloc is above and for the same reason.
   Declared in Standard.File with pragma Foreign_Import, so these types are
   exactly the ones the code generator declares. */
int64_t hilde_environment_value(uint8_t* name, uint8_t* into,
                                size_t capacity) {
  extern char* getenv(const char* name);
  const char* value = getenv((const char*) name);
  size_t length;

  if (value == NULL) {
    return -1;
  }
  length = strlen(value);
  memcpy(into, value, length < capacity ? length : capacity);
  return (int64_t) length;
}
