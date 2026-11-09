/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Confining the process: pledge and unveil, Landlock and seccomp,
 * Seatbelt and Capsicum.
 */

#include "internal.h"

/*
 * Confining the running process, cut down to what a library can decide.
 * OpenBSD unveils each path, locks the view and pledges, in that order.
 * Linux sets no new privileges, applies a Landlock ruleset built from the
 * same paths, and installs a seccomp filter that refuses up to 34 system
 * calls; sixteen of them only where the kernel headers define their
 * number.
 * Which paths, which promises and whether a degraded start is allowed are
 * the programme's decision, handed in through Standard.Sandbox.
 *
 * Every function answers what it did and never aborts.  On a platform
 * without the mechanism most of them say -1.  Three say 0 there, since
 * for them 0 already means not done or none:
 * hilde_sandbox_set_no_new_privileges, hilde_sandbox_platform and
 * hilde_sandbox_landlock_add.  A report that claims a confinement the
 * process does not have is worse than no sandbox at all.
 */

/* PR_SET_NO_NEW_PRIVS and PR_GET_NO_NEW_PRIVS of <linux/prctl.h>.  The
   numbers are written here rather than the header included, as the libc
   functions above are declared rather than their headers included.  They
   have been 38 and 39 since Linux 3.5, and the kernel cannot change them
   without breaking every binary already built. */
#define HILDE_PR_SET_NO_NEW_PRIVS 38
#define HILDE_PR_GET_NO_NEW_PRIVS 39
/* PR_SET_SECCOMP of <linux/prctl.h>, 22 since Linux 2.6.23, written here
   for the same reason. */
#define HILDE_PR_SET_SECCOMP 22

/* 1 when the flag is set afterwards, 0 when this platform has no such flag
   or the call failed.  It never aborts: a programme decides for itself what
   an unconfined run means, and a library that exits on its behalf takes that
   decision away. */
int32_t hilde_sandbox_set_no_new_privileges(void) {
#if defined(__linux__)
  {
    extern int prctl(int option, ...);

    return (prctl(HILDE_PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) == 0) ? 1 : 0;
  }
#else
  return 0;
#endif
}

/* 1 when the flag is set, 0 when it is not, -1 when the platform does not
   know the question.  The three answers are different on purpose: "not set"
   and "cannot be asked" are not the same, and a report that says applied
   has to be checkable against something. */
int32_t hilde_sandbox_query_no_new_privileges(void) {
#if defined(__linux__)
  {
    extern int prctl(int option, ...);

    int answer = prctl(HILDE_PR_GET_NO_NEW_PRIVS, 0, 0, 0, 0);

    if (answer < 0) {
      return -1;
    }
    return (answer != 0) ? 1 : 0;
  }
#else
  return -1;
#endif
}

/* Which of the sandboxes this programme was built for: 1 OpenBSD (pledge
   and unveil), 2 Linux (no new privileges, Landlock, seccomp), 3 macOS
   (Seatbelt), 4 FreeBSD (Capsicum), 0 none. */
int32_t hilde_sandbox_platform(void) {
  /* Built as a library, a sandbox would confine the host's whole process,
     and on Android the system's own seccomp filter kills an app at a call
     it does not allow.  In both cases nothing is applied and the report
     says so. */
  if (HILDE_IN_LIBRARY) {
    return 0;
  }
#if defined(__OpenBSD__)
  return 1;
#elif defined(__linux__) && !defined(__ANDROID__)
  return 2;
#elif defined(HILDE_SANDBOX_SEATBELT)
  return 3;
#elif defined(HILDE_SANDBOX_CAPSICUM)
  return 4;
#else
  return 0;
#endif
}

/* OpenBSD: pledge and unveil.  The strings come from Bindings.Sandbox, each
   checked there to end in its one zero byte. */

/* 1 when pledge(2) took the promises, 0 when it refused them, -1 on a
   platform without pledge.  No execpromises are given, so a child this
   process starts runs without pledge and without the unveil view. */
int32_t hilde_sandbox_pledge(uint8_t* promises) {
#if defined(__OpenBSD__)
  {
    extern int pledge(const char* promises, const char* execpromises);

    return (pledge((const char*) promises, NULL) == 0) ? 1 : 0;
  }
#else
  (void) promises;
  return -1;
#endif
}

/* 1 when unveil(2) took the path, 0 when it refused, -1 without unveil.
   An empty permission string hides the path. */
int32_t hilde_sandbox_unveil(uint8_t* path, uint8_t* permissions) {
#if defined(__OpenBSD__)
  {
    extern int unveil(const char* path, const char* permissions);

    return (unveil((const char*) path, (const char*) permissions) == 0) ? 1 : 0;
  }
#else
  (void) path;
  (void) permissions;
  return -1;
#endif
}

/* Locks the view: no later unveil can widen it.  1 when unveil(2) took the
   lock, 0 when it refused, -1 without unveil. */
int32_t hilde_sandbox_unveil_lock(void) {
#if defined(__OpenBSD__)
  {
    extern int unveil(const char* path, const char* permissions);

    return (unveil(NULL, NULL) == 0) ? 1 : 0;
  }
#else
  return -1;
#endif
}

/* pledge(2) with execpromises, the promises a programme this process
   starts runs under.  A zero flag passes NULL for its string: promises
   left as they are, or no execpromises, which lets a started programme run
   without pledge and without the unveil view.  With execpromises the
   started programme keeps both.  1 when pledge took the call, 0 when it
   refused it, -1 on a platform without pledge. */
int32_t hilde_sandbox_pledge_exec(uint8_t* promises, int32_t with_promises,
                                  uint8_t* execpromises, int32_t with_exec) {
#if defined(__OpenBSD__)
  {
    extern int pledge(const char* promises, const char* execpromises);
    const char* now = (with_promises != 0) ? (const char*) promises : NULL;
    const char* later = (with_exec != 0) ? (const char*) execpromises : NULL;

    return (pledge(now, later) == 0) ? 1 : 0;
  }
#else
  (void) promises;
  (void) with_promises;
  (void) execpromises;
  (void) with_exec;
  return -1;
#endif
}

/* The walk of the child of hilde_sandbox_unveil_probe over grants, which
   hilde_packed_holds has found to hold 2 * count texts: each path and its
   permissions go to take, and the index of the first pair take refuses for
   want of room (E2BIG) comes back, or -1 when all of them fit.  It is apart
   from unveil(2) so that the walk over the packed block is built, and can
   be fuzzed, on every system. */
static __attribute__((unused)) int32_t hilde_sandbox_unveil_walk(const uint8_t* grants, int32_t count,
                                                                 int (*take)(const char* path, const char* permissions)) {
  const char* at = (const char*) grants;
  int32_t k;

  for (k = 0; k < count; k++) {
    const char* permissions = at + strlen(at) + 1;

    if ((take(at, permissions) == -1) && (errno == E2BIG)) {
      return k;
    }
    at = permissions + strlen(permissions) + 1;
  }
  return -1;
}

/* Runs count paths of grants through unveil(2) in a child process, one at
   a time, and answers the index of the first the kernel refused for want
   of room (E2BIG), or -1 when all fit.  -2 when the child could not be
   run, -3 on a platform without unveil.  grants holds each path and its
   permissions, each ending in a zero byte, as Standard.Sandbox packs them,
   length bytes in all; a block that does not hold 2 * count texts is -2.

   The kernel counts unveiled directories and the names beneath them, each
   up to a ceiling, so what fits depends on the shape of the list and is
   measured rather than computed.  A child does it because an unveil cannot
   be undone: a refusal half way through the list would leave this process
   with half a view.  Any other refusal, such as a missing parent
   directory, only narrows the view and is not counted.  The child ends
   with _exit, so that it does not flush the parent's buffers a second
   time. */
int32_t hilde_sandbox_unveil_probe(uint8_t* grants, size_t length, int32_t count) {
#if defined(__OpenBSD__)
  if (count < 0 || !hilde_packed_holds(grants, length, (size_t) count * 2)) {
    return -2;
  }
  {
    extern int unveil(const char* path, const char* permissions);
    int fds[2];
    int status;
    int32_t answer = -2;
    pid_t pid;

    if (pipe(fds) == -1) {
      return -2;
    }
    pid = fork();
    if (pid == -1) {
      close(fds[0]);
      close(fds[1]);
      return -2;
    }
    if (pid == 0) {
      int32_t first;

      close(fds[0]);
      first = hilde_sandbox_unveil_walk(grants, count, unveil);
      if (write(fds[1], &first, sizeof first) != (ssize_t) sizeof first) {
        _exit(1);
      }
      _exit(0);
    }
    close(fds[1]);
    if (read(fds[0], &answer, sizeof answer) != (ssize_t) sizeof answer) {
      answer = -2;
    }
    close(fds[0]);
    while (waitpid(pid, &status, 0) == -1) {
      if (errno != EINTR) {
        break;
      }
    }
    return answer;
  }
#else
  (void) grants;
  (void) length;
  (void) count;
  return -3;
#endif
}

/* Whether the promises, words separated by one space, hold the word. */
static __attribute__((unused)) int hilde_sandbox_promised(const char* promises, const char* word) {
  size_t size = strlen(word);
  const char* at = promises;

  while (*at != '\0') {
    const char* end = strchr(at, ' ');
    size_t length = (end == NULL) ? strlen(at) : (size_t) (end - at);

    if ((length == size) && (memcmp(at, word, size) == 0)) {
      return 1;
    }
    if (end == NULL) {
      break;
    }
    at = end + 1;
  }
  return 0;
}

/* macOS: Seatbelt.  The C library has no documented call that applies a
   profile of one's own to the running process, so the profile is written
   to a file and the programme is started again under
   /usr/bin/sandbox-exec, which applies it before the programme's first
   instruction.  The first process waits for the confined one and ends as
   it ends.  The profile denies everything, imports the system's own
   system.sb (the shared cache, the system libraries, sysctl and the like,
   without which no process starts) and allows the paths of the policy
   with their permissions, the binary itself and the trees of system and
   package libraries, for reading.

   The confined process is told that it is the one started under the
   profile through a pipe on a fixed descriptor, read before main by
   hilde_seatbelt_handshake, never through the environment: a stale
   variable inherited from a shell would make a process believe it was
   confined.  The pipe carries a hash of the policy the profile was built
   from and the number of its paths that are in the profile, and the
   confined process claims Seatbelt only for a policy with the same hash.
   The message alone proves nothing: whoever starts the programme can put
   the same bytes on that descriptor.  So the process believes it only
   when the kernel says so as well: sandbox_check must report the process
   as sandboxed, and must report creating a file in the root directory as denied,
   which the profile does and an unconfined process never sees.
   It cannot build the profile again itself: resolving a path reads the
   directories above it, which the profile no longer lets it read.  On a second pipe it says that it has
   started; a first process that hears nothing knows the programme never
   ran under the profile, carries on unconfined and reports so. */
#define HILDE_SEATBELT_MAGIC "HildeSbx"
#define HILDE_SEATBELT_MAGIC_LENGTH 8
#define HILDE_SEATBELT_MESSAGE_LENGTH (HILDE_SEATBELT_MAGIC_LENGTH + 16)

/* 1 when a process may take itself for the confined one: got bytes were
   read, a whole message that starts with the magic bytes, and the kernel
   reports the process as sandboxed and creating a file in / as
   denied.  sandboxed and root_denied are 1 for yes, anything else for no
   or unknown.  0 in every other case.  Kept apart from the reading so that
   it can be tested on any system. */
__attribute__((unused)) static int hilde_seatbelt_verdict(const unsigned char* message, long got,
                                                          int sandboxed, int root_denied) {
  if ((message == NULL) || (got != (long) HILDE_SEATBELT_MESSAGE_LENGTH)) {
    return 0;
  }
  if (memcmp(message, HILDE_SEATBELT_MAGIC, HILDE_SEATBELT_MAGIC_LENGTH) != 0) {
    return 0;
  }
  return (sandboxed == 1) && (root_denied == 1);
}

#if defined(HILDE_SANDBOX_SEATBELT)
#define HILDE_SEATBELT_HANDSHAKE_FD 197
#define HILDE_SEATBELT_STARTED_FD 198
/* From libsandbox, which has no public header for it: the filter kinds
   and the flag that keeps a check out of the system log. */
#define HILDE_SANDBOX_FILTER_NONE 0
#define HILDE_SANDBOX_FILTER_PATH 1
#define HILDE_SANDBOX_CHECK_NO_REPORT 0x40000000
extern int sandbox_check(pid_t pid, const char* operation, int type, ...);
#define HILDE_SEATBELT_SPELLINGS 3

/* Set before main in the process sandbox-exec started: the hash of the
   policy its profile was built from and the number of paths in it.
   hilde_seatbelt_claimed is set by the first policy that is asked about,
   so that a second one is not reported as applied. */
static int hilde_seatbelt_started;
static uint64_t hilde_seatbelt_policy_hash;
static uint64_t hilde_seatbelt_taken;
static int hilde_seatbelt_claimed;

/* Runs before main.  A descriptor 197 that is a pipe holding the magic
   bytes, in a process the kernel reports as sandboxed with the root
   directory closed to new files, makes this the confined process; anything else at that number is
   left as it is.  Both descriptors are closed, so that a programme this
   one starts cannot take itself for a confined first start. */
__attribute__((constructor)) static void hilde_seatbelt_handshake(void) {
  unsigned char message[HILDE_SEATBELT_MESSAGE_LENGTH];
  struct stat state;
  struct pollfd ready;
  ssize_t got;
  int answer;

  if (HILDE_IN_LIBRARY) {
    return;
  }
  if ((fstat(HILDE_SEATBELT_HANDSHAKE_FD, &state) == -1) || !S_ISFIFO(state.st_mode)) {
    return;
  }
  ready.fd = HILDE_SEATBELT_HANDSHAKE_FD;
  ready.events = POLLIN;
  ready.revents = 0;
  do {
    answer = poll(&ready, 1, 0);
  } while ((answer == -1) && (errno == EINTR));
  if ((answer != 1) || ((ready.revents & POLLIN) == 0)) {
    return;
  }
  do {
    got = read(HILDE_SEATBELT_HANDSHAKE_FD, message, sizeof message);
  } while ((got == -1) && (errno == EINTR));
  if (!hilde_seatbelt_verdict(message, (long) got,
                              sandbox_check(getpid(), NULL, HILDE_SANDBOX_FILTER_NONE),
                              sandbox_check(getpid(), "file-write-create",
                                            HILDE_SANDBOX_FILTER_PATH | HILDE_SANDBOX_CHECK_NO_REPORT, "/hilde-seatbelt-probe"))) {
    return;
  }
  close(HILDE_SEATBELT_HANDSHAKE_FD);
  memcpy(&hilde_seatbelt_policy_hash, message + HILDE_SEATBELT_MAGIC_LENGTH, 8);
  memcpy(&hilde_seatbelt_taken, message + HILDE_SEATBELT_MAGIC_LENGTH + 8, 8);
  hilde_seatbelt_started = 1;
  if ((fstat(HILDE_SEATBELT_STARTED_FD, &state) == 0) && S_ISFIFO(state.st_mode)) {
    while ((write(HILDE_SEATBELT_STARTED_FD, "s", 1) == -1) && (errno == EINTR)) {
    }
    close(HILDE_SEATBELT_STARTED_FD);
  }
}

/* The profile as it is built: bytes, their number and the room for them.
   failed is set when memory ran out; such a profile is never used. */
struct hilde_seatbelt_text {
  char* bytes;
  size_t length;
  size_t room;
  int failed;
};

static void hilde_seatbelt_append(struct hilde_seatbelt_text* text, const char* bytes, size_t count) {
  extern void* realloc(void* pointer, size_t size);

  if (text->failed) {
    return;
  }
  if (count > text->room - text->length) {
    size_t room = (text->room == 0) ? 4096 : text->room;
    char* grown;

    while (count > room - text->length) {
      if (room > (SIZE_MAX / 2)) {
        text->failed = 1;
        return;
      }
      room *= 2;
    }
    grown = (char*) realloc(text->bytes, room);
    if (grown == NULL) {
      text->failed = 1;
      return;
    }
    text->bytes = grown;
    text->room = room;
  }
  memcpy(text->bytes + text->length, bytes, count);
  text->length += count;
}

static void hilde_seatbelt_put(struct hilde_seatbelt_text* text, const char* line) {
  hilde_seatbelt_append(text, line, strlen(line));
}

/* A path as a string of the profile: in double quotes, with a backslash
   before each double quote and each backslash. */
static void hilde_seatbelt_quoted(struct hilde_seatbelt_text* text, const char* path) {
  const char* at;

  hilde_seatbelt_put(text, "\"");
  for (at = path; *at != '\0'; at++) {
    if ((*at == '"') || (*at == '\\')) {
      hilde_seatbelt_put(text, "\\");
    }
    hilde_seatbelt_append(text, at, 1);
  }
  hilde_seatbelt_put(text, "\"");
}

/* One rule: the operations, then the path as a subpath or a literal. */
static void hilde_seatbelt_rule(struct hilde_seatbelt_text* text, const char* operations,
                                const char* shape, const char* path) {
  hilde_seatbelt_put(text, "(allow ");
  hilde_seatbelt_put(text, operations);
  hilde_seatbelt_put(text, " (");
  hilde_seatbelt_put(text, shape);
  hilde_seatbelt_put(text, " ");
  hilde_seatbelt_quoted(text, path);
  hilde_seatbelt_put(text, "))\n");
}

/* Resolves a path the way realpath(3) does.  Declared here with the same
   symbol <stdlib.h> gives it, which this file does not include. */
static char* hilde_seatbelt_realpath(const char* path, char* resolved) {
  extern char* realpath(const char* restrict path, char* restrict resolved) __DARWIN_EXTSN(realpath);

  return realpath(path, resolved);
}

/* Every spelling of an absolute path that Seatbelt may match it under,
   since it compares against the path with its symbolic links followed and
   /tmp, /etc and /var are links into /private: the path as given, the
   path resolved, and its directory resolved with the last name as given,
   which also carries a path that does not exist yet.  The number of
   spellings, or 0 when neither the path nor its directory resolves; a
   rule for such a path would never match, so none is written. */
static int hilde_seatbelt_spellings(const char* path, char out[HILDE_SEATBELT_SPELLINGS][PATH_MAX]) {
  char parent[PATH_MAX];
  char buffer[PATH_MAX];
  size_t size = strlen(path);
  int count = 0;
  int resolved = 0;
  int k;
  char* slash;

  if ((path[0] != '/') || (size >= PATH_MAX)) {
    return 0;
  }
  memcpy(out[count], path, size + 1);
  count++;
  if (hilde_seatbelt_realpath(path, buffer) != NULL) {
    resolved = 1;
    if (strcmp(buffer, path) != 0) {
      memcpy(out[count], buffer, strlen(buffer) + 1);
      count++;
    }
  }
  memcpy(parent, path, size + 1);
  slash = strrchr(parent, '/');
  if (slash == parent) {
    resolved = 1;
  } else if (slash != NULL) {
    const char* base = path + (slash - parent) + 1;

    *slash = '\0';
    if (hilde_seatbelt_realpath(parent, buffer) != NULL) {
      size_t head = strlen(buffer);
      size_t tail = strlen(base);

      resolved = 1;
      if (head + 1 + tail < PATH_MAX) {
        buffer[head] = '/';
        memcpy(buffer + head + 1, base, tail + 1);
        for (k = 0; k < count; k++) {
          if (strcmp(out[k], buffer) == 0) {
            break;
          }
        }
        if (k == count) {
          memcpy(out[count], buffer, strlen(buffer) + 1);
          count++;
        }
      }
    }
  }
  return resolved ? count : 0;
}

/* The rules of one path of the policy, for each of its spellings: r reads,
   w writes, truncates, removes and changes the attributes, c creates, x
   executes when the promises allow exec.  A relative path is taken from
   the working directory, as open(2) would take it.  1 when the path is in
   the profile, 0 when it could not be resolved and is not. */
static int hilde_seatbelt_path(struct hilde_seatbelt_text* text, const char* path,
                               const char* permissions, int exec) {
  char spelling[HILDE_SEATBELT_SPELLINGS][PATH_MAX];
  char absolute[PATH_MAX];
  const char* named = path;
  int count;
  int k;

  if (path[0] != '/') {
    size_t head;
    size_t tail = strlen(path);

    if (getcwd(absolute, sizeof absolute) == NULL) {
      return 0;
    }
    head = strlen(absolute);
    if (head + 1 + tail >= sizeof absolute) {
      return 0;
    }
    absolute[head] = '/';
    memcpy(absolute + head + 1, path, tail + 1);
    named = absolute;
  }
  count = hilde_seatbelt_spellings(named, spelling);
  for (k = 0; k < count; k++) {
    if (strchr(permissions, 'r') != NULL) {
      hilde_seatbelt_rule(text, "file-read*", "subpath", spelling[k]);
    }
    if (strchr(permissions, 'w') != NULL) {
      hilde_seatbelt_rule(text, "file-write-data file-write-unlink file-write-mode "
                          "file-write-times file-write-owner file-write-flags file-write-xattr",
                          "subpath", spelling[k]);
    }
    if (strchr(permissions, 'c') != NULL) {
      hilde_seatbelt_rule(text, "file-write-create", "subpath", spelling[k]);
    }
    if ((strchr(permissions, 'x') != NULL) && exec) {
      hilde_seatbelt_rule(text, "process-exec file-map-executable", "subpath", spelling[k]);
    }
  }
  return (count > 0) ? 1 : 0;
}

/* The trees of libraries a programme may load at its start, for reading:
   the system's, MacPorts' and Homebrew's.  A tree that does not exist
   costs a rule that never matches. */
static const char* const hilde_seatbelt_libraries[] = {
  "/usr/lib", "/System/Library", "/usr/local/lib", "/usr/local/opt",
  "/usr/local/Cellar", "/opt/local/lib", "/opt/homebrew/lib", "/opt/homebrew/opt"
};

/* The whole profile of a policy, into text, and the number of its paths
   that are in it.  exe is the binary, which may be read and executed. */
static int32_t hilde_seatbelt_profile(struct hilde_seatbelt_text* text, const uint8_t* grants,
                                      int32_t count, const char* promises, int32_t with_promises,
                                      const char* exe) {
  const char* at = (const char*) grants;
  int network = 1;
  int forks = 1;
  int exec = 1;
  int32_t taken = 0;
  int32_t k;
  size_t i;

  if (with_promises) {
    network = hilde_sandbox_promised(promises, "inet") || hilde_sandbox_promised(promises, "unix") ||
              hilde_sandbox_promised(promises, "dns");
    forks = hilde_sandbox_promised(promises, "proc");
    exec = hilde_sandbox_promised(promises, "exec");
  }
  hilde_seatbelt_put(text, "(version 1)\n(deny default)\n(import \"system.sb\")\n");
  hilde_seatbelt_put(text, "(allow sysctl-read)\n(allow mach-lookup)\n(allow signal (target self))\n");
  if (forks) {
    hilde_seatbelt_put(text, "(allow process-fork)\n");
  }
  if (network) {
    hilde_seatbelt_put(text, "(allow network*)\n");
  }
  for (k = 0; k < count; k++) {
    const char* permissions = at + strlen(at) + 1;

    taken += hilde_seatbelt_path(text, at, permissions, exec);
    at = permissions + strlen(permissions) + 1;
  }
  hilde_seatbelt_rule(text, "file-read* process-exec file-map-executable", "literal", exe);
  for (i = 0; i < sizeof hilde_seatbelt_libraries / sizeof hilde_seatbelt_libraries[0]; i++) {
    hilde_seatbelt_rule(text, "file-read* file-map-executable", "subpath", hilde_seatbelt_libraries[i]);
  }
  return taken;
}

static uint64_t hilde_seatbelt_mix(uint64_t hash, const uint8_t* bytes, size_t count) {
  size_t i;

  for (i = 0; i < count; i++) {
    hash ^= bytes[i];
    hash *= 1099511628211ULL;
  }
  return hash;
}

/* FNV-1a over the policy: its paths and permissions with their zero
   bytes, whether it has promises, and the promises.  It tells the
   confined process whether its policy is the one its profile was built
   from.  Not a defence against anyone who may start the programme, who
   could start it unconfined anyway. */
static uint64_t hilde_seatbelt_hash(const uint8_t* grants, int32_t count, const uint8_t* promises,
                                    int32_t with_promises) {
  const uint8_t* at = grants;
  uint64_t hash = 14695981039346656037ULL;
  uint8_t flag = (uint8_t) (with_promises ? 1 : 0);
  int32_t k;

  for (k = 0; k < count; k++) {
    size_t path = strlen((const char*) at) + 1;
    size_t permissions = strlen((const char*) at + path) + 1;

    hash = hilde_seatbelt_mix(hash, at, path + permissions);
    at += path + permissions;
  }
  hash = hilde_seatbelt_mix(hash, &flag, 1);
  return hilde_seatbelt_mix(hash, promises, strlen((const char*) promises) + 1);
}

/* The profile's name, while it exists, for the handler below. */
static char hilde_seatbelt_profile_path[64];
static const int hilde_seatbelt_signals[] = { SIGHUP, SIGINT, SIGQUIT, SIGTERM };
#define HILDE_SEATBELT_SIGNALS ((int) (sizeof hilde_seatbelt_signals / sizeof hilde_seatbelt_signals[0]))
static void (*hilde_seatbelt_saved[HILDE_SEATBELT_SIGNALS])(int);

/* A signal that ends the first process while the profile exists removes
   it first and then ends the process as the signal would have. */
static void hilde_seatbelt_on_signal(int number) {
  int saved = errno;

  if (hilde_seatbelt_profile_path[0] != '\0') {
    unlink(hilde_seatbelt_profile_path);
  }
  errno = saved;
  signal(number, SIG_DFL);
  raise(number);
}

/* Catches the signals that would leave the profile behind.  A signal the
   process ignores stays ignored. */
static void hilde_seatbelt_arm(void) {
  int k;

  for (k = 0; k < HILDE_SEATBELT_SIGNALS; k++) {
    hilde_seatbelt_saved[k] = signal(hilde_seatbelt_signals[k], SIG_IGN);
    if ((hilde_seatbelt_saved[k] != SIG_IGN) && (hilde_seatbelt_saved[k] != SIG_ERR)) {
      if (signal(hilde_seatbelt_signals[k], hilde_seatbelt_on_signal) == SIG_ERR) {
        hilde_seatbelt_saved[k] = SIG_ERR;
      }
    }
  }
}

/* Removes the profile, then gives the signals back their handlers. */
static void hilde_seatbelt_disarm(void) {
  int k;

  if (hilde_seatbelt_profile_path[0] != '\0') {
    unlink(hilde_seatbelt_profile_path);
    hilde_seatbelt_profile_path[0] = '\0';
  }
  for (k = 0; k < HILDE_SEATBELT_SIGNALS; k++) {
    if (hilde_seatbelt_saved[k] != SIG_ERR) {
      signal(hilde_seatbelt_signals[k], hilde_seatbelt_saved[k]);
    }
  }
}

/* The confined process, while the first process waits for it. */
static volatile pid_t hilde_seatbelt_child;

/* SIGTERM and SIGHUP are sent to the process that was started, which is
   the first one: they are passed on to the confined process, which ends,
   and the first process then ends as it ended.  SIGINT and SIGQUIT come
   from the terminal to both and are not passed on. */
static void hilde_seatbelt_forward(int number) {
  int saved = errno;

  if (hilde_seatbelt_child > 0) {
    kill(hilde_seatbelt_child, number);
  }
  errno = saved;
}

static void hilde_seatbelt_pass_on(int number) {
  void (*before)(int) = signal(number, SIG_IGN);

  if ((before != SIG_IGN) && (before != SIG_ERR)) {
    signal(number, hilde_seatbelt_forward);
  }
}

static int hilde_seatbelt_write_all(int fd, const char* bytes, size_t count) {
  while (count > 0) {
    ssize_t written = write(fd, bytes, count);

    if (written == -1) {
      if (errno == EINTR) {
        continue;
      }
      return 0;
    }
    bytes += written;
    count -= (size_t) written;
  }
  return 1;
}

/* The child after fork: the two pipes onto their fixed descriptors, then
   sandbox-exec with the profile, the binary and the programme's arguments.
   It never returns. */
static _Noreturn void hilde_seatbelt_exec(int handshake, int started, const char* profile, const char* exe) {
  extern void* calloc(size_t count, size_t size);
  extern size_t hilde_get_argc(void);
  extern hilde_span_t hilde_get_nth_arg(size_t n);
  size_t argc = hilde_get_argc();
  char** argv;
  size_t k;

  /* Both are moved above the two fixed numbers first, so that placing one
     cannot close the other. */
  handshake = fcntl(handshake, F_DUPFD, HILDE_SEATBELT_STARTED_FD + 1);
  started = fcntl(started, F_DUPFD, HILDE_SEATBELT_STARTED_FD + 1);
  if ((handshake == -1) || (started == -1)) {
    _exit(127);
  }
  if ((dup2(handshake, HILDE_SEATBELT_HANDSHAKE_FD) == -1) ||
      (dup2(started, HILDE_SEATBELT_STARTED_FD) == -1)) {
    _exit(127);
  }
  close(handshake);
  close(started);
  if ((fcntl(HILDE_SEATBELT_HANDSHAKE_FD, F_SETFD, 0) == -1) ||
      (fcntl(HILDE_SEATBELT_STARTED_FD, F_SETFD, 0) == -1)) {
    _exit(127);
  }
  argv = (char**) calloc(argc + 4, sizeof(char*));
  if (argv == NULL) {
    _exit(127);
  }
  argv[0] = (char*) "sandbox-exec";
  argv[1] = (char*) "-f";
  argv[2] = (char*) profile;
  argv[3] = (char*) exe;
  for (k = 1; k < argc; k++) {
    argv[k + 3] = (char*) hilde_get_nth_arg(k).data;
  }
  argv[argc + 3] = NULL;
  execv("/usr/bin/sandbox-exec", argv);
  _exit(127);
}

/* Starts the programme again under the profile.  When the confined
   process says it has started, this process waits for it and ends as it
   ends, and never returns.  -2 when it could not be started; nothing of
   the programme ran under the profile then, and this process goes on
   unconfined. */
static int32_t hilde_seatbelt_restart(const struct hilde_seatbelt_text* text, const char* exe,
                                      uint64_t hash, int32_t taken) {
  extern int mkstemp(char* template);
  static const char pattern[] = "/tmp/hilde-sandbox-XXXXXX";
  unsigned char message[HILDE_SEATBELT_MESSAGE_LENGTH];
  uint64_t paths = (uint64_t) taken;
  int handshake[2];
  int started[2];
  int status = 0;
  int reaped = 1;
  int fd;
  ssize_t got;
  char byte;
  pid_t pid;

  memcpy(hilde_seatbelt_profile_path, pattern, sizeof pattern);
  hilde_seatbelt_arm();
  fd = mkstemp(hilde_seatbelt_profile_path);
  if (fd == -1) {
    hilde_seatbelt_profile_path[0] = '\0';
    hilde_seatbelt_disarm();
    return -2;
  }
  if (!hilde_seatbelt_write_all(fd, text->bytes, text->length)) {
    close(fd);
    hilde_seatbelt_disarm();
    return -2;
  }
  if (close(fd) == -1) {
    hilde_seatbelt_disarm();
    return -2;
  }
  memcpy(message, HILDE_SEATBELT_MAGIC, HILDE_SEATBELT_MAGIC_LENGTH);
  memcpy(message + HILDE_SEATBELT_MAGIC_LENGTH, &hash, 8);
  memcpy(message + HILDE_SEATBELT_MAGIC_LENGTH + 8, &paths, 8);
  if (pipe(handshake) == -1) {
    hilde_seatbelt_disarm();
    return -2;
  }
  if (pipe(started) == -1) {
    close(handshake[0]);
    close(handshake[1]);
    hilde_seatbelt_disarm();
    return -2;
  }
  if ((fcntl(handshake[0], F_SETFD, FD_CLOEXEC) == -1) || (fcntl(handshake[1], F_SETFD, FD_CLOEXEC) == -1) ||
      (fcntl(started[0], F_SETFD, FD_CLOEXEC) == -1) || (fcntl(started[1], F_SETFD, FD_CLOEXEC) == -1) ||
      !hilde_seatbelt_write_all(handshake[1], (const char*) message, sizeof message)) {
    close(handshake[0]);
    close(handshake[1]);
    close(started[0]);
    close(started[1]);
    hilde_seatbelt_disarm();
    return -2;
  }
  close(handshake[1]);
  hilde_flush_output();
  pid = fork();
  if (pid == -1) {
    close(handshake[0]);
    close(started[0]);
    close(started[1]);
    hilde_seatbelt_disarm();
    return -2;
  }
  if (pid == 0) {
    close(started[0]);
    hilde_seatbelt_exec(handshake[0], started[1], hilde_seatbelt_profile_path, exe);
  }
  close(handshake[0]);
  close(started[1]);
  do {
    got = read(started[0], &byte, 1);
  } while ((got == -1) && (errno == EINTR));
  close(started[0]);
  /* sandbox-exec has read the profile once the programme has started, or
     has given up; either way the file is no longer needed. */
  hilde_seatbelt_disarm();
  if (got == 1) {
    hilde_seatbelt_child = pid;
    hilde_seatbelt_pass_on(SIGTERM);
    hilde_seatbelt_pass_on(SIGHUP);
  }
  while (waitpid(pid, &status, 0) == -1) {
    if (errno != EINTR) {
      reaped = 0;
      break;
    }
  }
  if (got != 1) {
    return -2;
  }
  if (reaped && WIFEXITED(status)) {
    _exit(WEXITSTATUS(status));
  }
  if (reaped && WIFSIGNALED(status)) {
    signal(WTERMSIG(status), SIG_DFL);
    raise(WTERMSIG(status));
  }
  _exit(1);
}
#endif

/* Confines the process with Seatbelt.  grants holds count paths and their
   permissions, each ending in a zero byte, length bytes in all, or with
   no path a single zero byte; promises holds the words of the policy when
   with_promises is 1.  A block of another form is -2, before any walk
   over it.  In the process started under the profile: the number of
   paths in the profile, when it was built from this policy, else -2.  In
   the first process it does not return when the confined one started,
   and answers -2 when it did not.  -1 on a platform without Seatbelt. */
int32_t hilde_sandbox_seatbelt(uint8_t* grants, size_t length, int32_t count, uint8_t* promises,
                               int32_t with_promises) {
#if defined(HILDE_SANDBOX_SEATBELT)
  {
    extern void free(void* pointer);
    struct hilde_seatbelt_text text = { NULL, 0, 0, 0 };
    char named[PATH_MAX];
    char exe[PATH_MAX];
    uint32_t size = sizeof named;
    uint64_t hash;
    int32_t taken;
    int32_t answer;

    if (HILDE_IN_LIBRARY || (count < 0)) {
      return -2;
    }
    if ((count == 0) ? (grants == NULL || length != 1 || grants[0] != 0)
                     : !hilde_packed_holds(grants, length, (size_t) count * 2)) {
      return -2;
    }
    hash = hilde_seatbelt_hash(grants, count, promises, with_promises);
    if (hilde_seatbelt_started) {
      answer = -2;
      if (!hilde_seatbelt_claimed && (hilde_seatbelt_policy_hash == hash) &&
          (hilde_seatbelt_taken <= (uint64_t) count)) {
        answer = (int32_t) hilde_seatbelt_taken;
      }
      hilde_seatbelt_claimed = 1;
      return answer;
    }
    /* The name the binary was started by may be relative or a link; both
       processes resolve it, so that their profiles name the same file. */
    if ((_NSGetExecutablePath(named, &size) != 0) || (hilde_seatbelt_realpath(named, exe) == NULL)) {
      return -2;
    }
    taken = hilde_seatbelt_profile(&text, grants, count, (const char*) promises, with_promises, exe);
    if (text.failed) {
      free(text.bytes);
      return -2;
    }
    answer = hilde_seatbelt_restart(&text, exe, hash, taken);
    free(text.bytes);
    return answer;
  }
#else
  (void) grants;
  (void) length;
  (void) count;
  (void) promises;
  (void) with_promises;
  return -1;
#endif
}

/* FreeBSD: Capsicum.  cap_enter puts the process into capability mode,
   where no call may name a path or an address of the global namespaces:
   open, stat, connect and the like fail, and only the descriptors the
   process already holds are reachable, each within its rights.  The paths
   of the policy are therefore opened before, each as an O_PATH descriptor
   limited to the rights of its permissions, and the runtime's own calls on
   paths are routed through them: a path below a granted one is resolved
   with the *at call from that descriptor, and the kernel refuses a name
   that leaves it.  A path below no grant is refused as access denied.  Calls
   made by C libraries on their own, such as a database opening its file,
   are not routed and fail in capability mode, which narrows what is
   reachable and never widens it.

   Capability mode allows neither a connection to a new address nor exec,
   so it is entered only for promises that need neither; with other
   promises, or none, nothing is applied and the report says why.  The
   standard descriptors are limited too: 0 to reading, 1 and 2 to
   writing.  A descriptor the programme opened before is left as it is. */
#if defined(HILDE_SANDBOX_CAPSICUM)
/* The promises capability mode cannot keep: they need a connection to a
   new address, a name lookup, exec, or a global table of the system. */
static const char* const hilde_capsicum_blocking[] = {
  "inet", "unix", "dns", "exec", "getpw", "route", "wroute", "mcast", "pf", "bpf", "settime"
};

/* The rights of a grant: every grant may be looked into and asked about;
   r reads, w writes, truncates, syncs, removes and changes the mode, c
   creates, makes directories and links and removes.  x maps to nothing:
   capability mode allows no exec. */
static void hilde_capsicum_rights(cap_rights_t* rights, const char* permissions) {
  cap_rights_init(rights, CAP_LOOKUP, CAP_FSTAT, CAP_FSTATAT, CAP_FCNTL, CAP_EVENT, CAP_SEEK, CAP_FLOCK);
  if (strchr(permissions, 'r') != NULL) {
    cap_rights_set(rights, CAP_READ, CAP_MMAP_R);
  }
  if (strchr(permissions, 'w') != NULL) {
    cap_rights_set(rights, CAP_WRITE, CAP_FTRUNCATE, CAP_FSYNC, CAP_UNLINKAT, CAP_RENAMEAT_SOURCE,
                   CAP_FCHMOD, CAP_FCHMODAT, CAP_FUTIMESAT);
  }
  if (strchr(permissions, 'c') != NULL) {
    cap_rights_set(rights, CAP_CREATE, CAP_MKDIRAT, CAP_SYMLINKAT, CAP_LINKAT_SOURCE, CAP_LINKAT_TARGET,
                   CAP_RENAMEAT_TARGET, CAP_UNLINKAT, CAP_FCHMOD, CAP_FSYNC);
  }
}

#endif

/* Enters capability mode with the paths of the policy.  grants holds
   count paths and their permissions, each ending in a zero byte, and
   promises the words of the policy when with_promises is 1.  The number
   of paths opened when the process is in capability mode afterwards; -3
   when the promises are missing or need what capability mode forbids, so
   that nothing was applied; -2 when capability mode could not be entered
   or already was; -1 on a platform without Capsicum. */
int32_t hilde_sandbox_capsicum(uint8_t* grants, int32_t count, uint8_t* promises, int32_t with_promises) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  {
    extern void* calloc(size_t count, size_t size);
    extern void* malloc(size_t size);
    extern void free(void* pointer);
    const char* at = (const char*) grants;
    struct hilde_capsicum_grant* opened;
    cap_rights_t rights;
    int32_t taken = 0;
    int32_t k;
    size_t i;
    int fd;

    if (HILDE_IN_LIBRARY || (count < 0) || hilde_capsicum_entered) {
      return -2;
    }
    if (!with_promises) {
      return -3;
    }
    for (i = 0; i < sizeof hilde_capsicum_blocking / sizeof hilde_capsicum_blocking[0]; i++) {
      if (hilde_sandbox_promised((const char*) promises, hilde_capsicum_blocking[i])) {
        return -3;
      }
    }
    if (getcwd(hilde_capsicum_cwd, sizeof hilde_capsicum_cwd) == NULL) {
      hilde_capsicum_cwd[0] = '\0';
    }
    opened = (count > 0) ? (struct hilde_capsicum_grant*) calloc((size_t) count, sizeof *opened) : NULL;
    if ((count > 0) && (opened == NULL)) {
      return -2;
    }
    for (k = 0; k < count; k++) {
      const char* permissions = at + strlen(at) + 1;
      char absolute[PATH_MAX];
      struct stat info;

      if (hilde_capsicum_absolute(at, hilde_capsicum_cwd, absolute)) {
        fd = open(absolute, O_PATH | O_CLOEXEC);
        if (fd != -1) {
          size_t length = strlen(absolute);
          char* copy = (char*) malloc(length + 1);

          hilde_capsicum_rights(&rights, permissions);
          if ((copy != NULL) && (fstat(fd, &info) == 0) && (cap_rights_limit(fd, &rights) == 0)) {
            memcpy(copy, absolute, length + 1);
            opened[taken].path = copy;
            opened[taken].length = length;
            opened[taken].fd = fd;
            opened[taken].directory = S_ISDIR(info.st_mode) ? 1 : 0;
            taken++;
          } else {
            free(copy);
            close(fd);
          }
        }
      }
      at = permissions + strlen(permissions) + 1;
    }
    /* The standard descriptors: a closed one is left closed. */
    cap_rights_init(&rights, CAP_READ, CAP_FSTAT, CAP_FCNTL, CAP_EVENT, CAP_SEEK, CAP_IOCTL);
    (void) cap_rights_limit(0, &rights);
    cap_rights_init(&rights, CAP_WRITE, CAP_FSTAT, CAP_FCNTL, CAP_EVENT, CAP_SEEK, CAP_IOCTL, CAP_FSYNC);
    (void) cap_rights_limit(1, &rights);
    (void) cap_rights_limit(2, &rights);
    hilde_capsicum_grants = opened;
    hilde_capsicum_count = taken;
    if (cap_enter() != 0) {
      for (k = 0; k < taken; k++) {
        close(opened[k].fd);
        free(opened[k].path);
      }
      free(opened);
      hilde_capsicum_grants = NULL;
      hilde_capsicum_count = 0;
      return -2;
    }
    hilde_capsicum_entered = 1;
    return taken;
  }
#else
  (void) grants;
  (void) count;
  (void) promises;
  (void) with_promises;
  return -1;
#endif
}

/* 1 when the process is in capability mode, as the kernel answers, 0 when
   it is not, -1 on a platform without Capsicum. */
int32_t hilde_sandbox_query_capsicum(void) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  {
    u_int mode = 0;

    if (cap_getmode(&mode) != 0) {
      return -1;
    }
    return (mode != 0) ? 1 : 0;
  }
#else
  return -1;
#endif
}

/* Linux: Landlock and seccomp.  Neither has a wrapper in the C library, so
   both go through syscall(2), which glibc declares only outside -std=c17;
   each function below therefore declares it itself.  The kernel headers
   bring structs and numbers only, no function that a Hilde module could
   declare a second time. */
#if defined(__linux__) && defined(__has_include)
#if __has_include(<linux/landlock.h>) && __has_include(<linux/seccomp.h>)
#define HILDE_SANDBOX_LINUX 1
#endif
#endif

#if defined(HILDE_SANDBOX_LINUX)
#include <sys/syscall.h>
#include <linux/landlock.h>
#include <linux/seccomp.h>
#include <linux/filter.h>
#include <linux/audit.h>

/* Fixed ABI values, defined for headers that predate them. */
#ifndef LANDLOCK_CREATE_RULESET_VERSION
#define LANDLOCK_CREATE_RULESET_VERSION (1U << 0)
#endif
#ifndef LANDLOCK_ACCESS_FS_MAKE_SOCK
#define LANDLOCK_ACCESS_FS_MAKE_SOCK (1ULL << 9)
#endif
#ifndef LANDLOCK_ACCESS_FS_MAKE_FIFO
#define LANDLOCK_ACCESS_FS_MAKE_FIFO (1ULL << 10)
#endif
#ifndef LANDLOCK_ACCESS_FS_MAKE_BLOCK
#define LANDLOCK_ACCESS_FS_MAKE_BLOCK (1ULL << 11)
#endif
#ifndef LANDLOCK_ACCESS_FS_MAKE_SYM
#define LANDLOCK_ACCESS_FS_MAKE_SYM (1ULL << 12)
#endif
#ifndef LANDLOCK_ACCESS_FS_TRUNCATE
#define LANDLOCK_ACCESS_FS_TRUNCATE (1ULL << 14)
#endif
#ifndef SECCOMP_SET_MODE_FILTER
#define SECCOMP_SET_MODE_FILTER 1
#endif
#ifndef SECCOMP_FILTER_FLAG_TSYNC
#define SECCOMP_FILTER_FLAG_TSYNC (1UL << 0)
#endif

/* Every right of Landlock ABI 1.  The ruleset handles all of them, because
   a right the ruleset does not handle is not restricted anywhere, whatever
   the rules say.  LANDLOCK_ACCESS_FS_TRUNCATE comes with ABI 3; asking
   for a right the kernel does not know costs the whole ruleset (EINVAL). */
#define HILDE_LANDLOCK_ABI1 ( \
  LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR | \
  LANDLOCK_ACCESS_FS_WRITE_FILE | LANDLOCK_ACCESS_FS_REMOVE_FILE | \
  LANDLOCK_ACCESS_FS_REMOVE_DIR | LANDLOCK_ACCESS_FS_MAKE_CHAR | \
  LANDLOCK_ACCESS_FS_MAKE_DIR | LANDLOCK_ACCESS_FS_MAKE_REG | \
  LANDLOCK_ACCESS_FS_MAKE_SOCK | LANDLOCK_ACCESS_FS_MAKE_FIFO | \
  LANDLOCK_ACCESS_FS_MAKE_BLOCK | LANDLOCK_ACCESS_FS_MAKE_SYM | \
  LANDLOCK_ACCESS_FS_EXECUTE)

/* O_PATH and O_CLOEXEC, which glibc shows only with _GNU_SOURCE.  The
   values are those of the generic Linux ABI, which x86_64, i386, aarch64
   and arm use.  On another architecture HILDE_SANDBOX_LANDLOCK_PATHS stays
   undefined and no path rule is built at all, rather than built with a
   guessed value. */
#if defined(__x86_64__) || defined(__i386__) || defined(__aarch64__) || defined(__arm__)
#define HILDE_SANDBOX_LANDLOCK_PATHS 1
#define HILDE_O_PATH 010000000
#define HILDE_O_CLOEXEC 02000000
#endif

/* The architecture this binary's system call numbers belong to: a seccomp
   filter compares numbers, and the same number is another call under
   another ABI.  Only these get a filter. */
#if defined(__x86_64__)
#define HILDE_SECCOMP_ARCH AUDIT_ARCH_X86_64
#elif defined(__i386__)
#define HILDE_SECCOMP_ARCH AUDIT_ARCH_I386
#elif defined(__aarch64__)
#define HILDE_SECCOMP_ARCH AUDIT_ARCH_AARCH64
#elif defined(__arm__)
#define HILDE_SECCOMP_ARCH AUDIT_ARCH_ARM
#endif

/* x32 system calls arrive as AUDIT_ARCH_X86_64 with this bit set. */
#define HILDE_X32_SYSCALL_BIT 0x40000000

static uint64_t hilde_sandbox_landlock_mask(int32_t abi) {
  uint64_t mask = HILDE_LANDLOCK_ABI1;

  if (abi >= 3) {
    mask |= LANDLOCK_ACCESS_FS_TRUNCATE;
  }
  return mask;
}

#if defined(HILDE_SANDBOX_LANDLOCK_PATHS)
static uint64_t hilde_sandbox_directory_rights(const char* permissions) {
  uint64_t access = 0;

  if (strchr(permissions, 'r') != NULL) {
    access |= LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR;
  }
  if (strchr(permissions, 'w') != NULL) {
    access |= LANDLOCK_ACCESS_FS_WRITE_FILE | LANDLOCK_ACCESS_FS_REMOVE_FILE |
              LANDLOCK_ACCESS_FS_REMOVE_DIR | LANDLOCK_ACCESS_FS_TRUNCATE;
  }
  if (strchr(permissions, 'c') != NULL) {
    access |= LANDLOCK_ACCESS_FS_MAKE_CHAR | LANDLOCK_ACCESS_FS_MAKE_DIR |
              LANDLOCK_ACCESS_FS_MAKE_REG | LANDLOCK_ACCESS_FS_MAKE_SOCK |
              LANDLOCK_ACCESS_FS_MAKE_FIFO | LANDLOCK_ACCESS_FS_MAKE_BLOCK |
              LANDLOCK_ACCESS_FS_MAKE_SYM;
  }
  if (strchr(permissions, 'x') != NULL) {
    access |= LANDLOCK_ACCESS_FS_EXECUTE;
  }
  return access;
}

/* A rule on a file that is not a directory takes only the rights that
   apply to a file; a directory right there is EINVAL. */
static uint64_t hilde_sandbox_file_rights(const char* permissions) {
  uint64_t access = 0;

  if (strchr(permissions, 'r') != NULL) {
    access |= LANDLOCK_ACCESS_FS_READ_FILE;
  }
  if (strchr(permissions, 'w') != NULL) {
    access |= LANDLOCK_ACCESS_FS_WRITE_FILE | LANDLOCK_ACCESS_FS_TRUNCATE;
  }
  if (strchr(permissions, 'x') != NULL) {
    access |= LANDLOCK_ACCESS_FS_EXECUTE;
  }
  return access;
}
#endif
#endif

/* The Landlock ABI of this kernel: 1 and up, 0 when the kernel has none,
   was booted without it or refused the question, -1 on a platform without
   Landlock. */
int32_t hilde_sandbox_landlock_abi(void) {
#if defined(HILDE_SANDBOX_LINUX)
  {
    extern long syscall(long number, ...);

    long abi = syscall(__NR_landlock_create_ruleset, NULL, (size_t) 0,
                       (uint32_t) LANDLOCK_CREATE_RULESET_VERSION);

    if (abi < 1) {
      return 0;
    }
    return (abi > 1000) ? 1000 : (int32_t) abi;
  }
#else
  return -1;
#endif
}

/* A new ruleset handling every right the ABI knows: its descriptor, or -1. */
int32_t hilde_sandbox_landlock_open(int32_t abi) {
#if defined(HILDE_SANDBOX_LINUX)
  {
    extern long syscall(long number, ...);

    struct landlock_ruleset_attr attr;
    long fd;

    if (abi < 1) {
      return -1;
    }
    memset(&attr, 0, sizeof(attr));
    attr.handled_access_fs = hilde_sandbox_landlock_mask(abi);
    fd = syscall(__NR_landlock_create_ruleset, &attr, sizeof(attr), (uint32_t) 0);
    return (fd < 0) ? -1 : (int32_t) fd;
  }
#else
  (void) abi;
  return -1;
#endif
}

#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SANDBOX_LANDLOCK_PATHS)
/* The descriptor a rule for one path is made on, with the rights the
   rule grants in access, or -1 when the path is not covered: it does not
   exist, it is not a directory and c (create) was asked for, or the
   kernel refused to look at it.  A directory gets the directory rights,
   any other file the file rights.
   Landlock grants creation only for everything beneath a directory, so c
   on a file cannot be held to that one name.  Granting it on the parent
   would open every file there for reading, writing and removal, so such a
   path is reported not covered instead.
   The path is opened first and its kind read from the open descriptor
   with fstat(2).  A stat of the name before the open would leave a moment
   in which a file could be swapped for a directory, which would then get
   the file rights for everything beneath it. */
static int hilde_sandbox_landlock_target(const char* name, const char* rights,
                                         uint64_t* access) {
  struct stat st;
  int fd;

  *access = 0;
  fd = open(name, HILDE_O_PATH | HILDE_O_CLOEXEC);
  if (fd < 0) {
    return -1;
  }
  if (fstat(fd, &st) != 0) {
    close(fd);
    return -1;
  }
  if (S_ISDIR(st.st_mode)) {
    *access = hilde_sandbox_directory_rights(rights);
  } else if (strchr(rights, 'c') == NULL) {
    *access = hilde_sandbox_file_rights(rights);
  } else {
    close(fd);
    return -1;
  }
  return fd;
}
#endif

/* One path as a rule of the ruleset, made on the descriptor and with the
   rights of hilde_sandbox_landlock_target.  1 when the path is covered, 0
   when it is not: the target says so, or the rule was refused. */
int32_t hilde_sandbox_landlock_add(int32_t ruleset, int32_t abi,
                                   uint8_t* path,
                                   uint8_t* permissions) {
#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SANDBOX_LANDLOCK_PATHS)
  {
    extern long syscall(long number, ...);

    struct landlock_path_beneath_attr rule;
    uint64_t access = 0;
    int fd;
    long added;

    fd = hilde_sandbox_landlock_target((const char*) path,
                                       (const char*) permissions, &access);
    if (fd < 0) {
      return 0;
    }
    access &= hilde_sandbox_landlock_mask(abi);
    if (access == 0) {
      /* Nothing this ruleset handles was asked for: covered. */
      close(fd);
      return 1;
    }
    memset(&rule, 0, sizeof(rule));
    rule.allowed_access = access;
    rule.parent_fd = fd;
    added = syscall(__NR_landlock_add_rule, (int) ruleset,
                    LANDLOCK_RULE_PATH_BENEATH, &rule, (uint32_t) 0);
    close(fd);
    return (added == 0) ? 1 : 0;
  }
#else
  (void) ruleset;
  (void) abi;
  (void) path;
  (void) permissions;
  return 0;
#endif
}

/* Restricts this thread, and every thread and child it starts later, to
   the ruleset, and closes it.  1 on success, 0 when refused, -1 without
   Landlock. */
int32_t hilde_sandbox_landlock_restrict(int32_t ruleset) {
#if defined(HILDE_SANDBOX_LINUX)
  {
    extern long syscall(long number, ...);

    long done = syscall(__NR_landlock_restrict_self, (int) ruleset, (uint32_t) 0);

    close(ruleset);
    return (done == 0) ? 1 : 0;
  }
#else
  (void) ruleset;
  return -1;
#endif
}

/* Closes a ruleset that is not applied. */
int32_t hilde_sandbox_landlock_close(int32_t ruleset) {
#if defined(HILDE_SANDBOX_LINUX)
  return (close(ruleset) == 0) ? 1 : 0;
#else
  (void) ruleset;
  return -1;
#endif
}

#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SECCOMP_ARCH)
/* One call of the deny list: EPERM for it, the next test for every other. */
#define HILDE_SECCOMP_DENY(nr) \
  BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, (nr), 0, 1), \
  BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | (EPERM & SECCOMP_RET_DATA))
#endif

int32_t hilde_sandbox_thread_count(void);

/* Whether a filter installed for the calling thread alone confines the
   process: only when the process has that one thread.  An unknown count
   (-1) is not one. */
int32_t hilde_sandbox_fallback_confines(int32_t threads) {
  return (threads == 1) ? 1 : 0;
}

/* The seccomp filter: a call of a foreign architecture or of x32 is
   refused, the calls below answer EPERM, and every other call is allowed.
   They are 34, or fewer where the kernel headers lack a number an #ifdef
   asks for: tracing and reading another process, loading a kernel or a
   module, mounting, swapping, rebooting and naming the host, and the
   calls that widen what the kernel is asked to do for an unprivileged
   process: io_uring, programmes loaded with bpf, performance counters,
   userfaultfd, new namespaces, the kernel keyring and opening a file by
   its handle.  Installed for every thread of the process
   (SECCOMP_FILTER_FLAG_TSYNC).  1 when installed, 0 when refused, -1 when
   this platform or architecture has no filter. */
int32_t hilde_sandbox_seccomp(void) {
#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SECCOMP_ARCH)
  {
    extern long syscall(long number, ...);
    extern int prctl(int option, ...);

    struct sock_filter filter[] = {
      BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, arch)),
      BPF_JUMP(BPF_JMP | BPF_JEQ | BPF_K, HILDE_SECCOMP_ARCH, 1, 0),
      BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | (EPERM & SECCOMP_RET_DATA)),
      BPF_STMT(BPF_LD | BPF_W | BPF_ABS, offsetof(struct seccomp_data, nr)),
      BPF_JUMP(BPF_JMP | BPF_JGE | BPF_K, HILDE_X32_SYSCALL_BIT, 0, 1),
      BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ERRNO | (EPERM & SECCOMP_RET_DATA)),
      HILDE_SECCOMP_DENY(__NR_ptrace),
      HILDE_SECCOMP_DENY(__NR_process_vm_readv),
      HILDE_SECCOMP_DENY(__NR_process_vm_writev),
#ifdef __NR_pidfd_getfd
      HILDE_SECCOMP_DENY(__NR_pidfd_getfd),
#endif
#ifdef __NR_kcmp
      HILDE_SECCOMP_DENY(__NR_kcmp),
#endif
      HILDE_SECCOMP_DENY(__NR_kexec_load),
#ifdef __NR_kexec_file_load
      HILDE_SECCOMP_DENY(__NR_kexec_file_load),
#endif
      HILDE_SECCOMP_DENY(__NR_init_module),
      HILDE_SECCOMP_DENY(__NR_finit_module),
      HILDE_SECCOMP_DENY(__NR_delete_module),
      HILDE_SECCOMP_DENY(__NR_mount),
      HILDE_SECCOMP_DENY(__NR_umount2),
      HILDE_SECCOMP_DENY(__NR_pivot_root),
#ifdef __NR_fsopen
      HILDE_SECCOMP_DENY(__NR_fsopen),
#endif
#ifdef __NR_fsconfig
      HILDE_SECCOMP_DENY(__NR_fsconfig),
#endif
#ifdef __NR_fsmount
      HILDE_SECCOMP_DENY(__NR_fsmount),
#endif
#ifdef __NR_move_mount
      HILDE_SECCOMP_DENY(__NR_move_mount),
#endif
#ifdef __NR_open_tree
      HILDE_SECCOMP_DENY(__NR_open_tree),
#endif
      HILDE_SECCOMP_DENY(__NR_reboot),
      HILDE_SECCOMP_DENY(__NR_swapon),
      HILDE_SECCOMP_DENY(__NR_swapoff),
      HILDE_SECCOMP_DENY(__NR_sethostname),
      HILDE_SECCOMP_DENY(__NR_setdomainname),
#ifdef __NR_io_uring_setup
      HILDE_SECCOMP_DENY(__NR_io_uring_setup),
#endif
#ifdef __NR_io_uring_enter
      HILDE_SECCOMP_DENY(__NR_io_uring_enter),
#endif
#ifdef __NR_bpf
      HILDE_SECCOMP_DENY(__NR_bpf),
#endif
#ifdef __NR_perf_event_open
      HILDE_SECCOMP_DENY(__NR_perf_event_open),
#endif
#ifdef __NR_userfaultfd
      HILDE_SECCOMP_DENY(__NR_userfaultfd),
#endif
      HILDE_SECCOMP_DENY(__NR_unshare),
#ifdef __NR_setns
      HILDE_SECCOMP_DENY(__NR_setns),
#endif
      HILDE_SECCOMP_DENY(__NR_keyctl),
      HILDE_SECCOMP_DENY(__NR_add_key),
#ifdef __NR_name_to_handle_at
      HILDE_SECCOMP_DENY(__NR_name_to_handle_at),
#endif
#ifdef __NR_open_by_handle_at
      HILDE_SECCOMP_DENY(__NR_open_by_handle_at),
#endif
      BPF_STMT(BPF_RET | BPF_K, SECCOMP_RET_ALLOW),
    };
    struct sock_fprog program;

    program.len = (unsigned short) (sizeof(filter) / sizeof(filter[0]));
    program.filter = filter;
    if (syscall(__NR_seccomp, (unsigned int) SECCOMP_SET_MODE_FILTER,
                (unsigned int) SECCOMP_FILTER_FLAG_TSYNC, &program) == 0) {
      return 1;
    }
    /* A kernel without the seccomp call, or without
       SECCOMP_FILTER_FLAG_TSYNC: the older way, which installs the filter
       for this thread only, and so confines the process only while it has
       no other thread. */
    if ((errno == ENOSYS) || (errno == EINVAL)) {
      if (hilde_sandbox_fallback_confines(hilde_sandbox_thread_count())
          && prctl(HILDE_PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &program) == 0) {
        return 1;
      }
    }
    return 0;
  }
#else
  return -1;
#endif
}

/* Whether a call the filter refuses is refused: one byte of this process's
   own memory read through process_vm_readv, which needs no privilege and
   which the filter answers with EPERM.  1 when it was refused so, 0 when
   it went through, -1 when this platform cannot be asked or the call
   failed otherwise.  PR_GET_SECCOMP is not used: it says only that some
   filter confines the thread, and in a container one does so before this
   process installs its own. */
int32_t hilde_sandbox_query_seccomp(void) {
#if defined(HILDE_SANDBOX_LINUX)
  {
    extern long syscall(long number, ...);

    /* The layout of struct iovec, which <sys/uio.h> would bring along with
       declarations of readv and writev. */
    struct hilde_iovec {
      void* base;
      size_t length;
    };
    static uint8_t from = 1;
    uint8_t into = 0;
    struct hilde_iovec local;
    struct hilde_iovec remote;
    long got;

    local.base = &into;
    local.length = 1;
    remote.base = &from;
    remote.length = 1;
    errno = 0;
    got = syscall(__NR_process_vm_readv, (long) getpid(), &local, 1UL, &remote, 1UL, 0UL);
    if (got == 1) {
      return 0;
    }
    return ((got < 0) && (errno == EPERM)) ? 1 : -1;
  }
#else
  return -1;
#endif
}

/* For the tests of the filter, which call it from outside: whether
   unshare with no flags, which changes nothing and needs no privilege, is
   refused.  1 when it answers EPERM, 0 when it went through, -1 when this
   platform or architecture has no filter or the call failed otherwise. */
int32_t hilde_sandbox_test_unshare_refused(void) {
#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SECCOMP_ARCH)
  {
    extern long syscall(long number, ...);
    long got;

    errno = 0;
    got = syscall(__NR_unshare, 0L);
    if (got == 0) {
      return 0;
    }
    return ((got < 0) && (errno == EPERM)) ? 1 : -1;
  }
#else
  return -1;
#endif
}

/* The number of threads of this process, from /proc/self/task on Linux
   and from task_threads on macOS; -1 when it cannot be counted.  Landlock confines the thread that applies it and the
   threads it starts later, not those already running, so the caller must
   know whether there are any.  A readdir that fails ends the list early:
   it is told from the end by errno, and a count it cut short would be too
   low, so it gives -1. */
int32_t hilde_sandbox_thread_count(void) {
#if defined(__linux__)
  {
    DIR* tasks = opendir("/proc/self/task");
    struct dirent* entry;
    int32_t count = 0;

    if (tasks == NULL) {
      return -1;
    }
    for (;;) {
      errno = 0;
      entry = readdir(tasks);
      if (entry == NULL) {
        break;
      }
      if (entry->d_name[0] != '.') {
        count++;
      }
    }
    if (errno != 0) {
      closedir(tasks);
      return -1;
    }
    closedir(tasks);
    return count;
  }
#elif defined(HILDE_SANDBOX_SEATBELT)
  {
    thread_act_array_t threads;
    mach_msg_type_number_t count = 0;
    mach_msg_type_number_t k;
    int whole = 1;

    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS) {
      return -1;
    }
    for (k = 0; k < count; k++) {
      if (mach_port_deallocate(mach_task_self(), threads[k]) != KERN_SUCCESS) {
        whole = 0;
      }
    }
    if (vm_deallocate(mach_task_self(), (vm_address_t) threads,
                      (vm_size_t) count * sizeof(thread_act_t)) != KERN_SUCCESS) {
      whole = 0;
    }
    if (!whole || (count > INT32_MAX)) {
      return -1;
    }
    return (int32_t) count;
  }
#else
  return -1;
#endif
}
