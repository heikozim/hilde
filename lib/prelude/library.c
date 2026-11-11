/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The entry of a library: hilde_start, hilde_end and the checks every
 * exported function makes at its entrance.
 */

#include "internal.h"

/*
 * The runtime of a library
 *
 * hilde_start and hilde_end bracket the calls of a library's exported
 * functions, and every wrapper checks at its entrance that it lies between
 * them: a call outside is a stop with a message, never undefined
 * behaviour.  The host may call from several threads at once.  Each call
 * runs on the thread that made it, and a call that uses tasks hands them
 * to the library's own worker threads (see hilde_task_ready).  In a
 * programme the checks do nothing.
 */

/* 0 before hilde_start, 1 between it and hilde_end, 2 after. */
static int hilde_library_state;

/* The bytes of a span handed in as NULL with the length 0. */
static uint8_t hilde_library_no_bytes[1];

/* A stop for a wrong call of the named function: "Hilde: " and the name,
   then what was wrong. */
static _Noreturn __attribute__((noreturn)) void hilde_library_refuse(const char* name, const char* what) {
  char message[512];
  char head[256];

  hilde_stop_join(head, sizeof head, "Hilde: ", 7, name, strlen(name));
  hilde_stop_join(message, sizeof message, head, strlen(head), what, strlen(what));
  hilde_stop_with(message);
}

/* The entrance of every wrapper, with its export name.  The call is
   counted before the state is read, and hilde_end changes the state before
   it reads the count, so that one of the two always sees the other. */
void hilde_library_enter(const char* name) {
  int state;

  if (!HILDE_IN_LIBRARY) {
    return;
  }
  __atomic_add_fetch(&hilde_library_calls, 1, __ATOMIC_SEQ_CST);
  state = __atomic_load_n(&hilde_library_state, __ATOMIC_SEQ_CST);
  if (state == 0) {
    hilde_library_refuse(name, " was called before hilde_start");
  }
  if (state == 2) {
    hilde_library_refuse(name, " was called after hilde_end");
  }
}

/* The exit of every wrapper. */
void hilde_library_leave(void) {
  if (HILDE_IN_LIBRARY) {
    __atomic_sub_fetch(&hilde_library_calls, 1, __ATOMIC_SEQ_CST);
  }
}

/* The span of bytes a caller handed in as a pointer and a length.  NULL
   with the length 0 is the empty span; NULL with more is a stop. */
hilde_span_t hilde_library_bytes(const char* name, const void* bytes, size_t length) {
  if (bytes == NULL) {
    if (length > 0) {
      hilde_library_refuse(name, " was given no bytes with a length above 0");
    }
    return hilde_make_span(hilde_library_no_bytes, 0);
  }
  return hilde_make_span((void*) bytes, length);
}

/* A handle passed by reference: it must not be NULL. */
void hilde_library_check_handle(const char* name, const void* handle) {
  if (handle == NULL) {
    hilde_library_refuse(name, " was given a null handle");
  }
}

/* A handle passed by value: its value is copied out of the box into into,
   and the box is freed, so that the caller's handle is spent. */
void hilde_library_take(const char* name, void* handle, void* into, size_t size) {
  extern void free(void* ptr);

  hilde_library_check_handle(name, handle);
  memcpy(into, handle, size);
  free(handle);
}

/* A handle for a value returned: a box on the heap holding a copy of it.
   A stop when there is no memory for the box. */
void* hilde_library_box(const char* name, const void* value, size_t size) {
  extern void* malloc(size_t size);
  void* box = malloc(size == 0 ? 1 : size);

  if (box == NULL) {
    hilde_library_refuse(name, ": there is no memory for the handle it returns");
  }
  memcpy(box, value, size);
  return box;
}

#if defined(HILDE_LIBRARY)
/* The three functions a host calls, the only names of the runtime a
   shared library shows (it is built with -fvisibility=hidden). */

/* The argument vector of a library: no arguments. */
static char* hilde_library_no_arguments[1];

__attribute__((visibility("default")))
void hilde_set_abort_handler(void (*handler)(const char* message)) {
  __atomic_store_n(&hilde_library_handler, handler, __ATOMIC_SEQ_CST);
}

__attribute__((visibility("default")))
void hilde_start(void) {
  int expected = 0;

  if (!__atomic_compare_exchange_n(&hilde_library_state, &expected, 1, 0,
                                   __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)) {
    hilde_library_refuse("hilde_start", expected == 1 ? " was called twice"
                                                      : " was called after hilde_end");
  }
  hilde_store_cli_args(0, hilde_library_no_arguments);
}

__attribute__((visibility("default")))
void hilde_end(void) {
  int expected = 1;

  if (!__atomic_compare_exchange_n(&hilde_library_state, &expected, 2, 0,
                                   __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)) {
    hilde_library_refuse("hilde_end", expected == 0 ? " was called before hilde_start"
                                                    : " was called twice");
  }
  if (__atomic_load_n(&hilde_library_calls, __ATOMIC_SEQ_CST) != 0) {
    hilde_library_refuse("hilde_end", " was called while an exported function ran");
  }
  hilde_task_library_stop();
  hilde_flush_output();
}

/* Run when the library is unloaded, by dlclose(3) or at the end of the
   process, also when the host did not call hilde_end: no thread of the
   library may run on in code that is gone.  While an exported function
   still runs its tasks may still run, and the threads are left as they
   are, since waiting for them could hang the host's exit. */
__attribute__((destructor))
static void hilde_library_unload(void) {
  if (__atomic_load_n(&hilde_library_calls, __ATOMIC_SEQ_CST) == 0) {
    hilde_task_library_stop();
  }
}

#if defined(__wasi__)
/* A module for wasm32-wasi shares no memory with its host: the host
   asks for size bytes in the module's memory, writes what it passes
   there, hands the address to an exported function, and gives the bytes
   back.  NULL when there is no memory for them. */
__attribute__((visibility("default")))
void* hilde_wasm_alloc(size_t size) {
  return malloc(size == 0 ? 1 : size);
}

__attribute__((visibility("default")))
void hilde_wasm_free(void* bytes) {
  free(bytes);
}
#endif
#endif
