/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * Waiting on many descriptors: epoll on Linux, kqueue on the BSDs and
 * macOS.
 */

#include "internal.h"

/*
 * Waiting on many descriptors.
 *
 * One interface, and one backend behind it on each platform: epoll on
 * Linux, kqueue on OpenBSD, FreeBSD and macOS, none elsewhere.  The interface
 * names its backend: a programme that cannot say which poller it is using
 * cannot say what its timeouts mean.
 */

#define HILDE_POLLER_BACKEND_NONE 0
#define HILDE_POLLER_BACKEND_EPOLL 1
#define HILDE_POLLER_BACKEND_KQUEUE 2

#define HILDE_POLLER_READ 1
#define HILDE_POLLER_WRITE 2
#define HILDE_POLLER_ERROR 4

/* How many ready descriptors one wait can report.  A number and not a
   growing buffer: the events live in the poller, the caller reads them out
   by index, and a wait that fills the buffer is answered by the next wait.
   64 is the same order as the queue depth a single-threaded responder can
   usefully act on before it comes back. */
#define HILDE_POLLER_MAX_EVENTS 64

/* Which backend this binary has.  A programme may ask before it builds
   anything, because the answer decides whether it can run at all; a null
   pointer from the constructor as the only answer would make every
   programme find out by failing. */
int hilde_poller_backend(void) {
#if defined(__linux__)
  return HILDE_POLLER_BACKEND_EPOLL;
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
  return HILDE_POLLER_BACKEND_KQUEUE;
#else
  return HILDE_POLLER_BACKEND_NONE;
#endif
}

#if defined(__linux__)

typedef struct {
  int fd;
  int ready;
  size_t registered;
  struct epoll_event events[HILDE_POLLER_MAX_EVENTS];
} hilde_poller_t;

static uint32_t hilde_poller_mask(int interest) {
  uint32_t mask = 0;

  if ((interest & HILDE_POLLER_READ) != 0) {
    mask |= EPOLLIN;
  }
  if ((interest & HILDE_POLLER_WRITE) != 0) {
    mask |= EPOLLOUT;
  }
  return mask;
}

void* hilde_poller_create(void) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_poller_t* poller = (hilde_poller_t*) calloc(1, sizeof(hilde_poller_t));

  if (poller == NULL) {
    return NULL;
  }
  poller->fd = epoll_create1(EPOLL_CLOEXEC);
  if (poller->fd < 0) {
    free(poller);
    return NULL;
  }
  poller->ready = 0;
  poller->registered = 0;
  return poller;
}

int hilde_poller_add(void* handle, int fd, int interest) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;
  struct epoll_event event;

  if (poller == NULL) {
    return 0;
  }
  event.events = hilde_poller_mask(interest);
  event.data.fd = fd;
  if (epoll_ctl(poller->fd, EPOLL_CTL_ADD, fd, &event) != 0) {
    return 0;
  }
  poller->registered += 1;
  return 1;
}

int hilde_poller_modify(void* handle, int fd, int interest) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;
  struct epoll_event event;

  if (poller == NULL) {
    return 0;
  }
  event.events = hilde_poller_mask(interest);
  event.data.fd = fd;
  return (epoll_ctl(poller->fd, EPOLL_CTL_MOD, fd, &event) == 0) ? 1 : 0;
}

int hilde_poller_drop(void* handle, int fd) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL) {
    return 0;
  }
  if (epoll_ctl(poller->fd, EPOLL_CTL_DEL, fd, NULL) != 0) {
    return 0;
  }
  if (poller->registered > 0) {
    poller->registered -= 1;
  }
  return 1;
}

size_t hilde_poller_registered(void* handle) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  return (poller == NULL) ? 0 : poller->registered;
}

/* Ready descriptors, or -1.  EINTR is retried here and not reported: a
   signal is not an answer, and a caller that had to distinguish it would
   have to write this loop itself.  The retry starts the timeout again from
   the beginning, so a wait that signals keep interrupting can last longer
   than timeout_ms: shortening it would need a clock this module does not
   keep. */
/* One epoll_wait(2), for a helper thread. */
typedef struct hilde_epoll_call {
  hilde_poller_t* poller;
  int timeout;
  int ready;
} hilde_epoll_call_t;

static void hilde_epoll_blocking(void* raw) {
  hilde_epoll_call_t* call = (hilde_epoll_call_t*) raw;

  do {
    call->ready = epoll_wait(call->poller->fd, call->poller->events, HILDE_POLLER_MAX_EVENTS,
                             call->timeout);
  } while (call->ready < 0 && errno == EINTR);
}

int hilde_poller_wait(void* handle, int timeout_ms) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;
  hilde_epoll_call_t call;
  int ready;

  if (poller == NULL) {
    return -1;
  }
  call.poller = poller;
  call.timeout = timeout_ms;
  hilde_task_blocking(hilde_epoll_blocking, &call);
  ready = call.ready;
  poller->ready = (ready < 0) ? 0 : ready;
  return ready;
}

int hilde_poller_event_fd(void* handle, size_t index) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || index >= (size_t) poller->ready) {
    return -1;
  }
  return poller->events[index].data.fd;
}

int hilde_poller_event_flags(void* handle, size_t index) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;
  uint32_t got;
  int flags = 0;

  if (poller == NULL || index >= (size_t) poller->ready) {
    return 0;
  }
  got = poller->events[index].events;
  if ((got & EPOLLIN) != 0) {
    flags |= HILDE_POLLER_READ;
  }
  if ((got & EPOLLOUT) != 0) {
    flags |= HILDE_POLLER_WRITE;
  }
  if ((got & (EPOLLERR | EPOLLHUP)) != 0) {
    flags |= HILDE_POLLER_ERROR;
  }
  return flags;
}

hilde_unit_t hilde_poller_destroy(void* handle) {
  extern void free(void* ptr);
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL) {
    return nil;
  }
  close(poller->fd);
  poller->fd = -1;
  free(poller);
  return nil;
}

#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)

/* kqueue(2).  This backend keeps the contract of the epoll backend above,
   and translates where kqueue differs:

   One descriptor is two registrations.  kqueue has no combined interest
   mask; reading and writing are separate filters.  Both are added when a
   descriptor is watched, the one not asked for disabled, so that a change of
   interest enables or disables a filter and never adds or deletes one.

   One descriptor can come back twice in one wait, once per filter, where
   epoll gives one event with both flags.  The two are merged into one event
   here, so the caller sees what epoll gives it; the kernel's buffer holds
   two kevents for every event this module can hand out.

   EV_EOF on the read filter is not a hangup by itself: it is set as soon as
   the peer shut its writing side, and bytes may still be waiting.  Only
   EV_EOF with nothing left to read raises the error flag; on the write
   filter EV_EOF always does.  So the flag comes at another moment than on
   epoll, which for a pipe raises it as soon as the writer is gone, bytes
   waiting or not.  The error flag is a hint, not an exact moment.

   FreeBSD refuses the write filter of a pipe end whose peer is closed
   already, enabled or not, with EPIPE; the read filter it takes, and that
   one reports the end of file at every wait.  Such a descriptor is accepted
   without its write filter.  Its read filter is enabled whatever the
   interest, and the end of file is reported as epoll reports a closed
   peer: the error flag, and the writable flag where the interest asks for
   writing, because a write would fail at once.

   A descriptor closed while watched leaves the kqueue by itself, as it
   leaves an epoll, and its number can come back with the next file opened.
   The table of watched descriptors asks the kernel before it believes such
   a number, so a new file with the old number is watched as on epoll.

   Level-triggered, as epoll is here: no EV_CLEAR. */

/* The bits of a byte of the table of watched descriptors: the low three
   hold 1 plus the interest, and the next one says that the descriptor's
   write filter could not be attached because its peer is closed. */
#define HILDE_POLLER_KNOWN_INTEREST 0x07
#define HILDE_POLLER_KNOWN_GONE 0x10

typedef struct {
  int fd;
  int ready;
  size_t registered;
  /* Which descriptors are watched, one byte each and indexed by the
     descriptor: 0 for not watched, else 1 plus the interest the kernel
     holds for reading, and the bit that says the peer is gone.  It makes
     watching one twice and dropping or changing one that is not watched
     fail as they do on epoll: kqueue itself takes a second EV_ADD as a
     change. */
  unsigned char* known;
  size_t known_size;
  struct kevent kernel[2 * HILDE_POLLER_MAX_EVENTS];
  int event_fd[HILDE_POLLER_MAX_EVENTS];
  int event_flags[HILDE_POLLER_MAX_EVENTS];
} hilde_poller_t;

/* One change of one filter, applied at once.  Collecting the changes for
   the next wait would save calls, but the interest the kernel holds and the
   one this module was told would then differ until that wait. */
static int hilde_poller_change(hilde_poller_t* poller, int fd, short filter,
                               unsigned short flags) {
  struct kevent change;

  EV_SET(&change, (uintptr_t) fd, filter, flags, 0, 0, NULL);
  return (kevent(poller->fd, &change, 1, NULL, 0, NULL) == 0) ? 1 : 0;
}

/* The part of interest the descriptor's access mode allows.  A filter the
   mode rules out stays disabled whatever the caller asks: macOS reports the
   writing end of a pipe readable once its reader is gone, although a read
   from it fails, where epoll does not.  OpenBSD opens both ends of a pipe
   for reading and writing, and a pipe there carries bytes both ways, so
   for its pipes nothing is ruled out.  When the mode cannot be read the
   interest is kept as asked, and the kernel refuses the descriptor in the
   next call. */
static int hilde_poller_possible(int fd, int interest) {
  int mode = fcntl(fd, F_GETFL);

  if (mode < 0) {
    return interest;
  }
  if ((mode & O_ACCMODE) == O_RDONLY) {
    return interest & ~HILDE_POLLER_WRITE;
  }
  if ((mode & O_ACCMODE) == O_WRONLY) {
    return interest & ~HILDE_POLLER_READ;
  }
  return interest;
}

/* Both filters of fd set to interest, as far as hilde_poller_possible
   allows it: EV_ADD on a filter that is there changes it.  Both are always
   written, so a change that failed halfway is repaired by the next one.
   The table learns the interest as soon as the kernel holds it for
   reading, which is what hilde_poller_held reads back.  The write filter
   goes first: when FreeBSD refuses it with EPIPE, the peer of a pipe is
   closed, the descriptor is accepted without it, and its read filter is
   enabled whatever the interest, because the end of file it reports is
   all the poller will ever hear of that descriptor.  The caller has made
   room for fd. */
static int hilde_poller_set(hilde_poller_t* poller, int fd, int interest) {
  int possible = hilde_poller_possible(fd, interest);
  unsigned short reading = EV_ADD
    | (((possible & HILDE_POLLER_READ) != 0) ? EV_ENABLE : EV_DISABLE);
  unsigned short writing = EV_ADD
    | (((possible & HILDE_POLLER_WRITE) != 0) ? EV_ENABLE : EV_DISABLE);
  int gone = 0;

  if (!hilde_poller_change(poller, fd, EVFILT_WRITE, writing)) {
    if (errno != EPIPE) {
      return 0;
    }
    gone = 1;
    reading = EV_ADD | EV_ENABLE;
  }
  if (!hilde_poller_change(poller, fd, EVFILT_READ, reading)) {
    return 0;
  }
  poller->known[fd] = (unsigned char)
    ((1 + (possible & (HILDE_POLLER_READ | HILDE_POLLER_WRITE)))
     | (gone ? HILDE_POLLER_KNOWN_GONE : 0));
  return 1;
}

/* Room in known for fd: 1, or 0 when memory ran out. */
static int hilde_poller_room(hilde_poller_t* poller, int fd) {
  extern void* realloc(void* ptr, size_t size);
  size_t want;
  unsigned char* grown;

  if ((size_t) fd < poller->known_size) {
    return 1;
  }
  want = (poller->known_size == 0) ? 16 : poller->known_size;
  while (want <= (size_t) fd) {
    want *= 2;
  }
  grown = (unsigned char*) realloc(poller->known, want);
  if (grown == NULL) {
    return 0;
  }
  memset(grown + poller->known_size, 0, want - poller->known_size);
  poller->known = grown;
  poller->known_size = want;
  return 1;
}

static int hilde_poller_watched(hilde_poller_t* poller, int fd) {
  return fd >= 0 && (size_t) fd < poller->known_size && poller->known[fd] != 0;
}

/* Whether the kernel still holds the filters of a watched fd.  A descriptor
   closed while it is watched leaves every kqueue at once, and its number
   comes back with the next file opened; the table does not see the close,
   and epoll forgets such a descriptor by itself.  The read filter is set
   again to the state it has, without EV_ADD: that changes nothing when the
   filter is there and fails when the close took it. */
static int hilde_poller_held(hilde_poller_t* poller, int fd) {
  int interest = (poller->known[fd] & HILDE_POLLER_KNOWN_INTEREST) - 1;

  /* The read filter of a descriptor whose peer is gone is always enabled. */
  if ((poller->known[fd] & HILDE_POLLER_KNOWN_GONE) != 0) {
    interest |= HILDE_POLLER_READ;
  }

  return hilde_poller_change(poller, fd, EVFILT_READ,
    ((interest & HILDE_POLLER_READ) != 0) ? EV_ENABLE : EV_DISABLE);
}

void* hilde_poller_create(void) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_poller_t* poller = (hilde_poller_t*) calloc(1, sizeof(hilde_poller_t));

  if (poller == NULL) {
    return NULL;
  }
  poller->fd = kqueue();
  if (poller->fd < 0) {
    free(poller);
    return NULL;
  }
  /* Close-on-exec is set afterwards with fcntl, one way on all three
     systems.  A kqueue is not inherited by fork(2), so a child forked
     between the two calls has nothing to inherit; the flag is for exec, and
     when it cannot be set no queue is handed out. */
  if (fcntl(poller->fd, F_SETFD, FD_CLOEXEC) != 0) {
    close(poller->fd);
    free(poller);
    return NULL;
  }
  poller->ready = 0;
  poller->registered = 0;
  poller->known = NULL;
  poller->known_size = 0;
  return poller;
}

int hilde_poller_add(void* handle, int fd, int interest) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || fd < 0) {
    return 0;
  }
  if (hilde_poller_watched(poller, fd)) {
    if (hilde_poller_held(poller, fd)) {
      return 0;
    }
    /* Closed while watched.  The number is free again, and it stays
       counted in registered, as the epoll backend keeps counting a
       descriptor the kernel forgot. */
    poller->known[fd] = 0;
  }
  if (!hilde_poller_room(poller, fd)) {
    return 0;
  }
  if (!hilde_poller_set(poller, fd, interest)) {
    /* Nothing of fd is left behind: a filter that was added goes again. */
    hilde_poller_change(poller, fd, EVFILT_READ, EV_DELETE);
    hilde_poller_change(poller, fd, EVFILT_WRITE, EV_DELETE);
    poller->known[fd] = 0;
    return 0;
  }
  poller->registered += 1;
  return 1;
}

int hilde_poller_modify(void* handle, int fd, int interest) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || !hilde_poller_watched(poller, fd)) {
    return 0;
  }
  if (!hilde_poller_held(poller, fd)) {
    /* Closed while watched: refused as epoll refuses it. */
    poller->known[fd] = 0;
    return 0;
  }
  return hilde_poller_set(poller, fd, interest);
}

int hilde_poller_drop(void* handle, int fd) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || !hilde_poller_watched(poller, fd)) {
    return 0;
  }
  if (!hilde_poller_held(poller, fd)) {
    /* Closed while watched: refused and still counted, as on epoll. */
    poller->known[fd] = 0;
    return 0;
  }
  /* Both results unchecked: the filters are there, and the bookkeeping is
     done either way. */
  hilde_poller_change(poller, fd, EVFILT_READ, EV_DELETE);
  hilde_poller_change(poller, fd, EVFILT_WRITE, EV_DELETE);
  poller->known[fd] = 0;
  if (poller->registered > 0) {
    poller->registered -= 1;
  }
  return 1;
}

size_t hilde_poller_registered(void* handle) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  return (poller == NULL) ? 0 : poller->registered;
}

/* Ready descriptors after merging, or -1.  EINTR is retried, as on epoll,
   and the timeout starts again then.  A negative timeout waits without
   end, as epoll_wait does. */
/* One kevent(2) that waits, for a helper thread. */
typedef struct hilde_kevent_call {
  hilde_poller_t* poller;
  struct timespec* until;
  int got;
} hilde_kevent_call_t;

static void hilde_kevent_blocking(void* raw) {
  hilde_kevent_call_t* call = (hilde_kevent_call_t*) raw;

  do {
    call->got = kevent(call->poller->fd, NULL, 0, call->poller->kernel,
                       2 * HILDE_POLLER_MAX_EVENTS, call->until);
  } while (call->got < 0 && errno == EINTR);
}

int hilde_poller_wait(void* handle, int timeout_ms) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;
  struct timespec limit;
  struct timespec* until = NULL;
  hilde_kevent_call_t call;
  int got;
  int filled = 0;
  int i;
  int j;

  if (poller == NULL) {
    return -1;
  }
  if (timeout_ms >= 0) {
    limit.tv_sec = timeout_ms / 1000;
    limit.tv_nsec = (long) (timeout_ms % 1000) * 1000000L;
    until = &limit;
  }
  call.poller = poller;
  call.until = until;
  hilde_task_blocking(hilde_kevent_blocking, &call);
  got = call.got;
  if (got < 0) {
    poller->ready = 0;
    return -1;
  }
  for (i = 0; i < got; i++) {
    int fd = (int) poller->kernel[i].ident;
    int flags = 0;
    int merged = 0;

    if ((poller->kernel[i].flags & EV_ERROR) != 0) {
      flags |= HILDE_POLLER_ERROR;
    } else if (poller->kernel[i].filter == EVFILT_READ) {
      int gone = hilde_poller_watched(poller, fd)
        && (poller->known[fd] & HILDE_POLLER_KNOWN_GONE) != 0;
      int asked = gone ? ((poller->known[fd] & HILDE_POLLER_KNOWN_INTEREST) - 1) : HILDE_POLLER_READ;

      if ((asked & HILDE_POLLER_READ) != 0) {
        flags |= HILDE_POLLER_READ;
      }
      if ((poller->kernel[i].flags & EV_EOF) != 0 && poller->kernel[i].data == 0) {
        flags |= HILDE_POLLER_ERROR;
      }
      /* The peer is gone and the write filter was never attached: a write
         would fail at once, which epoll reports as writable. */
      if (gone && (poller->kernel[i].flags & EV_EOF) != 0 && (asked & HILDE_POLLER_WRITE) != 0) {
        flags |= HILDE_POLLER_WRITE;
      }
    } else if (poller->kernel[i].filter == EVFILT_WRITE) {
      flags |= HILDE_POLLER_WRITE;
      if ((poller->kernel[i].flags & EV_EOF) != 0) {
        flags |= HILDE_POLLER_ERROR;
      }
    }
    if (flags == 0) {
      continue;
    }
    for (j = 0; j < filled; j++) {
      if (poller->event_fd[j] == fd) {
        poller->event_flags[j] |= flags;
        merged = 1;
        break;
      }
    }
    if (!merged && filled < HILDE_POLLER_MAX_EVENTS) {
      poller->event_fd[filled] = fd;
      poller->event_flags[filled] = flags;
      filled += 1;
    }
  }
  poller->ready = filled;
  return filled;
}

int hilde_poller_event_fd(void* handle, size_t index) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || index >= (size_t) poller->ready) {
    return -1;
  }
  return poller->event_fd[index];
}

int hilde_poller_event_flags(void* handle, size_t index) {
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL || index >= (size_t) poller->ready) {
    return 0;
  }
  return poller->event_flags[index];
}

hilde_unit_t hilde_poller_destroy(void* handle) {
  extern void free(void* ptr);
  hilde_poller_t* poller = (hilde_poller_t*) handle;

  if (poller == NULL) {
    return nil;
  }
  close(poller->fd);
  poller->fd = -1;
  free(poller->known);
  free(poller);
  return nil;
}

#else

/* No backend on this platform.  Every call answers as a caller that asked
   hilde_poller_backend first would expect: nothing is created, nothing is
   watched, and no wait succeeds. */

void* hilde_poller_create(void) {
  return NULL;
}

int hilde_poller_add(void* handle, int fd, int interest) {
  (void) handle;
  (void) fd;
  (void) interest;
  return 0;
}

int hilde_poller_modify(void* handle, int fd, int interest) {
  (void) handle;
  (void) fd;
  (void) interest;
  return 0;
}

int hilde_poller_drop(void* handle, int fd) {
  (void) handle;
  (void) fd;
  return 0;
}

size_t hilde_poller_registered(void* handle) {
  (void) handle;
  return 0;
}

int hilde_poller_wait(void* handle, int timeout_ms) {
  (void) handle;
  (void) timeout_ms;
  return -1;
}

int hilde_poller_event_fd(void* handle, size_t index) {
  (void) handle;
  (void) index;
  return -1;
}

int hilde_poller_event_flags(void* handle, size_t index) {
  (void) handle;
  (void) index;
  return 0;
}

hilde_unit_t hilde_poller_destroy(void* handle) {
  (void) handle;
  return nil;
}

#endif /* the poller backends */
