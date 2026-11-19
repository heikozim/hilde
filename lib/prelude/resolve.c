/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

#include "internal.h"

/* Name resolution through getaddrinfo of the C library, asked for every
   address of a name, of both families, for a stream socket so that each
   address comes once and not once per socket type.  The struct of the
   answers and the two functions are declared in internal.h. */

/* The addresses of name, written to out as records of 17 bytes each: the
   length of the address, 4 or 16, then the address in network byte order,
   padded with zeros to 16.  Every address is written as the resolver gave
   it; Standard.Resolve reads the records and folds an IPv6 address that
   maps an IPv4 one into that IPv4 address.  The count records
   caps how many are written; the rest are dropped.  The name comes as a
   span without a terminating zero and a copy with one is made; a name
   holding a zero byte is refused, since C would read it only up to that
   byte.

   Returns how many records were written, or
     -1  the resolver knows no address for the name (EAI_NONAME, EAI_NODATA)
     -2  the resolver could not be asked or did not answer (EAI_AGAIN,
         EAI_FAIL): asking again later may succeed
     -3  anything else: no memory, a system error, a zero byte, a system
         whose layout is not checked.
   Static and marked unused: a programme that does not call it does not
   emit it. */
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
/* One getaddrinfo(3), its arguments and its answers, handed to a helper
   thread. */
typedef struct hilde_resolve_call {
  const char* node;
  hilde_addrinfo_t hints;
  hilde_addrinfo_t* list;
  int answer;
} hilde_resolve_call_t;

static __attribute__((unused)) void hilde_resolve_blocking(void* raw) {
  hilde_resolve_call_t* call = (hilde_resolve_call_t*) raw;

  call->answer = hilde_libc_getaddrinfo(call->node, NULL, &call->hints, &call->list);
}

#if defined(HILDE_VALGRIND)
/* Under valgrind the call runs on a thread of its own that ends with it.
   The C library keeps the resolver's state of a thread until that thread
   ends, a helper of the runtime lives to the end of the programme, and
   valgrind counts the state such a helper still holds as lost. */
static __attribute__((unused)) void* hilde_resolve_thread(void* raw) {
  hilde_resolve_blocking(raw);
  return NULL;
}
#endif
#endif

static inline __attribute__((unused))
hilde_int32_t hilde_resolve(hilde_span_t name, void* out, size_t records) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  const size_t record = 17;

  if (name.size == 0 || memchr(name.data, 0, name.size) != NULL) {
    return -3;
  }
  char* node = calloc(name.size + 1, 1);
  if (node == NULL) {
    return -3;
  }
  memcpy(node, name.data, name.size);
  hilde_resolve_call_t call;
  memset(&call.hints, 0, sizeof call.hints);
  call.hints.ai_family = AF_UNSPEC;
  call.hints.ai_socktype = SOCK_STREAM;
  call.node = node;
  call.list = NULL;
#if defined(HILDE_VALGRIND)
  pthread_t resolver;
  if (pthread_create(&resolver, NULL, hilde_resolve_thread, &call) == 0) {
    if (pthread_join(resolver, NULL) != 0) {
      hilde_stop("Hilde: the thread of a name resolution could not be joined");
    }
  } else {
    hilde_task_blocking(hilde_resolve_blocking, &call);
  }
#else
  hilde_task_blocking(hilde_resolve_blocking, &call);
#endif
  hilde_addrinfo_t* list = call.list;
  int answer = call.answer;
  free(node);
  if (answer != 0) {
    /* EAI_NONAME, EAI_NODATA, EAI_AGAIN and EAI_FAIL by the numbers above;
       scripts/resolver/check-header.sh holds them to the headers. */
    if (answer == HILDE_EAI_NONAME || answer == HILDE_EAI_NODATA) {
      return -1;
    }
    if (answer == HILDE_EAI_AGAIN || answer == HILDE_EAI_FAIL) {
      return -2;
    }
    return -3;
  }
  unsigned char* at = out;
  size_t written = 0;
  for (hilde_addrinfo_t* a = list; a != NULL && written < records; a = a->ai_next) {
    const unsigned char* socket_address = a->ai_addr;

    if (socket_address == NULL) {
      continue;
    }
    memset(at, 0, record);
    if (a->ai_family == AF_INET && a->ai_addrlen >= 8) {
      at[0] = 4;
      memcpy(at + 1, socket_address + 4, 4);
    } else if (a->ai_family == AF_INET6 && a->ai_addrlen >= 24) {
      at[0] = 16;
      memcpy(at + 1, socket_address + 8, 16);
    } else {
      continue;
    }
    at += record;
    written++;
  }
  hilde_libc_freeaddrinfo(list);
  return (hilde_int32_t) written;
#else
  (void) name;
  (void) out;
  (void) records;
  return -3;
#endif
}
