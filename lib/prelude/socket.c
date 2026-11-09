/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Unix domain sockets, TCP connections and the socket calls of libtls.
 */

#include "internal.h"

/*
 * A Unix domain socket.
 *
 * What a FastCGI server behind a web server needs: a stream socket bound
 * to a path, listened on, and the connections it accepts -- each one an
 * ordinary descriptor that Standard.File reads and writes.
 *
 * With glibc 2.41 under -std=c17 -Wall -Wextra, gcc and clang: socket,
 * bind, listen, accept, connect, chmod, unlink, struct sockaddr_un,
 * AF_UNIX, SOCK_STREAM, ECONNREFUSED and ENAMETOOLONG are visible with no
 * declaration of ours; S_ISSOCK is not (both compilers refuse it), and
 * neither is lstat, which is declared where it is used, as in
 * hilde_file_kind above.
 *
 * The public helpers are declared in Standard.File with pragma
 * Foreign_Import rather than called through @embed text, so their
 * signatures here are exactly what the code generator declares for them
 * -- int32_t, uint32_t, hilde_index_t, uint8_t* and no const -- and a
 * difference between the two is a compile error, not a silent conversion.
 */

/* The longest path a struct sockaddr_un holds, its zero byte not
   counted: 107 with glibc, on the BSDs whatever their header says.
   Taken from the struct, not written down as a number. */
hilde_index_t hilde_socket_path_limit(void) {
#if defined(__wasi__)
  return 0;
#else
  struct sockaddr_un address;

  return sizeof(address.sun_path) - 1;
#endif
}

/* Fill address from path.  0, or -1 when the path is empty or does not
   fit: a path cut to fit would bind a different name. */
#if !defined(__wasi__)
static int hilde_socket_address(uint8_t* path,
                                struct sockaddr_un* address) {
  size_t size = strlen((const char*) path);

  if (size == 0 || size >= sizeof(address->sun_path)) {
    errno = ENAMETOOLONG;
    return -1;
  }
  memset(address, 0, sizeof(*address));
  address->sun_family = AF_UNIX;
  memcpy(address->sun_path, path, size + 1);
  return 0;
}
#endif

/* A stream socket with close-on-exec set.  The descriptor, or -1. */
#if !defined(__wasi__)
static int hilde_socket_make(void) {
  return hilde_file_mark_close_on_exec(socket(AF_UNIX, SOCK_STREAM, 0));
}
#endif

/* Connect to the socket at path.  The descriptor, or -1 with errno from
   connect(2): the close after a failure must not overwrite it, because
   hilde_socket_is_stale below reads it. */
int32_t hilde_socket_connect(uint8_t* path) {
#if defined(__wasi__)
  (void) path;
  return -1;
#else
  struct sockaddr_un address;
  int fd;
  int saved;

  if (hilde_socket_address(path, &address) != 0) {
    return -1;
  }
  fd = hilde_socket_make();
  if (fd < 0) {
    return -1;
  }
  if (connect(fd, (struct sockaddr*) &address, sizeof(address)) != 0) {
    saved = errno;
    close(fd);
    errno = saved;
    return -1;
  }
  return fd;
#endif
}

/* Is path a socket that nobody accepts on, as a server that died without
   cleaning up leaves behind?  1 or 0.
   Both halves are needed.  Linux answers ECONNREFUSED for a path that is
   not a socket at all, so the refusal alone would let this remove a
   regular file; and S_ISSOCK is not visible under -std=c17, so the type is
   found by elimination: POSIX names seven file types, and a socket is the
   one that is none of the other six. */
#if !defined(__wasi__)
static int hilde_socket_is_stale(uint8_t* path) {
  extern int lstat(const char* path, struct stat* buf);
  struct stat info;
  int fd;

  if (lstat((const char*) path, &info) != 0) {
    return 0;
  }
  if (S_ISREG(info.st_mode) || S_ISDIR(info.st_mode)
      || S_ISLNK(info.st_mode) || S_ISCHR(info.st_mode)
      || S_ISBLK(info.st_mode) || S_ISFIFO(info.st_mode)) {
    return 0;
  }
  fd = hilde_socket_connect(path);
  if (fd >= 0) {
    close(fd);
    return 0;
  }
  return (errno == ECONNREFUSED) ? 1 : 0;
}
#endif

/* Whether nobody but this process's user and root can change the names in
   the directory that holds path: the directory belongs to one of them and
   neither its group nor others may write to it.  Then a name made there
   cannot be swapped for a symbolic link between the bind and the chmod. */
#if !defined(__wasi__)
static int hilde_socket_parent_is_private(const char* path) {
  extern uid_t geteuid(void);
  char parent[sizeof(((struct sockaddr_un*) 0)->sun_path)];
  const char* slash = strrchr(path, '/');
  struct stat info;

  if (slash == NULL) {
    parent[0] = '.';
    parent[1] = '\0';
  } else if (slash == path) {
    parent[0] = '/';
    parent[1] = '\0';
  } else {
    size_t n = (size_t) (slash - path);
    if (n >= sizeof parent) {
      return 0;
    }
    memcpy(parent, path, n);
    parent[n] = '\0';
  }
  if (hilde_path_stat(parent, &info, 1) != 0) {
    return 0;
  }
  return ((info.st_mode & 022) == 0) && (info.st_uid == geteuid() || info.st_uid == 0);
}
#endif

/* Bind fd to name, give the file mode, and listen; on a failure the file is
   removed.  The mode is set before listen(2): until then the kernel refuses
   every connection, so there is no moment in which the file has the
   umask's mode and somebody can connect through it.  1 on success. */
#if !defined(__wasi__)
static int hilde_socket_bind_listen(int fd, uint8_t* name, uint32_t mode) {
  struct sockaddr_un address;

  if (hilde_socket_address(name, &address) != 0) {
    return 0;
  }
  if (bind(fd, (struct sockaddr*) &address, sizeof(address)) != 0) {
    return 0;
  }
  if (chmod((const char*) name, (mode_t) mode) != 0 || listen(fd, 64) != 0) {
    unlink((const char*) name);
    return 0;
  }
  return 1;
}
#endif

/* Bind a socket to path, give the file mode, and listen.  A stale socket
   at the path is removed first; anything else there makes this fail, and
   is left as it was.  The descriptor, or -1.
   chmod(2) takes a path, so in a directory that others may write to the
   socket is made in a directory of its own, mode 0700, beside path, given
   its mode there, and renamed to path; nobody else can reach a name in
   that directory.  Where the longer name does not fit into a socket
   address, such a path is refused. */
int32_t hilde_socket_listen(uint8_t* path, uint32_t mode) {
#if defined(__wasi__)
  (void) path;
  (void) mode;
  return -1;
#else
  extern char* mkdtemp(char* pattern);
  extern int lstat(const char* path, struct stat* buf);
  extern int rename(const char* from, const char* to);
  extern int rmdir(const char* path);
  struct sockaddr_un address;
  struct stat existing;
  char dir[sizeof address.sun_path];
  char inner[sizeof address.sun_path];
  const char* name = (const char*) path;
  const char* slash;
  size_t parent;
  int fd;

  if (hilde_socket_address(path, &address) != 0) {
    return -1;
  }
  if (hilde_socket_is_stale(path) == 1) {
    if (unlink(name) != 0) {
      return -1;
    }
  }
  fd = hilde_socket_make();
  if (fd < 0) {
    return -1;
  }
  if (hilde_socket_parent_is_private(name)) {
    if (!hilde_socket_bind_listen(fd, path, mode)) {
      close(fd);
      return -1;
    }
    return fd;
  }
  /* rename(2) would replace what stands at path, where bind(2) refuses
     it: anything still there after the stale socket is gone is refused. */
  if (hilde_path_stat(name, &existing, 0) == 0 || errno != ENOENT) {
    close(fd);
    return -1;
  }
  slash = strrchr(name, '/');
  parent = (slash == NULL) ? 0 : (size_t) (slash - name) + 1;
  if (parent + sizeof ".hilde-XXXXXX/s" > sizeof dir) {
    close(fd);
    return -1;
  }
  memcpy(dir, name, parent);
  memcpy(dir + parent, ".hilde-XXXXXX", sizeof ".hilde-XXXXXX");
  if (mkdtemp(dir) == NULL) {
    close(fd);
    return -1;
  }
  memcpy(inner, dir, parent + sizeof ".hilde-XXXXXX" - 1);
  memcpy(inner + parent + sizeof ".hilde-XXXXXX" - 1, "/s", sizeof "/s");
  if (!hilde_socket_bind_listen(fd, (uint8_t*) inner, mode)) {
    close(fd);
    hilde_path_remove(dir, 1);
    return -1;
  }
  if (hilde_path_rename(inner, name) != 0) {
    close(fd);
    unlink(inner);
    hilde_path_remove(dir, 1);
    return -1;
  }
  if (hilde_path_remove(dir, 1) != 0) {
    close(fd);
    unlink(name);
    return -1;
  }
  return fd;
#endif
}

/* The next connection, blocking until there is one.  The descriptor, or
   -1.  Close-on-exec is set with fcntl, as for the pipe above; the moment
   between accept and fcntl does not leak into a child, because
   hilde_process_spawn closes every descriptor above the standard three. */
int32_t hilde_socket_accept(int32_t listener) {
  int fd;

  do {
    fd = accept(listener, NULL, NULL);
  } while (fd < 0 && errno == EINTR);
  return hilde_file_mark_close_on_exec(fd);
}

/* The time limit of poll(2), an int, from milliseconds held in a uint32_t.
   Standard.File refuses more than 2147483647 before it calls, but a cast
   alone would turn a larger number into a negative one, which poll reads
   as no limit at all; it is held at the largest int instead. */
static int hilde_poll_millis(uint32_t milliseconds) {
  return (milliseconds > (uint32_t) INT32_MAX) ? INT32_MAX : (int) milliseconds;
}

/* The next connection, waiting at most milliseconds.  The descriptor, or
   -1 when nobody connected in that time or poll(2) or accept(2) failed.
   poll and not the poller, because poll is the same call on every
   platform, where the poller has another backend on each.  A signal
   restarts the wait with the whole time again. */
int32_t hilde_socket_accept_within(int32_t listener, uint32_t milliseconds) {
  struct pollfd waiting;
  int ready;

  waiting.fd = listener;
  waiting.events = POLLIN;
  waiting.revents = 0;
  do {
    ready = poll(&waiting, 1, hilde_poll_millis(milliseconds));
  } while (ready < 0 && errno == EINTR);
  if (ready <= 0) {
    return -1;
  }
  return hilde_socket_accept(listener);
}

/* Close the listening socket and remove its file.  1 when both worked. */
int32_t hilde_socket_close_listener(int32_t listener, uint8_t* path) {
  int closed = (close(listener) == 0) ? 1 : 0;
  int removed = (unlink((const char*) path) == 0) ? 1 : 0;

  return closed && removed;
}

/*
 * A TCP connection.
 *
 * The socket half of Standard.HttpClient: a connection to an address the
 * caller resolved and checked, made within a time limit, and a wait for a
 * socket that libtls, over a non-blocking socket, asks to be read or
 * written.
 *
 * The address comes as its 4 or 16 bytes in network byte order, the port as
 * a number.  The connect is non-blocking and waited for with poll(2), so it
 * ends when the time is up and not when the kernel gives up; the socket is
 * made blocking again afterwards, since a FileDescriptor of Standard.File is
 * read and written blocking.  Everything used here is visible under
 * -std=c17 with glibc and on OpenBSD; see the include of netinet/in.h.
 *
 * Like the Unix socket above, the helpers are declared in Bindings.File and
 * Bindings.Tls with pragma Foreign_Import, so their signatures here are
 * exactly what the code generator declares for them.
 */

/* The kind of failure for errno after a connect: -1 refused, -2 timed out,
   -3 no route to the address or no network for its family, -4 anything
   else. */
#if !defined(__wasi__)
static int32_t hilde_tcp_failure(int error) {
  if (error == ECONNREFUSED) {
    return -1;
  }
  if (error == ETIMEDOUT) {
    return -2;
  }
  if (error == ENETUNREACH || error == EHOSTUNREACH || error == EAFNOSUPPORT
      || error == EADDRNOTAVAIL) {
    return -3;
  }
  return -4;
}
#endif

#if !defined(__wasi__)
/* Connect a stream socket of family to the target_size bytes of target
   within milliseconds, as hilde_tcp_connect below: the descriptor,
   blocking and close-on-exec, or -1 to -4 as there. */
static int32_t hilde_tcp_connect_to(const struct sockaddr* target, socklen_t target_size,
                                    int family, uint32_t milliseconds) {
  int fd;
  int flags;
  int ready;
  int error = 0;
  socklen_t error_size = sizeof error;
  struct pollfd waiting;

  fd = hilde_file_mark_close_on_exec(socket(family, SOCK_STREAM, 0));
  if (fd < 0) {
    return hilde_tcp_failure(errno);
  }
  flags = fcntl(fd, F_GETFL);
  if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) != 0) {
    close(fd);
    return -4;
  }
  if (connect(fd, target, target_size) != 0) {
    if (errno != EINPROGRESS) {
      error = errno;
      close(fd);
      return hilde_tcp_failure(error);
    }
    waiting.fd = fd;
    waiting.events = POLLOUT;
    waiting.revents = 0;
    do {
      ready = poll(&waiting, 1, hilde_poll_millis(milliseconds));
    } while (ready < 0 && errno == EINTR);
    if (ready == 0) {
      close(fd);
      return -2;
    }
    if (ready < 0 || getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &error_size) != 0) {
      close(fd);
      return -4;
    }
    if (error != 0) {
      close(fd);
      return hilde_tcp_failure(error);
    }
  }
  if (fcntl(fd, F_SETFL, flags) != 0) {
    close(fd);
    return -4;
  }
  return fd;
}
#endif

/* Connect to the size bytes at address, 4 of IPv4 or 16 of IPv6, at port,
   within milliseconds (at most 2147483647, Standard.File refuses more).
   The descriptor, blocking and close-on-exec, or
     -1  refused: nobody listens at the port
     -2  no answer within the time
     -3  no route to the address, or no network for its family
     -4  anything else, a size that is neither 4 nor 16 among it.
   A signal restarts the wait with the whole time again, as in
   hilde_socket_accept_within. */
int32_t hilde_tcp_connect(uint8_t* address, hilde_index_t size, uint16_t port,
                          uint32_t milliseconds) {
#if defined(__wasi__)
  (void) address;
  (void) size;
  (void) port;
  (void) milliseconds;
  return -3;
#else
  struct sockaddr_in v4;
  struct sockaddr_in6 v6;
  struct sockaddr* target;
  socklen_t target_size;
  int family;

  if (size == 4) {
    memset(&v4, 0, sizeof v4);
    v4.sin_family = AF_INET;
    v4.sin_port = htons(port);
    memcpy(&v4.sin_addr, address, 4);
    target = (struct sockaddr*) &v4;
    target_size = sizeof v4;
    family = AF_INET;
  } else if (size == 16) {
    memset(&v6, 0, sizeof v6);
    v6.sin6_family = AF_INET6;
    v6.sin6_port = htons(port);
    memcpy(&v6.sin6_addr, address, 16);
    target = (struct sockaddr*) &v6;
    target_size = sizeof v6;
    family = AF_INET6;
  } else {
    return -4;
  }
  return hilde_tcp_connect_to(target, target_size, family, milliseconds);
#endif
}

/* A TCP socket bound to the size bytes at address, 4 of IPv4 or 16 of
   IPv6, at port, and listening with a backlog of 128.  Port 0 lets the
   kernel choose one, which hilde_tcp_local_port tells.  SO_REUSEADDR is
   set so that a server can be started again at once on the port of one
   that ended; an IPv6 socket takes only IPv6, so that an address means
   one family.  The descriptor, blocking and close-on-exec, or -1. */
int32_t hilde_tcp_listen(uint8_t* address, hilde_index_t size, uint16_t port) {
#if defined(__wasi__)
  (void) address;
  (void) size;
  (void) port;
  return -1;
#else
  struct sockaddr_in v4;
  struct sockaddr_in6 v6;
  struct sockaddr* local;
  socklen_t local_size;
  int family;
  int fd;
  int on = 1;

  if (size == 4) {
    memset(&v4, 0, sizeof v4);
    v4.sin_family = AF_INET;
    v4.sin_port = htons(port);
    memcpy(&v4.sin_addr, address, 4);
    local = (struct sockaddr*) &v4;
    local_size = sizeof v4;
    family = AF_INET;
  } else if (size == 16) {
    memset(&v6, 0, sizeof v6);
    v6.sin6_family = AF_INET6;
    v6.sin6_port = htons(port);
    memcpy(&v6.sin6_addr, address, 16);
    local = (struct sockaddr*) &v6;
    local_size = sizeof v6;
    family = AF_INET6;
  } else {
    return -1;
  }
  fd = hilde_file_mark_close_on_exec(socket(family, SOCK_STREAM, 0));
  if (fd < 0) {
    return -1;
  }
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof on) != 0
      || (family == AF_INET6
          && setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &on, sizeof on) != 0)
      || bind(fd, local, local_size) != 0 || listen(fd, 128) != 0) {
    close(fd);
    return -1;
  }
  return fd;
#endif
}

/* The local port of a TCP socket, or 0 when getsockname failed. */
uint16_t hilde_tcp_local_port(int32_t fd) {
#if defined(__wasi__)
  (void) fd;
  return 0;
#else
  struct sockaddr_storage local;
  socklen_t local_size = sizeof local;

  memset(&local, 0, sizeof local);
  if (getsockname(fd, (struct sockaddr*) &local, &local_size) != 0) {
    return 0;
  }
  if (local.ss_family == AF_INET) {
    return ntohs(((struct sockaddr_in*) &local)->sin_port);
  }
  if (local.ss_family == AF_INET6) {
    return ntohs(((struct sockaddr_in6*) &local)->sin6_port);
  }
  return 0;
#endif
}

/* Make the socket non-blocking.  1, or 0 when fcntl failed. */
int32_t hilde_socket_nonblocking(int32_t fd) {
  int flags = fcntl(fd, F_GETFL);

  if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) != 0) {
    return 0;
  }
  return 1;
}

/* Make the socket blocking again.  1, or 0 when fcntl failed. */
int32_t hilde_socket_blocking(int32_t fd) {
  int flags = fcntl(fd, F_GETFL);

  if (flags < 0 || fcntl(fd, F_SETFL, flags & ~O_NONBLOCK) != 0) {
    return 0;
  }
  return 1;
}

/* One poll(2) of hilde_socket_wait, its arguments and its answer, for a
   helper thread: a wait on a socket can last as long as its caller allows,
   and it must not hold the worker and the tasks queued on it.  errno is
   the helper's, and the caller's is not it. */
typedef struct hilde_socket_wait_call {
  struct pollfd waiting;
  int milliseconds;
  int ready;
  int error;
} hilde_socket_wait_call_t;

static __attribute__((unused)) void hilde_socket_wait_blocking(void* raw) {
  hilde_socket_wait_call_t* call = (hilde_socket_wait_call_t*) raw;

  call->ready = poll(&call->waiting, 1, call->milliseconds);
  call->error = (call->ready < 0) ? errno : 0;
}

/* Wait until the socket can be read, or written when writing is 1, at most
   milliseconds, or without a limit when it is negative.  1 when it is
   ready or a signal came (the caller then asks again and waits again with
   what is left), 0 when the time ran out, -1 when poll failed.  An error
   or a hang-up on the socket counts as ready: the next read or write then
   says what happened.  The wait runs through hilde_task_blocking, so that
   it holds a helper thread and not the worker, as every other long wait of
   the runtime does; a signal is not waited out here, so that the caller
   takes the wait up again with what is left of its time. */
int32_t hilde_socket_wait(int32_t fd, int32_t writing, int32_t milliseconds) {
  hilde_socket_wait_call_t call;

  call.waiting.fd = fd;
  call.waiting.events = (writing == 1) ? POLLOUT : POLLIN;
  call.waiting.revents = 0;
  call.milliseconds = (milliseconds < 0) ? -1 : (int) milliseconds;
  call.ready = -1;
  call.error = 0;
  hilde_task_blocking(hilde_socket_wait_blocking, &call);
  if (call.ready < 0) {
    return (call.error == EINTR) ? 1 : -1;
  }
  return (call.ready > 0) ? 1 : 0;
}

/* The milliseconds left until deadline, a reading of the monotonic clock
   in nanoseconds; 0 when it has passed.  Without a monotonic clock
   (deadline -1) every wait gets the whole limit again. */
static int32_t hilde_socket_left(int64_t deadline, uint32_t milliseconds) {
  int64_t now;
  int64_t left;

  if (deadline < 0) {
    return (milliseconds > (uint32_t) INT32_MAX) ? INT32_MAX : (int32_t) milliseconds;
  }
  now = hilde_time_monotonic_nanos();
  if (now < 0 || now >= deadline) {
    return 0;
  }
  left = (deadline - now + 999999) / 1000000;
  return (left > INT32_MAX) ? INT32_MAX : (int32_t) left;
}

static int64_t hilde_socket_deadline(uint32_t milliseconds) {
  int64_t now = hilde_time_monotonic_nanos();

  return (now < 0) ? -1 : now + (int64_t) milliseconds * 1000000;
}

/* Standard.File.readWithin: at most count bytes from a non-blocking socket,
   waiting at most milliseconds in all for some to come.  The bytes read, 0
   at the end of the stream, -1 on an error, -2 when the time ran out.  A
   signal that ends the wait early is waited out with what is left. */
int64_t hilde_socket_read_within(int32_t fd, uint8_t* buffer, size_t count, uint32_t milliseconds) {
  int64_t deadline = hilde_socket_deadline(milliseconds);

  for (;;) {
    ssize_t n = read(fd, buffer, count);
    int32_t left;
    int32_t ready;

    if (n >= 0) {
      return (int64_t) n;
    }
    if (errno == EINTR) {
      continue;
    }
    if (errno != EAGAIN && errno != EWOULDBLOCK) {
      return -1;
    }
    left = hilde_socket_left(deadline, milliseconds);
    if (left == 0) {
      return -2;
    }
    ready = hilde_socket_wait(fd, 0, left);
    if (ready == 0) {
      return -2;
    }
    if (ready < 0) {
      return -1;
    }
  }
}

/* 1 when the other end of a pipe has gone: poll says error, hang-up or an
   invalid descriptor for the write end.  A write(2) to such a pipe raises
   SIGPIPE, which send(2) with MSG_NOSIGNAL does not, so a pipe is asked
   first, and a reader that has gone is a failure.  A reader that closes
   between this and the write is not seen; a programme ignores SIGPIPE
   (hilde_store_cli_args), so that write fails with EPIPE, and in a library
   it raises SIGPIPE as the host has it set. */
static int hilde_pipe_gone(int32_t fd) {
  struct pollfd waiting;

  waiting.fd = fd;
  waiting.events = POLLOUT;
  waiting.revents = 0;
  return poll(&waiting, 1, 0) > 0 && (waiting.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0;
}

/* Standard.File.writeWithin: all count bytes to a non-blocking socket or
   pipe within milliseconds in all.  count when every byte went out, -1 on an
   error, -2 when the time ran out first.  The bytes go out with
   MSG_NOSIGNAL, so that a peer that closed gives EPIPE and not a SIGPIPE
   that ends the programme; Linux, OpenBSD and FreeBSD all have the flag, and
   a build there whose socket header lacks it stops here.  SOCK_STREAM says
   that header was read: a tool that reads this file without the system's
   headers, as cppcheck does, is not stopped.  A descriptor that is not a
   socket (send(2) says ENOTSOCK), a pipe to a child process, is written with
   write(2) from then on, after hilde_pipe_gone has looked at it. */
#if (defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
     defined(__APPLE__)) && defined(SOCK_STREAM) && !defined(MSG_NOSIGNAL)
#error "MSG_NOSIGNAL is missing: hilde_socket_write_within would raise SIGPIPE"
#endif
int64_t hilde_socket_write_within(int32_t fd, const uint8_t* buffer, size_t count, uint32_t milliseconds) {
  int64_t deadline = hilde_socket_deadline(milliseconds);
  size_t written = 0;
  int plain = 0;

  while (written < count) {
    ssize_t n;
    int32_t left;
    int32_t ready;

    if (plain) {
      if (hilde_pipe_gone(fd)) {
        return -1;
      }
      n = write(fd, buffer + written, count - written);
    } else {
#ifdef MSG_NOSIGNAL
      n = send(fd, buffer + written, count - written, MSG_NOSIGNAL);
      if (n < 0 && errno == ENOTSOCK) {
        plain = 1;
        continue;
      }
#else
      n = write(fd, buffer + written, count - written);
#endif
    }
    if (n > 0) {
      written += (size_t) n;
      continue;
    }
    if (n < 0 && errno == EINTR) {
      continue;
    }
    if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
      return -1;
    }
    left = hilde_socket_left(deadline, milliseconds);
    if (left == 0) {
      return -2;
    }
    ready = hilde_socket_wait(fd, 1, left);
    if (ready == 0) {
      return -2;
    }
    if (ready < 0) {
      return -1;
    }
  }
  return (int64_t) count;
}

/* libtls reads and writes a socket with read(2) and write(2) when it is
   given the socket or opens one itself, and a write to a peer that has
   closed raises SIGPIPE, which ends the whole programme.  Standard.Tls
   gives libtls every socket through tls_accept_cbs and tls_connect_cbs
   with the two functions below in place of the library's own: the socket
   is the argument, the bytes go with recv(2) and with send(2) and
   MSG_NOSIGNAL, so that a peer that closed is an error of the call.  A
   socket that cannot take or give bytes now answers libtls's want values,
   -2 to be read and -3 to be written (TLS_WANT_POLLIN and TLS_WANT_POLLOUT
   of tls.h, which a programme without libtls does not have).  The
   functions are static inline: a programme that does not use Standard.Tls
   emits none of them and needs no -ltls; the two prototypes of libtls are
   declarations only. */
struct tls;
int tls_accept_cbs(struct tls* server, struct tls** connection,
                   ssize_t (*read_cb)(struct tls*, void*, size_t, void*),
                   ssize_t (*write_cb)(struct tls*, const void*, size_t, void*), void* argument);
int tls_connect_cbs(struct tls* context,
                    ssize_t (*read_cb)(struct tls*, void*, size_t, void*),
                    ssize_t (*write_cb)(struct tls*, const void*, size_t, void*), void* argument,
                    const char* servername);

static inline __attribute__((unused))
ssize_t hilde_tls_read_cb(struct tls* context, void* buffer, size_t count, void* argument) {
  int fd = (int) (intptr_t) argument;
  ssize_t n;

  (void) context;
  do {
    n = recv(fd, buffer, count, 0);
  } while (n < 0 && errno == EINTR);
  if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
    return -2;
  }
  return n;
}

static inline __attribute__((unused))
ssize_t hilde_tls_write_cb(struct tls* context, const void* buffer, size_t count, void* argument) {
  int fd = (int) (intptr_t) argument;
  ssize_t n;

  (void) context;
  do {
#ifdef MSG_NOSIGNAL
    n = send(fd, buffer, count, MSG_NOSIGNAL);
#else
    n = send(fd, buffer, count, 0);
#endif
  } while (n < 0 && errno == EINTR);
  if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
    return -3;
  }
  return n;
}

/* tls_accept_socket and tls_connect_socket of libtls, with the two
   functions above in place of the library's own reads and writes. */
static inline __attribute__((unused))
int32_t hilde_tls_accept_socket(void* server, void** connection, int32_t fd) {
  return (int32_t) tls_accept_cbs((struct tls*) server, (struct tls**) connection,
                                  hilde_tls_read_cb, hilde_tls_write_cb, (void*) (intptr_t) fd);
}

static inline __attribute__((unused))
int32_t hilde_tls_connect_socket(void* context, int32_t fd, const char* servername) {
  return (int32_t) tls_connect_cbs((struct tls*) context, hilde_tls_read_cb, hilde_tls_write_cb,
                                   (void*) (intptr_t) fd, servername);
}

/* How long hilde_tls_tcp_connect waits for one address to take the
   connection, the connect limit Standard.HttpClient uses by default. */
#define HILDE_TLS_CONNECT_MILLIS 10000u

#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
/* One name resolution and connect of hilde_tls_tcp_connect, its arguments
   and its answer, for a helper thread. */
typedef struct hilde_tls_connect_call {
  const char* host;
  const char* port;
  int32_t fd;
} hilde_tls_connect_call_t;

static __attribute__((unused)) void hilde_tls_connect_blocking(void* raw) {
  hilde_tls_connect_call_t* call = (hilde_tls_connect_call_t*) raw;
  hilde_addrinfo_t hints;
  hilde_addrinfo_t* list = NULL;

  call->fd = -1;
  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  if (hilde_libc_getaddrinfo(call->host, call->port, &hints, &list) != 0) {
    return;
  }
  for (hilde_addrinfo_t* at = list; at != NULL && call->fd < 0; at = at->ai_next) {
    int32_t fd = hilde_tcp_connect_to((const struct sockaddr*) at->ai_addr,
                                      (socklen_t) at->ai_addrlen, at->ai_family,
                                      HILDE_TLS_CONNECT_MILLIS);

    if (fd >= 0) {
      call->fd = fd;
    }
  }
  hilde_libc_freeaddrinfo(list);
}

#if defined(HILDE_VALGRIND)
/* Under valgrind the call runs on a thread of its own that ends with it,
   as in hilde_resolve: the resolver state the C library keeps for a
   helper that lives to the end would count as lost. */
static __attribute__((unused)) void* hilde_tls_connect_thread(void* raw) {
  hilde_tls_connect_blocking(raw);
  return NULL;
}
#endif
#endif

/* What tls_connect does before its handshake, so that the socket is the
   runtime's and goes through the two functions above: every address of
   host for port, a number or a service name, from getaddrinfo, tried in
   its order until one connects, each within HILDE_TLS_CONNECT_MILLIS.  The
   resolution and the connects run through hilde_task_blocking, so that a
   host that does not answer holds a helper thread and not the worker and
   the tasks queued on it.  The socket is blocking and close-on-exec.  Its
   number, or -1 when the name has no address or no address took the
   connection; on a system whose resolver layout is not checked, always
   -1. */
static inline __attribute__((unused))
int32_t hilde_tls_tcp_connect(const char* host, const char* port) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
  hilde_tls_connect_call_t call;

  call.host = host;
  call.port = port;
  call.fd = -1;
#if defined(HILDE_VALGRIND)
  pthread_t connector;
  if (pthread_create(&connector, NULL, hilde_tls_connect_thread, &call) == 0) {
    if (pthread_join(connector, NULL) != 0) {
      hilde_stop("Hilde: the thread of a TLS connect could not be joined");
    }
  } else {
    hilde_task_blocking(hilde_tls_connect_blocking, &call);
  }
#else
  hilde_task_blocking(hilde_tls_connect_blocking, &call);
#endif
  return call.fd;
#else
  (void) host;
  (void) port;
  return -1;
#endif
}
