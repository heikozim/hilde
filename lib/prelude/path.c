/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The runtime's calls on paths, routed through the grants of Capsicum
 * in capability mode on FreeBSD and plain everywhere else.
 */

#include "internal.h"

/* The size of a path buffer: PATH_MAX where the headers give it, as on
   FreeBSD, and the 4096 of Linux where -std=c17 hides it. */
#if defined(PATH_MAX)
#define HILDE_PATH_SIZE PATH_MAX
#else
#define HILDE_PATH_SIZE 4096
#endif

/* path made absolute from the working directory into out and cleaned by
   its letters alone: no empty name, no "." and no ".." is left, a ".."
   takes the name before it away and stays at the root, and no slash ends
   it but the root's.  A grant and a path asked for are cleaned the same
   way, so that "." and "notes.txt" meet.  The cleaning only picks the
   grant; the kernel resolves the rest below the grant's descriptor and
   refuses a name that leaves it, so it never widens what is reachable.
   0 when it does not fit or when a relative path meets a working
   directory that is not absolute: each name then gains a slash, and the
   result would no longer fit the length checked. */
static __attribute__((unused)) int hilde_capsicum_absolute(const char* path, const char* cwd, char out[HILDE_PATH_SIZE]) {
  char joined[HILDE_PATH_SIZE];
  size_t length;
  size_t used = 0;
  size_t at = 0;

  if (path[0] == '/') {
    length = strlen(path);
    if (length >= HILDE_PATH_SIZE) {
      return 0;
    }
    memcpy(joined, path, length + 1);
  } else {
    size_t head = strlen(cwd);
    size_t tail = strlen(path);

    if ((cwd[0] != '/') || (head + 1 + tail >= HILDE_PATH_SIZE)) {
      return 0;
    }
    memcpy(joined, cwd, head);
    joined[head] = '/';
    memcpy(joined + head + 1, path, tail + 1);
    length = head + 1 + tail;
  }
  while (at < length) {
    size_t start;
    size_t name;

    while ((at < length) && (joined[at] == '/')) {
      at++;
    }
    start = at;
    while ((at < length) && (joined[at] != '/')) {
      at++;
    }
    name = at - start;
    if ((name == 0) || ((name == 1) && (joined[start] == '.'))) {
      continue;
    }
    if ((name == 2) && (joined[start] == '.') && (joined[start + 1] == '.')) {
      while ((used > 0) && (out[used - 1] != '/')) {
        used--;
      }
      if (used > 0) {
        used--;
      }
      continue;
    }
    out[used++] = '/';
    memcpy(out + used, joined + start, name);
    used += name;
  }
  if (used == 0) {
    out[used++] = '/';
  }
  out[used] = '\0';
  return 1;
}

#if defined(HILDE_SANDBOX_CAPSICUM)
static struct hilde_capsicum_grant* hilde_capsicum_grants;
static int32_t hilde_capsicum_count;
static int hilde_capsicum_entered;
/* The working directory when capability mode was entered, which cannot
   change after it: a relative path is taken from here. */
static char hilde_capsicum_cwd[PATH_MAX];

/* Where a path is resolved from: outside capability mode AT_FDCWD and the
   path itself; inside, the descriptor of the longest grant the path lies
   in and the rest of the path below it.  For the grant itself the rest is
   "." for a directory and "" for a file, and empty is set: the caller
   then adds O_EMPTY_PATH or AT_EMPTY_PATH.  -1 with errno EACCES when the
   path lies in no grant. */
static int hilde_capsicum_route(const char* path, const char** rest, int* empty, char buffer[PATH_MAX]) {
  const struct hilde_capsicum_grant* best = NULL;
  const char* tail;
  int32_t k;

  *empty = 0;
  if (!hilde_capsicum_entered) {
    *rest = path;
    return AT_FDCWD;
  }
  if (!hilde_capsicum_absolute(path, hilde_capsicum_cwd, buffer)) {
    errno = EACCES;
    return -1;
  }
  for (k = 0; k < hilde_capsicum_count; k++) {
    const struct hilde_capsicum_grant* grant = &hilde_capsicum_grants[k];
    int inside;

    if (grant->length == 1) {
      inside = 1;
    } else {
      inside = (strncmp(buffer, grant->path, grant->length) == 0) &&
               ((buffer[grant->length] == '\0') || (buffer[grant->length] == '/'));
    }
    if (inside && ((best == NULL) || (grant->length > best->length))) {
      best = grant;
    }
  }
  if (best == NULL) {
    errno = EACCES;
    return -1;
  }
  tail = buffer + ((best->length == 1) ? 0 : best->length);
  while (*tail == '/') {
    tail++;
  }
  if (*tail == '\0') {
    if (best->directory) {
      tail = ".";
    } else {
      *empty = 1;
    }
  }
  *rest = tail;
  return best->fd;
}
#endif

/* The runtime's calls on paths.  Outside capability mode, and on every
   other platform, each is the plain call; in capability mode on FreeBSD
   the path is routed through the grants of the policy. */
static __attribute__((unused)) int hilde_path_open(const char* path, int flags, mode_t mode) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(path, &rest, &empty, buffer);

    if (from == -1) {
      return -1;
    }
    return openat(from, rest, flags | (empty ? O_EMPTY_PATH : 0), mode);
  }
#endif
  return open(path, flags, mode);
}

static __attribute__((unused)) int hilde_path_stat(const char* path, struct stat* info, int follow) {
  extern int lstat(const char* path, struct stat* buf);

#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(path, &rest, &empty, buffer);

    if (from == -1) {
      return -1;
    }
    return fstatat(from, rest, info, (follow ? 0 : AT_SYMLINK_NOFOLLOW) | (empty ? AT_EMPTY_PATH : 0));
  }
#endif
  return follow ? stat(path, info) : lstat(path, info);
}

/* unlink, or rmdir when directory is 1.  The grant itself cannot be
   removed in capability mode. */
static __attribute__((unused)) int hilde_path_remove(const char* path, int directory) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(path, &rest, &empty, buffer);

    if (from == -1) {
      return -1;
    }
    if (empty || (strcmp(rest, ".") == 0)) {
      errno = EACCES;
      return -1;
    }
    return unlinkat(from, rest, directory ? AT_REMOVEDIR : 0);
  }
#endif
  return directory ? rmdir(path) : unlink(path);
}

static __attribute__((unused)) int hilde_path_mkdir(const char* path, mode_t mode) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(path, &rest, &empty, buffer);

    if (from == -1) {
      return -1;
    }
    return mkdirat(from, rest, mode);
  }
#endif
  return mkdir(path, mode);
}

static __attribute__((unused)) int hilde_path_rename(const char* from, const char* to) {
  extern int rename(const char* from, const char* to);
#if defined(HILDE_SANDBOX_CAPSICUM)
  extern int renameat(int from_fd, const char* from, int to_fd, const char* to);
#endif

#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char one[PATH_MAX];
    char two[PATH_MAX];
    const char* first;
    const char* second;
    int empty;
    int other;
    int at = hilde_capsicum_route(from, &first, &empty, one);

    if ((at == -1) || empty) {
      return -1;
    }
    other = hilde_capsicum_route(to, &second, &empty, two);
    if ((other == -1) || empty) {
      return -1;
    }
    return renameat(at, first, other, second);
  }
#endif
  return rename(from, to);
}

static __attribute__((unused)) int hilde_path_link(const char* existing, const char* name) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char one[PATH_MAX];
    char two[PATH_MAX];
    const char* first;
    const char* second;
    int empty;
    int other;
    int at = hilde_capsicum_route(existing, &first, &empty, one);

    if ((at == -1) || empty) {
      return -1;
    }
    other = hilde_capsicum_route(name, &second, &empty, two);
    if ((other == -1) || empty) {
      return -1;
    }
    return linkat(at, first, other, second, 0);
  }
#endif
  return link(existing, name);
}

/* A symbolic link called name that points at target; the target is text
   and is not routed. */
static __attribute__((unused)) int hilde_path_symlink(const char* target, const char* name) {
  extern int symlink(const char* target, const char* name);

#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(name, &rest, &empty, buffer);

    if ((from == -1) || empty) {
      return -1;
    }
    return symlinkat(target, from, rest);
  }
#endif
  return symlink(target, name);
}

static __attribute__((unused)) ssize_t hilde_path_readlink(const char* path, char* out, size_t size) {
  extern ssize_t readlink(const char* path, char* buf, size_t size);

#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    char buffer[PATH_MAX];
    const char* rest;
    int empty;
    int from = hilde_capsicum_route(path, &rest, &empty, buffer);

    if ((from == -1) || empty) {
      return -1;
    }
    return readlinkat(from, rest, out, size);
  }
#endif
  return readlink(path, out, size);
}

/* The directory stream of a path, or NULL. */
static __attribute__((unused)) DIR* hilde_path_opendir(const char* path) {
#if defined(HILDE_SANDBOX_CAPSICUM)
  if (hilde_capsicum_entered) {
    DIR* stream;
    int fd = hilde_path_open(path, O_RDONLY | O_DIRECTORY | O_CLOEXEC, 0);

    if (fd == -1) {
      return NULL;
    }
    stream = fdopendir(fd);
    if (stream == NULL) {
      close(fd);
    }
    return stream;
  }
#endif
  return opendir(path);
}
