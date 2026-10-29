/*
    Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

    Hilde is derived from the Austral project and extends it substantially.
    Modified by Heiko Zimmermann, 2026.
*/
/* Runtime prelude of the Hilde compiler, derived from the Austral prelude. */
#include <stdint.h>
#include <stddef.h>

/*
 * Hilde types
 */

typedef uint8_t   hilde_unit_t;
typedef uint8_t   hilde_bool_t;
typedef uint8_t   hilde_nat8_t;
typedef int8_t    hilde_int8_t;
typedef uint16_t  hilde_nat16_t;
typedef int16_t   hilde_int16_t;
typedef uint32_t  hilde_nat32_t;
typedef int32_t   hilde_int32_t;
typedef uint64_t  hilde_nat64_t;
typedef int64_t   hilde_int64_t;
typedef size_t    hilde_index_t;
typedef void    (*hilde_fnptr_t)(void);
typedef uint8_t   hilde_region_t;

#define nil   0
#define false 0
#define true  1

/*
 * A store through ptr that gives nil, so that it can stand where the
 * generated code needs an expression of the unit type.
 */

#define HILDE_STORE(ptr, val) (*(ptr) = (val), nil)

/*
 * What every generated programme uses: spans, the standard streams,
 * stopping and printing.
 */

typedef struct {
  void* data;
  size_t size;
} hilde_span_t;

extern hilde_span_t hilde_make_span(void* data, size_t size);

extern hilde_span_t hilde_make_span_from_string(const char* data, size_t size);

extern hilde_fnptr_t hilde_fnptr_from_object(void* object);

extern void* hilde_array_index(hilde_span_t* array, size_t index, size_t elem_size);

extern void* hilde_stdout(void);

extern void* hilde_stderr(void);

extern void* hilde_stdin(void);

/* _Noreturn: the generated code ends a great many functions with a call to
   this one.  Without it, compilers and static analysers read on past the
   stop and warn "control reaches end of non-void function" at each of
   them. */
extern _Noreturn hilde_unit_t hilde_abort(hilde_span_t message);

/* A precondition, a requires clause, that does not hold stops the programme
   here, with the compiler's message and the call site. */
extern _Noreturn hilde_unit_t hilde_contract_requires_failed(hilde_span_t message, hilde_span_t site);

extern hilde_unit_t hilde_printf(const char* format, ...);

/*
 * Memory functions
 */

extern void* hilde_calloc(size_t size, size_t count);

extern void* hilde_realloc(void* ptr, size_t count);

extern void* hilde_memmove(void* destination, void* source, size_t count);

extern void* hilde_memcpy(void* destination, void* source, size_t count);

extern hilde_unit_t hilde_free(void* ptr);

/* Clears size bytes at ptr: explicit_bzero where the system has it, a
   volatile write loop everywhere else.  Never memset, which the compiler
   may drop when the memory is not read again. */
extern void hilde_wipe(void* ptr, size_t size);

/*
 * Arena memory.  The handle is opaque here; what makes it safe is on the
 * Hilde side, in Standard.Arena.
 */

extern void* hilde_arena_create(size_t capacity);

extern void* hilde_arena_alloc(void* handle, size_t size);

extern hilde_unit_t hilde_arena_reset(void* handle);

extern hilde_unit_t hilde_arena_destroy(void* handle);

extern size_t hilde_arena_used(void* handle);

extern size_t hilde_arena_capacity(void* handle);

/*
 * Confining the running process, for Standard.Sandbox.  Each function
 * answers what it did, so that the sandbox can report which mechanism is
 * in force.
 */

extern int hilde_sandbox_set_no_new_privileges(void);

extern int hilde_sandbox_query_no_new_privileges(void);

/*
 * Files, for Standard.File.  A descriptor has a linear type there, used
 * exactly once, which is what keeps these from being called twice on one
 * number.
 */

extern int hilde_file_open_read(const uint8_t* path);

extern int hilde_file_open_write(const uint8_t* path);

extern int hilde_file_close(int fd);

extern int64_t hilde_file_read(int fd, uint8_t* buffer, size_t count);

extern int hilde_file_write_all(int fd, const uint8_t* buffer, size_t count);

extern int hilde_file_remove(const uint8_t* path);

extern uint64_t hilde_time_wall_nanos(void);

extern int hilde_time_has_monotonic(void);

extern int64_t hilde_time_monotonic_nanos(void);

extern int hilde_file_kind(const uint8_t* path, int follow);

extern int64_t hilde_file_read_link(const uint8_t* path, uint8_t* buffer,
                                    size_t size);

extern int hilde_file_make_link(const uint8_t* target, const uint8_t* name);

/*
 * A pipe and a poller.  The poller names its backend, epoll or kqueue;
 * where there is none, hilde_poller_backend says so and
 * hilde_poller_create answers a null pointer.
 */

extern int hilde_pipe_open(int* ends);

extern int hilde_poller_backend(void);

extern void* hilde_poller_create(void);

extern int hilde_poller_add(void* handle, int fd, int interest);

extern int hilde_poller_modify(void* handle, int fd, int interest);

extern int hilde_poller_drop(void* handle, int fd);

extern size_t hilde_poller_registered(void* handle);

extern int hilde_poller_wait(void* handle, int timeout_ms);

extern int hilde_poller_event_fd(void* handle, size_t index);

extern int hilde_poller_event_flags(void* handle, size_t index);

extern hilde_unit_t hilde_poller_destroy(void* handle);

/*
 * Command-line arguments
 */

void hilde_store_cli_args(int argc, char** argv);

size_t hilde_get_argc(void);

hilde_span_t hilde_get_nth_arg(size_t n);
