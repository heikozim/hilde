/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Files and directories, watching them, pipes and the chain of a
 * cancellation context.
 */

#include "internal.h"

/*
 * Files.
 *
 * Each call here wraps what cannot be said in Hilde: a descriptor is a
 * number the kernel owns, the O_ constants are platform numbers, and EINTR
 * is a retry the caller must not have to remember.
 */

/* Open an existing file for reading.  The descriptor, or -1. */
int hilde_file_open_read(const uint8_t* path) {
  int fd;

  do {
    fd = hilde_path_open((const char*) path, O_RDONLY, 0);
  } while (fd < 0 && errno == EINTR);
  return hilde_file_mark_close_on_exec(fd);
}

/* Create or truncate, and open for writing.  The descriptor, or -1.
   Mode 0600: a file this process creates is readable by its owner and by
   nobody else.  A caller who wants it wider widens it afterwards, which is
   one call; a caller who wanted it narrow and got 0644 has already leaked
   it. */
int hilde_file_open_write(const uint8_t* path) {
  int fd;

  do {
    fd = hilde_path_open((const char*) path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
  } while (fd < 0 && errno == EINTR);
  return hilde_file_mark_close_on_exec(fd);
}

/* The mode of a file just made, set on its descriptor so that the umask
   does not change it; 0 on success.  WASI has no modes: there the file
   keeps what its runtime gives it, and this succeeds.  fchmod is declared
   here because glibc does not declare it under -std=c17. */
static int hilde_file_mode_of_new(int fd, uint32_t mode) {
#if defined(__wasi__)
  (void) fd;
  (void) mode;
  return 0;
#else
  extern int fchmod(int fd, mode_t mode);

  return fchmod(fd, (mode_t) mode);
#endif
}

/* Create the file if it is missing and open it for appending.  A file made
   here gets mode on the open descriptor: open(2) creates with the mode less
   the umask, and a file that is to be 0640 must not end up 0600 under a
   umask of 077.  O_EXCL tells a file made here from one that was there: the
   mode of a file that was there is left as it is, since it may belong to
   someone else, and a symbolic link at the path is refused rather than
   followed, so that a link planted there cannot point the writes, or a
   fchmod, at another file.  The link is told by lstat(2) and the open
   file held against it by device and inode; O_NOFOLLOW is added where the
   headers show it.  The descriptor, or -1; a descriptor whose mode could
   not be set is closed and reported as a failure. */
int hilde_file_open_append(const uint8_t* path, uint32_t mode) {
  extern int lstat(const char* path, struct stat* buf);
  int nofollow = 0;
  struct stat named;
  struct stat opened;
  int fd;

#ifdef O_NOFOLLOW
  nofollow = O_NOFOLLOW;
#endif
  do {
    fd = hilde_path_open((const char*) path, O_WRONLY | O_APPEND | O_CREAT | O_EXCL | nofollow, (mode_t) mode);
  } while (fd < 0 && errno == EINTR);
  if (fd >= 0) {
    fd = hilde_file_mark_close_on_exec(fd);
    if (fd >= 0 && hilde_file_mode_of_new(fd, mode) != 0) {
      close(fd);
      return -1;
    }
    return fd;
  }
  if (errno != EEXIST) {
    return -1;
  }
  if (hilde_path_stat((const char*) path, &named, 0) != 0 || S_ISLNK(named.st_mode)) {
    return -1;
  }
  do {
    fd = hilde_path_open((const char*) path, O_WRONLY | O_APPEND | nofollow, 0);
  } while (fd < 0 && errno == EINTR);
  fd = hilde_file_mark_close_on_exec(fd);
  if (fd < 0) {
    return -1;
  }
  if (fstat(fd, &opened) != 0 || opened.st_dev != named.st_dev || opened.st_ino != named.st_ino) {
    close(fd);
    return -1;
  }
  return fd;
}

/* Open path for appending as above and put the new file in place of fd:
   dup2(2) makes the number fd name the new file in one step, so a write
   through fd never finds it closed.  This is what a log needs after a
   rotation renamed its file.  dup2 clears close-on-exec on its target, so
   it is set again.  1 on success; 0 when path could not be opened or dup2
   failed, and fd then still names the old file; 0 also when close-on-exec
   could not be set again, and fd then names the new file without it. */
int hilde_file_reopen_append(int fd, const uint8_t* path, uint32_t mode) {
#if defined(__wasi__)
  (void) fd;
  (void) path;
  (void) mode;
  return 0;
#else
  int fresh = hilde_file_open_append(path, mode);
  int moved;

  if (fresh < 0) {
    return 0;
  }
  do {
    moved = dup2(fresh, fd);
  } while (moved < 0 && errno == EINTR);
  close(fresh);
  if (moved < 0) {
    return 0;
  }
  return (fcntl(fd, F_SETFD, FD_CLOEXEC) == 0) ? 1 : 0;
#endif
}

/* 1 on success, 0 on failure.
   close(2) is deliberately not retried on EINTR: the descriptor is released
   before the signal is delivered, so a retry closes whatever file the kernel
   has since given that number to.  The number is gone either way, which is
   why the Hilde function Standard.File.closeFile consumes the descriptor
   whatever this returns. */
int hilde_file_close(int fd) {
  return (close(fd) == 0) ? 1 : 0;
}

/* Defined with the task runtime below: in a task, waits until fd has
   something to read while the other tasks run. */
static void hilde_task_before_read(int fd);

/* Bytes read, 0 at end of file, -1 on error.
   A short read is neither an error nor retried here: only the caller knows
   whether it wanted everything, and only the caller can tell end of file
   from a pause.  In a task the read does not hold its worker while the
   descriptor has nothing to read: see hilde_task_before_read. */
int64_t hilde_file_read(int fd, uint8_t* buffer, size_t count) {
  ssize_t n;

  hilde_task_before_read(fd);
  do {
    n = read(fd, buffer, count);
  } while (n < 0 && errno == EINTR);
  return (int64_t) n;
}

/* 1 when all count bytes were written, 0 otherwise.  A short write
   is the ordinary case on a pipe or a socket, and a programme that treats
   write(2) as all-or-nothing loses the tail of its answer under exactly the
   load that makes it matter. */
int hilde_file_write_all(int fd, const uint8_t* buffer, size_t count) {
  size_t written = 0;

  while (written < count) {
    ssize_t n = write(fd, buffer + written, count - written);

    if (n < 0) {
      if (errno == EINTR) {
        continue;
      }
      return 0;
    }
    if (n == 0) {
      /* No error and no progress.  Going round again would spin forever, so
         this is reported as a failure rather than waited out. */
      return 0;
    }
    written += (size_t) n;
  }
  return 1;
}

/* Standard.IO.Terminal.writeErrorText: the text to the standard error with
   write(2), after libc's stream has given up what it still holds, so that
   bytes written before with writeByte come first.  A log line goes out this
   way whole, in one write as far as the kernel takes it.  1 when every
   byte was written. */
int32_t hilde_stderr_write_all(const uint8_t* buffer, size_t count) {
  (void) hilde_libc_fflush(hilde_stderr());
  return hilde_file_write_all(2, buffer, count);
}

/*
 * Watching files and directories: inotify on Linux, kqueue on OpenBSD and
 * FreeBSD, nothing elsewhere.  There, opening, adding and waiting return -1,
 * hilde_watch_forget returns 1 as there is nothing to give back, and
 * hilde_watch_available returns 0.
 */

/* A watcher's descriptor, close-on-exec, or -1 where watching is not
   built or the kernel refused.  A kqueue is not inherited by a child. */
int hilde_watch_open(void) {
#if defined(__linux__)
  return inotify_init1(IN_CLOEXEC);
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
  return kqueue();
#else
  return -1;
#endif
}

/* A watch of path added to watcher: the names of a directory when
   directory is 1, else the content, the attributes and the name of a
   file.  The watch's number, inotify's watch descriptor or the descriptor
   kqueue watches, or -1.  A symbolic link at path is followed. */
int hilde_watch_add(int watcher, const uint8_t* path, int directory) {
#if defined(__linux__)
  uint32_t mask;

  if (directory != 0) {
    mask = IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO;
  } else {
    mask = IN_MODIFY | IN_ATTRIB | IN_DELETE_SELF | IN_MOVE_SELF;
  }
  return inotify_add_watch(watcher, (const char*) path, mask);
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
  struct kevent change;
  unsigned int notes;
  int fd;

  do {
    fd = hilde_path_open((const char*) path, O_RDONLY | O_CLOEXEC, 0);
  } while (fd < 0 && errno == EINTR);
  if (fd < 0) {
    return -1;
  }
  if (directory != 0) {
    notes = NOTE_WRITE;
  } else {
    notes = NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_DELETE | NOTE_RENAME;
  }
  EV_SET(&change, fd, EVFILT_VNODE, EV_ADD | EV_CLEAR, notes, 0, NULL);
  if (kevent(watcher, &change, 1, NULL, 0, NULL) != 0) {
    close(fd);
    return -1;
  }
  return fd;
#else
  (void) watcher;
  (void) path;
  (void) directory;
  return -1;
#endif
}

/* Waits at most milliseconds for a change among the watches of watcher.
   The number of a watch that changed; -2 when the time ran out; -1 on a
   failure.  On Linux every event that waits is read and the first one's
   watch reported, so that changes at once may be reported once; on
   OpenBSD one event is taken and the others wait for the next call. */
/* One poll(2), its arguments and its answer, for a helper thread. */
typedef struct hilde_poll_call {
  struct pollfd* fds;
  nfds_t count;
  int timeout;
  int rc;
} hilde_poll_call_t;

static void hilde_poll_blocking(void* raw) {
  hilde_poll_call_t* call = (hilde_poll_call_t*) raw;

  do {
    call->rc = poll(call->fds, call->count, call->timeout);
  } while (call->rc < 0 && errno == EINTR);
}

int hilde_watch_wait(int watcher, uint32_t milliseconds) {
  struct pollfd ready;
  hilde_poll_call_t call;
  int rc;
  int wait = (milliseconds > 2147483647u) ? 2147483647 : (int) milliseconds;

  ready.fd = watcher;
  ready.events = POLLIN;
  ready.revents = 0;
  call.fds = &ready;
  call.count = 1;
  call.timeout = wait;
  hilde_task_blocking(hilde_poll_blocking, &call);
  rc = call.rc;
  if (rc < 0) {
    return -1;
  }
  if (rc == 0) {
    return -2;
  }
#if defined(__linux__)
  {
    union {
      struct inotify_event event;
      char bytes[4096];
    } buffer;
    ssize_t n;

    do {
      n = read(watcher, buffer.bytes, sizeof buffer.bytes);
    } while (n < 0 && errno == EINTR);
    if (n < (ssize_t) sizeof(struct inotify_event)) {
      return -1;
    }
    return buffer.event.wd;
  }
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
  {
    struct kevent event;
    struct timespec none;
    int got;

    none.tv_sec = 0;
    none.tv_nsec = 0;
    got = kevent(watcher, NULL, 0, &event, 1, &none);
    if (got < 0) {
      return -1;
    }
    if (got == 0) {
      return -2;
    }
    return (int) event.ident;
  }
#else
  return -1;
#endif
}

/* Gives back what a watch holds: on OpenBSD, FreeBSD and macOS the
   descriptor kqueue watched; on Linux nothing, since closing the watcher ends its
   watches.  1 on success. */
int hilde_watch_forget(int number) {
#if defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
  return (close(number) == 0) ? 1 : 0;
#else
  (void) number;
  return 1;
#endif
}

/* 1 where watching is built. */
int hilde_watch_available(void) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
  return 1;
#else
  return 0;
#endif
}

/* 1 when the name is gone, 0 otherwise. */
int hilde_file_remove(const uint8_t* path) {
  return (hilde_path_remove((const char*) path, 0) == 0) ? 1 : 0;
}

/* 1 when the name is gone afterwards: removed now, or not there at all.
   Any other refusal of unlink(2) is 0.  For a PID file, whose absence is
   the state its removal wants. */
int hilde_file_remove_if_there(const uint8_t* path) {
  if (hilde_path_remove((const char*) path, 0) == 0) {
    return 1;
  }
  return (errno == ENOENT) ? 1 : 0;
}

/* Random bytes for an overwrite: getrandom(2) on Linux, arc4random_buf(3)
   on the BSDs and macOS.  Neither is declared under -std=c17, so both are
   declared here.  1 when the buffer is full. */
static int hilde_file_random_fill(uint8_t* buf, size_t n) {
#if defined(__linux__)
  extern long getrandom(void* buf, size_t buflen, unsigned int flags);
  size_t done = 0;

  while (done < n) {
    long got = getrandom(buf + done, n - done, 0);
    if (got < 0) {
      if (errno == EINTR) {
        continue;
      }
      return 0;
    }
    done += (size_t) got;
  }
  return 1;
#else
  extern void arc4random_buf(void* buf, size_t nbytes);

  arc4random_buf(buf, n);
  return 1;
#endif
}

/* Overwrites a file once with random bytes, writes it to the disk and
   removes its name, as rm -P of OpenBSD does.  Only a regular file that may
   be written is overwritten.  The name is looked at with lstat(2), so a
   symbolic link is refused; the file opened is held against it by device
   and inode, so a name swapped in between is refused too, and O_NOFOLLOW
   is added where the headers show it.  A file with more than one link is
   only unlinked: overwriting it would destroy what the other names hold.
   2 when overwritten and removed, 3 when only unlinked, 0 otherwise.  On
   flash memory and on a file system that copies on write the old blocks
   may survive; the caller's documentation says so. */
int hilde_file_secure_delete(const uint8_t* path) {
  extern int lstat(const char* path, struct stat* buf);
  enum { chunk = 4096 };
  uint8_t buf[chunk];
  struct stat named;
  struct stat opened;
  int flags = O_WRONLY | O_NONBLOCK;
  int fd;
  off_t left;
  int ok = 1;

  if (hilde_path_stat((const char*) path, &named, 0) != 0 || !S_ISREG(named.st_mode)) {
    return 0;
  }
#ifdef O_NOFOLLOW
  flags |= O_NOFOLLOW;
#endif
  do {
    fd = hilde_path_open((const char*) path, flags, 0);
  } while (fd < 0 && errno == EINTR);
  fd = hilde_file_mark_close_on_exec(fd);
  if (fd < 0) {
    return 0;
  }
  if (fstat(fd, &opened) != 0 || !S_ISREG(opened.st_mode)
      || opened.st_dev != named.st_dev || opened.st_ino != named.st_ino) {
    close(fd);
    return 0;
  }
  if (opened.st_nlink > 1) {
    close(fd);
    return (hilde_path_remove((const char*) path, 0) == 0) ? 3 : 0;
  }
  left = opened.st_size;
  while (ok && left > 0) {
    size_t n = (left > (off_t) chunk) ? (size_t) chunk : (size_t) left;
    size_t done = 0;
    if (!hilde_file_random_fill(buf, n)) {
      ok = 0;
      break;
    }
    while (done < n) {
      ssize_t w = write(fd, buf + done, n - done);
      if (w < 0) {
        if (errno == EINTR) {
          continue;
        }
        ok = 0;
        break;
      }
      if (w == 0) {
        /* No error and no progress.  Going round again would spin forever,
           so the overwrite is reported as a failure and the name is kept. */
        ok = 0;
        break;
      }
      done += (size_t) w;
    }
    left -= (off_t) done;
  }
  if (ok) {
    int rc;
    do {
      rc = fsync(fd);
    } while (rc != 0 && errno == EINTR);
    ok = (rc == 0);
  }
  if (close(fd) != 0) {
    ok = 0;
  }
  if (!ok) {
    return 0;
  }
  return (hilde_path_remove((const char*) path, 0) == 0) ? 2 : 0;
}

/* The mode of an open file, set with fchmod(2).  1 on success.  WASI has
   no modes and its fchmod fails for every descriptor: there the
   file keeps what its runtime gives it, as a file made by
   hilde_file_mode_of_new does, and this succeeds for a descriptor that is
   open, told by fstat(2), and fails for any other. */
int hilde_file_set_mode(int fd, uint32_t mode) {
#if defined(__wasi__)
  struct stat opened;

  (void) mode;
  return (fstat(fd, &opened) == 0) ? 1 : 0;
#else
  extern int fchmod(int fd, mode_t mode);

  return (fchmod(fd, (mode_t) mode) == 0) ? 1 : 0;
#endif
}

/*
 * What a name is, and where a link points.
 */

/* The five answers.  HILDE_KIND_UNKNOWN is first and is not the same as
   missing: a name that cannot be looked at because a directory above it
   is closed reads the same way here, and hilde_file_kind does not look at
   the error number to tell them apart.  So the answer is unknown, not a
   claim that the name is missing. */
#define HILDE_KIND_UNKNOWN 0
#define HILDE_KIND_REGULAR 1
#define HILDE_KIND_DIRECTORY 2
#define HILDE_KIND_SYMLINK 3
#define HILDE_KIND_OTHER 4

/* follow chooses between stat(2) and lstat(2), and the difference is the
   point of the function: lstat answers about the name itself, stat about
   what the name leads to.  A check that means to refuse symbolic links
   has to use lstat, that is follow 0. */
int hilde_file_kind(const uint8_t* path, int follow) {
  struct stat info;
  int rc;

  rc = hilde_path_stat((const char*) path, &info, follow != 0);
  if (rc != 0) {
    return HILDE_KIND_UNKNOWN;
  }
  if (S_ISREG(info.st_mode)) {
    return HILDE_KIND_REGULAR;
  }
  if (S_ISDIR(info.st_mode)) {
    return HILDE_KIND_DIRECTORY;
  }
  if (S_ISLNK(info.st_mode)) {
    return HILDE_KIND_SYMLINK;
  }
  return HILDE_KIND_OTHER;
}

/* Bytes written into buffer, or -1.  readlink(2) does not terminate what
   it writes and does not say whether it truncated: a return equal to size
   means the name may be cut short, and the caller treats that as a
   failure rather than as a shorter link. */
int64_t hilde_file_read_link(const uint8_t* path, uint8_t* buffer,
                             size_t size) {
  ssize_t n;

  do {
    n = hilde_path_readlink((const char*) path, (char*) buffer, size);
  } while (n < 0 && errno == EINTR);
  return (int64_t) n;
}

/* Makes a symbolic link called name that points at target.  1 on success,
   0 otherwise.  It exists so that the code asking whether a name is a link
   can be tested against a link it made, not against whatever the machine
   happens to have lying about. */
int hilde_file_make_link(const uint8_t* target, const uint8_t* name) {
  return (hilde_path_symlink((const char*) target, (const char*) name) == 0) ? 1 : 0;
}

/*
 * What a file is, renames, links and syncs, a temporary file beside a
 * name: the parts of an atomic write.
 */

/* The kind of a mode in the numbers of hilde_file_kind. */
static uint32_t hilde_file_kind_of_mode(mode_t mode) {
  if (S_ISREG(mode)) {
    return HILDE_KIND_REGULAR;
  }
  if (S_ISDIR(mode)) {
    return HILDE_KIND_DIRECTORY;
  }
  if (S_ISLNK(mode)) {
    return HILDE_KIND_SYMLINK;
  }
  return HILDE_KIND_OTHER;
}

/* A status in four narrow slots and four wide ones.  Narrow: the kind,
   the permission bits of the mode, the owner and the group, each 32 bits
   wide as uid_t and gid_t are on the platforms this project builds for.
   Wide: the size, the device, the inode number and the number of hard
   links.  A size below zero, which no ordinary file has, is written as 0.
   dev_t, ino_t and nlink_t are unsigned and at most 64 bits wide on those
   platforms. */
static void hilde_file_status_slots(const struct stat* info, uint32_t* slots,
                                    uint64_t* wide) {
  slots[0] = hilde_file_kind_of_mode(info->st_mode);
  slots[1] = (uint32_t) (info->st_mode & 07777);
  slots[2] = (uint32_t) info->st_uid;
  slots[3] = (uint32_t) info->st_gid;
  wide[0] = (info->st_size < 0) ? 0 : (uint64_t) info->st_size;
  wide[1] = (uint64_t) info->st_dev;
  wide[2] = (uint64_t) info->st_ino;
  wide[3] = (uint64_t) info->st_nlink;
}

/* What the name is, into the slots of hilde_file_status_slots, without
   following a symbolic link when follow is 0.  1 when found; 0 when
   nothing is there, ENOENT, or ENOTDIR for a part of the path that is no
   directory; -1 for every other refusal, which is not the same as
   missing: a name under a directory the process may not search is -1. */
int hilde_file_status(const uint8_t* path, int follow, uint32_t* slots,
                      uint64_t* wide) {
  struct stat info;
  int rc;

  rc = hilde_path_stat((const char*) path, &info, follow != 0);
  if (rc != 0) {
    return (errno == ENOENT || errno == ENOTDIR) ? 0 : -1;
  }
  hilde_file_status_slots(&info, slots, wide);
  return 1;
}

/* The status of an open file with fstat(2), into the slots of
   hilde_file_status_slots.  1 on success. */
int hilde_file_status_open(int fd, uint32_t* slots, uint64_t* wide) {
  struct stat info;

  if (fstat(fd, &info) != 0) {
    return 0;
  }
  hilde_file_status_slots(&info, slots, wide);
  return 1;
}

/* The owner and group of an open file, set with fchown(2).  Giving a file
   away needs privilege; setting what it has already does not.  1 on
   success.  fchown is declared here because glibc's headers (with gcc
   14.2.0) do not declare it under -std=c17, nor mkstemp, lstat and
   rename; OpenBSD's headers declare all of them but rename. */
int hilde_file_set_owner(int fd, uint32_t owner, uint32_t group) {
  extern int fchown(int fd, uid_t owner, gid_t group);

  return (fchown(fd, (uid_t) owner, (gid_t) group) == 0) ? 1 : 0;
}

/* What the kernel holds of an open file written to the disk, with
   fsync(2).  1 when the disk has it. */
int hilde_file_sync(int fd) {
  int rc;

  do {
    rc = fsync(fd);
  } while (rc != 0 && errno == EINTR);
  return (rc == 0) ? 1 : 0;
}

/* A directory written to the disk, which makes a name made or renamed in
   it durable: opened for reading and synced.  1 on success. */
int hilde_dir_sync(const uint8_t* path) {
  int fd;
  int rc;

  do {
    fd = hilde_path_open((const char*) path, O_RDONLY, 0);
  } while (fd < 0 && errno == EINTR);
  fd = hilde_file_mark_close_on_exec(fd);
  if (fd < 0) {
    return 0;
  }
  do {
    rc = fsync(fd);
  } while (rc != 0 && errno == EINTR);
  if (close(fd) != 0) {
    return 0;
  }
  return (rc == 0) ? 1 : 0;
}

/* Renames from to to with rename(2), which replaces a file at to in one
   step.  1 on success.  rename is ISO C and declared in <stdio.h>, which
   the runtime does not include. */
int hilde_file_rename(const uint8_t* from, const uint8_t* to) {
  return (hilde_path_rename((const char*) from, (const char*) to) == 0) ? 1 : 0;
}

/* name made a second name of the file at existing, with link(2).  1 on
   success. */
int hilde_file_link(const uint8_t* existing, const uint8_t* name) {
  return (hilde_path_link((const char*) existing, (const char*) name) == 0) ? 1 : 0;
}

/* A new file made by mkstemp(3) from template, a path that ends in six X
   which it replaces with a name nobody holds: created with mode 0600,
   open for reading and writing, close-on-exec.  The new name is written
   into template.  The descriptor, or -1, and then no file is left.  No
   second try on EINTR: the first try has already replaced the X. */
int hilde_file_make_temporary(uint8_t* template) {
  extern int mkstemp(char* template);
  int fd;

#if defined(HILDE_SANDBOX_CAPSICUM)
  /* mkstemp names a path, which capability mode refuses: the six X are
     replaced here and the name is opened through the grants, with
     O_EXCL, and a name that is taken is drawn again. */
  if (hilde_capsicum_entered) {
    extern uint32_t arc4random_uniform(uint32_t upper_bound);
    static const char letters[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    size_t length = strlen((const char*) template);
    int tries;
    size_t i;

    if ((length < 6) || (strcmp((const char*) template + length - 6, "XXXXXX") != 0)) {
      errno = EINVAL;
      return -1;
    }
    for (tries = 0; tries < 100; tries++) {
      for (i = length - 6; i < length; i++) {
        template[i] = (uint8_t) letters[arc4random_uniform((uint32_t) (sizeof letters - 1))];
      }
      fd = hilde_path_open((const char*) template, O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
      if ((fd >= 0) || (errno != EEXIST)) {
        return fd;
      }
    }
    return -1;
  }
#endif
  fd = mkstemp((char*) template);
  if (fd < 0) {
    return -1;
  }
  if (fcntl(fd, F_SETFD, FD_CLOEXEC) != 0) {
    close(fd);
    unlink((const char*) template);
    return -1;
  }
  return fd;
}

/* A new file at path, made only when the name is free (O_EXCL), open for
   writing, its mode set on the open file so that the umask does not
   change it, and close-on-exec.  The descriptor, or -1, and then no file
   is left. */
int hilde_file_create_new(const uint8_t* path, uint32_t mode) {
  int fd;

  do {
    fd = hilde_path_open((const char*) path, O_WRONLY | O_CREAT | O_EXCL, 0600);
  } while (fd < 0 && errno == EINTR);
  if (fd < 0) {
    return -1;
  }
  if (hilde_file_mode_of_new(fd, mode) != 0 || fcntl(fd, F_SETFD, FD_CLOEXEC) != 0) {
    close(fd);
    hilde_path_remove((const char*) path, 0);
    return -1;
  }
  return fd;
}

/* An existing file opened for writing from its first byte, neither
   truncated nor appended to, so that what is written lands on the bytes
   it had; close-on-exec.  The descriptor, or -1. */
int hilde_file_open_overwrite(const uint8_t* path) {
  int fd;

  do {
    fd = hilde_path_open((const char*) path, O_WRONLY, 0);
  } while (fd < 0 && errno == EINTR);
  return hilde_file_mark_close_on_exec(fd);
}

/*
 * The chain of a cancellation context.
 *
 * Standard.Context gives every derived context a pipe, and a context is
 * cancelled when the writing end of its own pipe or of an ancestor's pipe
 * is closed.  A node holds the reading end of one level and points at the
 * node of the level above.  A child takes a reference to its parent's node
 * rather than copies of the parent's descriptors, so a chain of n levels
 * holds n reading ends and not n(n+1)/2.  A child may outlive its parent:
 * a node and its reading end stay until the last reference to it is given
 * back.  The count is changed atomically, because a context is lent to
 * tasks on other threads and each of them may derive from it; a node is
 * only ever reached through a reference that holds it, so the count cannot
 * rise again once it has fallen to 0.
 */
struct hilde_context_node {
  int reading;
  long references;
  struct hilde_context_node* parent;
};

/* A node with one reference for reading below parent, which is NULL at the
   top of a chain; it takes a reference to parent.  NULL when there is no
   memory, and then neither reading nor parent is taken. */
void* hilde_context_node_make(int reading, void* parent) {
  struct hilde_context_node* node = hilde_calloc(1, sizeof(struct hilde_context_node));
  struct hilde_context_node* above = parent;

  if (node == NULL) {
    return NULL;
  }
  node->reading = reading;
  node->references = 1;
  node->parent = above;
  if (above != NULL) {
    __atomic_add_fetch(&above->references, 1, __ATOMIC_SEQ_CST);
  }
  return node;
}

/* Gives back one reference to node, which may be NULL.  The last reference
   closes the node's reading end, frees the node and gives back its
   reference to the parent, and so on up the chain.  What close says is not
   asked: the number is gone either way (see hilde_file_close). */
hilde_unit_t hilde_context_node_release(void* node) {
  struct hilde_context_node* at = node;

  while (at != NULL) {
    struct hilde_context_node* above = at->parent;

    if (__atomic_sub_fetch(&at->references, 1, __ATOMIC_SEQ_CST) != 0) {
      break;
    }
    hilde_file_close(at->reading);
    hilde_free(at);
    at = above;
  }
  return nil;
}

/* Waits at most milliseconds until a reading end of the chain from node up
   can be read from or has hung up; 0 asks without waiting, -1 waits as long
   as it takes.  A NULL node is an empty chain, and the wait is the time
   alone.  1 when one is ready, 0 when the time ran out, -1 when poll failed
   or there was no memory.  A signal restarts the wait. */
int32_t hilde_context_node_wait(void* node, int32_t milliseconds) {
  struct hilde_context_node* at;
  struct pollfd* fds;
  size_t count = 0;
  size_t i = 0;
  int ready;

  for (at = node; at != NULL; at = at->parent) {
    count++;
  }
  if (count == 0) {
    if (milliseconds != 0) {
      while (poll(NULL, 0, milliseconds) < 0 && errno == EINTR) {
      }
    }
    return 0;
  }
  if (count > SIZE_MAX / sizeof(struct pollfd)) {
    return -1;
  }
  fds = hilde_calloc(count, sizeof(struct pollfd));
  if (fds == NULL) {
    return -1;
  }
  for (at = node; at != NULL; at = at->parent) {
    fds[i].fd = at->reading;
    fds[i].events = POLLIN;
    fds[i].revents = 0;
    i++;
  }
  do {
    ready = poll(fds, (nfds_t) count, milliseconds);
  } while (ready < 0 && errno == EINTR);
  hilde_free(fds);
  if (ready > 0) {
    return 1;
  }
  return (ready == 0) ? 0 : -1;
}

/*
 * Moving the file offset.
 */

/* The new offset from the start of the file, or -1.  whence is 0, 1 or 2
   for "from the start", "from here" and "from the end", and it is translated
   into the platform's SEEK_ constants here rather than written down as their
   numbers in Hilde. */
int64_t hilde_file_seek(int fd, int64_t offset, int whence) {
  int how;
  off_t where;

  if (whence == 0) {
    how = SEEK_SET;
  } else if (whence == 1) {
    how = SEEK_CUR;
  } else if (whence == 2) {
    how = SEEK_END;
  } else {
    return -1;
  }
  where = lseek(fd, (off_t) offset, how);
  return (int64_t) where;
}

/*
 * Making and removing a directory, and reading one.
 */

/* 1 when the directory was made, 0 otherwise.  Mode 0700, for the reason
   hilde_file_open_write gives for 0600. */
int hilde_dir_make(const uint8_t* path) {
  return (hilde_path_mkdir((const char*) path, 0700) == 0) ? 1 : 0;
}

/* 1 when the (empty) directory is gone, 0 otherwise. */
int hilde_dir_remove(const uint8_t* path) {
  return (hilde_path_remove((const char*) path, 1) == 0) ? 1 : 0;
}

/* The directory stream, or NULL. */
void* hilde_dir_open(const uint8_t* path) {
  return (void*) hilde_path_opendir((const char*) path);
}

/* The next name into buffer; the entries named . and .. are skipped.  The
   length of the name, -1 at the end, -2 when reading failed, -3 when the
   name does not fit.

   The two are left out because they are not part of the directory's
   content, and a walker that forgets to skip them walks forever.  End and
   failure are told apart by errno, which readdir(3) leaves alone at the end
   and sets on a failure; that is why errno is cleared before the call. */
int64_t hilde_dir_next(void* dir, uint8_t* buffer, size_t size) {
  struct dirent* entry;
  size_t length;

  for (;;) {
    errno = 0;
    entry = readdir((DIR*) dir);
    if (entry == NULL) {
      return (errno == 0) ? -1 : -2;
    }
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }
    length = strlen(entry->d_name);
    if (length > size) {
      return -3;
    }
    memcpy(buffer, entry->d_name, length);
    return (int64_t) length;
  }
}

/* 1 when closedir(3) reported success, 0 otherwise.  Like close(2), the
   stream is gone either way. */
int hilde_dir_close(void* dir) {
  return (closedir((DIR*) dir) == 0) ? 1 : 0;
}
