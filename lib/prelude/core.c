/*
    Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

    Derived from the Austral project, https://github.com/austral/austral.
    Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*/

/*
 * The part of the runtime every programme carries: spans, printing, the
 * ways a programme stops, memory, wiping, the arena, the clock and the
 * command line.
 */

#include "internal.h"

hilde_span_t hilde_make_span(void* data, size_t size) {
  return (hilde_span_t){ .data = data, .size = size };
}

hilde_span_t hilde_make_span_from_string(const char* data, size_t size) {
  return (hilde_span_t){ .data = (void*) data, .size = size };
}

/* The function behind an object pointer, as dlsym(3) returns one.  ISO C
   has no conversion between the two kinds of pointer; POSIX requires that a
   pointer to a function fits in a void* and back, so the bytes are copied.
   The caller casts the result to the function's own type. */
_Static_assert(sizeof(void*) == sizeof(hilde_fnptr_t),
               "a function pointer is not the size of a void*");

hilde_fnptr_t hilde_fnptr_from_object(void* object) {
  hilde_fnptr_t function;
  memcpy(&function, &object, sizeof function);
  return function;
}

/* The C library's three stream variables, reached under names of their own
   where the library calls them stdin, stdout and stderr.  A header a
   programme names through pragma Foreign_Header declares them as pointers
   to the stdio stream type, which this file has not got, and glibc's
   <stdio.h> follows the declarations with #define stdout stdout: a
   renaming of stdout around the header does not survive that line, and
   under -O1 with gcc 14.2.0 the header's own inline functions then name
   an undeclared stdout.  An asm label gives the symbol a C name no header
   declares, so there is nothing left to rename.  At file scope, where the
   list of names the compiler renames (prelude_declared_names in
   lib/Compiler.ml) does not look. */
#if !defined(__APPLE__) && !defined(__FreeBSD__) && !defined(__OpenBSD__)
extern void* hilde_libc_stdout __asm__("stdout");
extern void* hilde_libc_stdin __asm__("stdin");
#endif
#if !defined(__APPLE__) && !defined(__FreeBSD__) && !defined(__OpenBSD__)
extern void* hilde_libc_stderr __asm__("stderr");
#endif

void* hilde_stdout(void) {
#if defined(__APPLE__)
  extern void* __stdoutp;
  return __stdoutp;
#elif defined(__FreeBSD__)
  /* FreeBSD's libc has no symbol named stdout: its <stdio.h> defines stdout
     as the pointer variable __stdoutp, as it does stdin and stderr. */
  extern void* __stdoutp;
  return __stdoutp;
#elif defined(__OpenBSD__)
  /* OpenBSD defines stdout as a cast of the symbol __stdout, which is the
     stream object. Its address is the stream pointer; reading it, the
     way the __APPLE__ branch reads its pointer variable, would hand out
     the first word of the object instead. */
  extern char __stdout[];
  return (void*) __stdout;
#else
  return hilde_libc_stdout;
#endif
}

void* hilde_stderr(void) {
#if defined(__APPLE__)
  extern void* __stderrp;
  return __stderrp;
#elif defined(__FreeBSD__)
  extern void* __stderrp;
  return __stderrp;
#elif defined(__OpenBSD__)
  /* OpenBSD's libc (libc.so.103.0 on 7.9) does not export __sF, the
     stream array older code reaches stderr through, and a link against it
     fails with "undefined symbol". Exported are __stdin, __stdout and
     __stderr, each the stream object itself, as in hilde_stdout. */
  extern char __stderr[];
  return (void*) __stderr;
#else
  return hilde_libc_stderr;
#endif
}

extern void* hilde_stdin(void) {
#if defined(__APPLE__)
  extern void* __stdinp;
  return __stdinp;
#elif defined(__FreeBSD__)
  /* See hilde_stdout: the pointer variable is __stdinp. */
  extern void* __stdinp;
  return __stdinp;
#elif defined(__OpenBSD__)
  /* See hilde_stdout: the symbol is the object, not a pointer to it. */
  extern char __stdin[];
  return (void*) __stdin;
#else
  return hilde_libc_stdin;
#endif
}

/* The two byte functions of Standard.IO.Terminal.  A module that imported
   fputc and fgetc under their own names would meet this: gcc knows fputc
   as a built-in taking an int and a stream pointer, and in a programme
   that names a header which brings <stdio.h> -- <openssl/evp.h> does, on
   OpenSSL and LibreSSL -- it compares the module's declaration, which
   says uint8_t* for the stream, with that type and warns with
   -Wbuiltin-declaration-mismatch (gcc 14.2.0; clang says nothing).
   Declared here, above every header, the two calls meet no stdio type.
   The signatures are what the code generator declares for them -- int32_t
   and uint8_t*, no const -- so that a difference is a compile error. */
/* The stdio functions the runtime calls, under names of their own and
   bound to the libc symbols by an asm label.  <stdio.h> is not included,
   so the stream is a void*.  Declared under the libc names, a void*
   stream is an incompatible redeclaration of a library function to clang,
   and a conflicting-types error next to a header that brings <stdio.h> or
   a module that imports one of them under its own name.  No header
   declares these names, so no declaration can meet them. */
extern int hilde_libc_fputc(int character,
                            void* stream) __asm__(HILDE_ASM_NAME("fputc"));
extern int hilde_libc_fgetc(void* stream) __asm__(HILDE_ASM_NAME("fgetc"));
extern int hilde_libc_fflush(void* stream) __asm__(HILDE_ASM_NAME("fflush"));
extern size_t hilde_libc_fwrite(const void* data, size_t size, size_t count,
                                void* stream) __asm__(HILDE_ASM_NAME("fwrite"));

int32_t hilde_fputc(int32_t character, uint8_t* stream) {
  return hilde_libc_fputc(character, stream);
}

int32_t hilde_fgetc(uint8_t* stream) {
  return hilde_libc_fgetc(stream);
}

/* Write every byte or give up; write(2) may write fewer than asked for.
   Nothing is reported if it fails: this runs on the way out of an abort,
   and there is no second channel left to report it on. */
static void hilde_write_stderr(const char* buffer, size_t count) {
  while (count > 0) {
    ssize_t written = write(2, buffer, count);
    if (written <= 0) {
      return;
    }
    buffer += written;
    count -= (size_t) written;
  }
}

/* Every way a programme stops flushes what it printed before it writes its
   reason and calls _Exit.  Standard output goes through stdio (hilde_printf,
   putchar), stdio buffers it fully when it is a file or a pipe, and _Exit
   does not flush: without this, a programme that printed two lines and
   then stopped would leave a file of 0 bytes.  Flushing first also puts
   the output before the reason in a terminal.  Not called in the child
   after fork (the _exit of hilde_process_spawn): the child holds a copy of
   the parent's buffer, and flushing it there would print it twice. */
static void hilde_flush_output(void) {
  (void) hilde_libc_fflush(NULL);
}


/* The host's handler of a stop, set by hilde_set_abort_handler; in a
   library only. */
static void (*hilde_library_handler)(const char* message);

/* How every stop ends.  A programme ends its process with _Exit(-1).  A
   library does not own the process it runs in: it hands the message to
   the host's handler, when one was set, and then calls abort(3), whose
   SIGABRT a crash reporter sees; a handler that returns changes
   nothing. */
static _Noreturn __attribute__((noreturn)) void hilde_stop(const char* message) {
  extern _Noreturn void _Exit(int status);
  extern _Noreturn void abort(void);

  if (HILDE_IN_LIBRARY) {
    void (*handler)(const char*) = __atomic_load_n(&hilde_library_handler, __ATOMIC_SEQ_CST);

    if (handler != NULL) {
      handler(message);
    }
    abort();
  }
#if defined(__wasi__)
  /* WASI takes an exit status only below 126, so a stop cannot end the
     module with a status of its own; it traps, which its runtime reports
     as a failure (wasmtime with 134). */
  __builtin_trap();
#else
  _Exit(-1);
#endif
}

/* A stop with its message: what was printed flushed first, then the
   message and a line end on standard error, then hilde_stop. */
static _Noreturn __attribute__((noreturn)) void hilde_stop_with(const char* message) {
  hilde_flush_output();
  hilde_write_stderr(message, strlen(message));
  hilde_write_stderr("\n", 1);
  hilde_stop(message);
}

/* The first a_length bytes of a and the first b_length bytes of b joined
   into out, for a message made of two parts.  Each part ends early at a
   zero byte; neither needs one, so a span can be handed in as it is.  The
   result is cut to size and always ends in a zero byte; with size 0
   nothing is written. */
static void hilde_stop_join(char* out, size_t size, const char* a, size_t a_length,
                            const char* b, size_t b_length) {
  size_t used = 0;
  const char* parts[2] = { a, b };
  size_t lengths[2] = { a_length, b_length };
  int i;

  if (size == 0) {
    return;
  }
  for (i = 0; i < 2; i++) {
    size_t k;

    for (k = 0; k < lengths[i] && parts[i][k] != '\0' && used + 1 < size; k++) {
      out[used++] = parts[i][k];
    }
  }
  out[used] = '\0';
}

/* The functions below never return, and say so twice: _Noreturn for the
   C standard and __attribute__((noreturn)) for cppcheck, which checks the
   generated C and does not read _Noreturn (Cppcheck 2.17.1 reports a null
   check before a call of a _Noreturn function as "redundant or a null
   pointer dereference", and does not with the attribute).  The compilers
   read both the same. */
_Noreturn __attribute__((noreturn)) hilde_unit_t hilde_abort_internal(const char* message) {
  hilde_stop_with(message);
}

/* The message is written by its size: a span need not end in a zero byte,
   and a part of a longer text would otherwise run on into the rest.  The
   host of a library gets a copy cut to the buffer and ended with a zero
   byte, also when the span holds one before its end. */
_Noreturn __attribute__((noreturn)) hilde_unit_t hilde_abort(hilde_span_t message) {
  char copy[2048];
  size_t n = (message.size < sizeof copy - 1) ? message.size : sizeof copy - 1;

  hilde_flush_output();
  hilde_write_stderr((const char*) message.data, message.size);
  hilde_write_stderr("\n", 1);
  if (n > 0) {
    memcpy(copy, message.data, n);
  }
  copy[n] = '\0';
  hilde_stop(copy);
}

/* A requires clause that does not hold.  The message is the one the
   compiler made for the clause, the site is where the call stands; both
   are string literals.  They are written out whole, and the host of a
   library gets them joined, cut to the buffer if they are long. */
_Noreturn __attribute__((noreturn)) hilde_unit_t hilde_contract_requires_failed(hilde_span_t message, hilde_span_t site) {
  static const char tail[] = "; the caller is at fault";
  char head[2048];
  char joined[2048];

  hilde_flush_output();
  hilde_write_stderr((const char*) message.data, message.size);
  hilde_write_stderr((const char*) site.data, site.size);
  hilde_write_stderr(tail, sizeof tail - 1);
  hilde_write_stderr("\n", 1);
  hilde_stop_join(head, sizeof head, (const char*) message.data, message.size,
                  (const char*) site.data, site.size);
  hilde_stop_join(joined, sizeof joined, head, strlen(head), tail, sizeof tail - 1);
  hilde_stop(joined);
}

/* Called at the end of a value-returning function that the code generator
   could not prove returns.  Without it the generated function would run
   off its closing brace: C leaves the returned value indeterminate there,
   a caller reading it is undefined behaviour, and gcc and clang warn
   "control reaches end of non-void function".  The call is not expected to
   run; if it ever does, the program stops with a named message instead of
   carrying an indeterminate value out of the function. */
_Noreturn __attribute__((noreturn)) void hilde_unreachable(const char* where) {
  char message[512];

  static const char head[] = "Hilde: control reached the end of a function with no return: ";

  hilde_stop_join(message, sizeof message, head, sizeof head - 1, where, strlen(where));
  hilde_stop_with(message);
}

/* A case that takes a value apart after its patterns have decided has
   branches for the variants the decision ruled out; each is a call to
   this.  None can run: the deciding phase read the tag the taking-apart
   phase switches on, and nothing changed it in between.  If one ever does
   run, the programme stops with a named message instead of going on with
   a value it has not taken apart. */
_Noreturn __attribute__((noreturn)) void hilde_case_unreachable(void) {
  hilde_stop_with("Hilde: a case with patterns reached a branch its decision had ruled out");
}


/* How many exported functions run now, on all threads of the host. */
static int hilde_library_calls;

/*
 * Bindings a Hilde program can import
 *
 * A pragma Foreign_Import makes the code generator write its own
 * declaration of the named C function, from the Hilde types of the
 * declaration.  For a libc function that declaration has to agree with the
 * one the C compiler already knows, and for some of them no Hilde
 * declaration can: puts takes a const char*, and the language has no type
 * that renders as one -- a Span of Nat8 renders as uint8_t*, which gcc
 * reports as conflicting types for the built-in.  Tried with gcc 14.2.0
 * and clang 19.1.7: of uint8_t*, char*, void* and int8_t* beside puts, gcc
 * rejects all four and accepts only const char*.
 *
 * So the binding goes one layer lower: bindings at the bottom, in C, and
 * above them something a safe language can say.  These two wrappers are
 * written in the types Hilde can spell, and the conversion the C ABI wants
 * happens here, in C, where it can be written correctly.
 *
 * Two things this buys beyond the warning.  A program that binds one of
 * these is checked: the wrapper is defined in the same translation unit as
 * the generated declaration, so a Hilde declaration that does not match is
 * a C error rather than a warning nobody reads.  And hilde_put_string
 * takes a size, so it is right for a slice, where puts would run on to the
 * first NUL byte outside it.
 *
 * Both go through putchar, not through write(2): hilde_printf writes
 * through stdio, and a program that used both would otherwise see its
 * output reordered by the buffer.
 */
int32_t hilde_put_character(uint8_t character) {
  extern int putchar(int character);

  return (int32_t) putchar((int) character);
}

int32_t hilde_put_string(uint8_t* data, size_t size) {
  extern int putchar(int character);

  for (size_t i = 0; i < size; i++) {
    if (putchar((int) data[i]) < 0) {
      return -1;
    }
  }
  if (putchar('\n') < 0) {
    return -1;
  }
  return 0;
}

hilde_unit_t hilde_printf(const char* format, ...) {
  extern int vprintf(const char* format, va_list arg);

  va_list args;
  va_start(args, format);
  vprintf(format, args);
  va_end(args);
  return nil;
}

/* The bytes of a span to standard output in one call, for print on a Span
   of Nat8, which every printed String goes through.  It goes through the
   stdio buffer that hilde_printf writes to, so the output keeps the order
   of the prints.  A call of vprintf per byte made printing a large text
   take longer than building it. */
hilde_unit_t hilde_print_bytes(uint8_t* data, size_t size) {
  if (size == 0) {
    return nil;
  }
  (void) hilde_libc_fwrite(data, 1, size, hilde_stdout());
  return nil;
}

void* hilde_array_index(hilde_span_t* array, size_t index, size_t elem_size) {
  if (index >= array->size) {
    hilde_abort_internal("Array index out of bounds.");
  }

  hilde_index_t offset = 0;
  if (__builtin_mul_overflow(index, elem_size, &offset)) {
    hilde_abort_internal("Multiplication overflow in array indexing operation.");
  }

  char* data = (char*) array->data;
  char* ptr = data + offset;
  return (void*)(ptr);
}

/*
 * Memory functions
 */

void* hilde_calloc(size_t size, size_t count) {
  extern void* calloc(size_t count, size_t size);

  return calloc(size, count);
}

void* hilde_realloc(void* ptr, size_t count) {
  extern void* realloc(void *ptr, size_t size);

  return realloc(ptr, count);
}

void* hilde_memmove(void* destination, void* source, size_t count) {
  return memmove(destination, source, count);
}

void* hilde_memcpy(void* destination, void* source, size_t count) {
  return memcpy(destination, source, count);
}

/* Overwriting memory that is about to be given back.

   memset is the wrong tool for this: once nothing reads the bytes again
   the compiler is allowed to prove the store dead and drop it, and on the
   one path where the wipe matters -- just before a free -- nothing ever
   does read them again.  There are two ways out, chosen per system by
   compiler macro, with no configure step and no HAVE_ macros.  glibc 2.25
   and newer, OpenBSD and FreeBSD have explicit_bzero, whose entire purpose
   is that it may not be removed.  Everything else writes through a
   volatile unsigned char*: an access through a volatile lvalue is an
   observable side effect, so the standard forbids the compiler to elide
   it.

   The declaration is ours rather than the header's, as this file does for
   calloc and free: everything here is compiled with -std=c17, and under a
   strict ISO source level glibc's <string.h> does not declare
   explicit_bzero at all.  On a system whose header does declare it the two
   prototypes are identical, which C allows. */
void hilde_wipe(void* ptr, size_t size) {
  if (ptr == NULL || size == 0) {
    return;
  }
/* HILDE_FORCE_FALLBACK takes the native branch out on a system that has
   it.  A fallback that is only ever compiled on the systems that lack the
   native function is a fallback nobody has run; with this switch both can
   be built and tested on one system and seen to agree.  It is a testing
   switch and nothing in the language reaches it. */
#if !defined(HILDE_FORCE_FALLBACK) && \
    (defined(__OpenBSD__) || defined(__FreeBSD__) || \
     (defined(__GLIBC__) && (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 25))))
  {
    extern void explicit_bzero(void* block, size_t length);

    explicit_bzero(ptr, size);
  }
#else
  {
    volatile unsigned char* byte = (volatile unsigned char*) ptr;
    size_t left = size;

    while (left > 0) {
      *byte = 0;
      byte++;
      left--;
    }
  }
#endif
}

hilde_unit_t hilde_free(void* ptr) {
  extern void free(void* ptr);

  free(ptr);
  return nil;
}


/*
 * Arena memory: a bump allocator behind a linear handle.  What makes it
 * safe is on the Hilde side, in Standard.Arena: the handle is linear,
 * allocation hands out a reference tied to the borrow region, and the type
 * checker refuses a use after reset or free.  What is here is only the
 * block.
 *
 * Two implementations, chosen at compile time and never at run time.  The
 * default takes a block with mmap, puts a PROT_NONE guard page after it and
 * overwrites what was used on reset and on free.  With
 * HILDE_ARENA_PASSTHROUGH defined, every allocation is a separate calloc and
 * every reset frees them one by one.  That is what OpenBSD's hardened
 * allocator wants to see, and the reason the switch exists: an arena goes
 * around the allocator's guard pages, its randomisation and its overwriting
 * of freed memory, so there has to be a way to put a program back on it.
 *
 * The capacity budget is enforced identically in both, so that a program
 * runs out of arena at the same allocation either way.
 *
 * When the block is full, allocation returns NULL and the Hilde side turns
 * that into None.  A full arena does not chain a second block.
 */

typedef struct hilde_arena_slot {
  void* pointer;
  size_t size;
} hilde_arena_slot_t;

typedef struct hilde_arena {
  unsigned char* base;          /* the mapping; NULL in pass-through mode */
  size_t capacity;              /* usable bytes, rounded up to a page */
  size_t mapped;                /* capacity + guard page, what munmap gets */
  size_t used;                  /* bytes handed out, alignment included */
  hilde_arena_slot_t* slots;    /* pass-through only: what to free */
  size_t slot_count;
  size_t slot_capacity;
} hilde_arena_t;

/* The prelude does not include <stdlib.h>.  It declares the libc functions
   it uses inside the function that uses them, as hilde_calloc and
   hilde_free above do, rather than pulling a header into every generated
   file.  A call to calloc or free without such a declaration does not
   compile: "implicit declaration of function calloc". */
static void* hilde_arena_calloc(size_t size) {
  extern void* calloc(size_t count, size_t size);

  return calloc(1, size);
}

static void hilde_arena_free(void* pointer) {
  extern void free(void* ptr);

  free(pointer);
}

static size_t hilde_arena_page_size(void) {
  long page = sysconf(_SC_PAGESIZE);

  if (page <= 0) {
    return 4096;
  }
  return (size_t) page;
}

/* The offset the next allocation starts at: used, rounded up to the
   alignment of max_align_t, which suits any C type.  Returns 0 and sets
   *ok to 0 when the rounding would wrap. */
static size_t hilde_arena_next_offset(size_t used, int* ok) {
  size_t align = _Alignof(max_align_t);
  size_t offset = (used + (align - 1)) & ~(align - 1);

  if (offset < used) {
    *ok = 0;
    return 0;
  }
  *ok = 1;
  return offset;
}

#ifndef HILDE_ARENA_PASSTHROUGH

#if defined(HILDE_ARENA_QUARANTINE)
/*
 * The quarantine, compiled in only with HILDE_ARENA_QUARANTINE defined and
 * off in the default build.
 *
 * freeArena overwrites what was used (hilde_wipe), tells the kernel the
 * pages may go (madvise, MADV_FREE), makes the block unreadable and
 * unwritable (mprotect, PROT_NONE) and puts it at the end of a quarantine
 * of fixed length.  A pointer kept past the free faults there, and the
 * addresses are not given back while the arena lies there: a new mapping
 * cannot land on them and hand a stale pointer somebody else's memory.
 * When the quarantine is full, the oldest arena is opened again (mprotect,
 * PROT_READ | PROT_WRITE) and kept for the next createArena of its size.
 * resetArena is untouched: the quick way, same pages, overwritten.
 *
 * One quarantine per thread (_Thread_local), and no lock: an arena goes
 * into the quarantine of the thread that frees it and comes back to a
 * createArena on that thread.  When tasks run on worker threads, an arena
 * made on one worker and freed on another lies in the second one's
 * quarantine.  No worker ever touches another's, so nothing is shared.
 */

/* How many freed arenas one thread keeps unreachable before the oldest is
   used again. */
#define HILDE_ARENA_QUARANTINE_LENGTH 16

static _Thread_local hilde_arena_t* hilde_arena_held[HILDE_ARENA_QUARANTINE_LENGTH];
static _Thread_local size_t hilde_arena_held_first = 0;  /* the oldest */
static _Thread_local size_t hilde_arena_held_count = 0;
/* The arena let out of the quarantine last, open again, waiting for the next
   createArena of its capacity on this thread. */
static _Thread_local hilde_arena_t* hilde_arena_ready = NULL;

/* Gives an arena back to the system for good.  Only for one that is not in
   the quarantine: the ready one, or one whose protection failed. */
static void hilde_arena_release(hilde_arena_t* arena) {
  munmap(arena->base, arena->mapped);
  hilde_arena_free(arena);
}

/* Tells the kernel the pages may go.  This is advice: a failure changes
   nothing a programme can see, since the pages are wiped already and are
   made unreachable afterwards either way, so it is not treated as an
   error. */
static void hilde_arena_advise(hilde_arena_t* arena) {
#if defined(MADV_FREE)
#if defined(__linux__)
  /* glibc hides madvise under -std=c17 as it hides MADV_FREE, so it is
     declared here, the way this file declares such functions. */
  extern int madvise(void* address, size_t length, int advice);
#endif
  (void) madvise(arena->base, arena->capacity, MADV_FREE);
#else
  /* No MADV_FREE under this platform's headers: nothing is advised, and the
     pages stay resident until the arena is used again or the process
     ends. */
  (void) arena;
#endif
}

/* The newest freed arena goes in; when the quarantine is full, the oldest
   comes out, open again, as the ready one.  An arena that cannot be made
   unreachable is released instead: a quarantine that holds a readable block
   would promise what it does not do. */
static void hilde_arena_quarantine(hilde_arena_t* arena) {
  hilde_arena_advise(arena);
  if (mprotect(arena->base, arena->capacity, PROT_NONE) != 0) {
    hilde_arena_release(arena);
    return;
  }
  if (hilde_arena_held_count < HILDE_ARENA_QUARANTINE_LENGTH) {
    hilde_arena_held[(hilde_arena_held_first + hilde_arena_held_count) %
                     HILDE_ARENA_QUARANTINE_LENGTH] = arena;
    hilde_arena_held_count++;
    return;
  }
  {
    hilde_arena_t* oldest = hilde_arena_held[hilde_arena_held_first];

    hilde_arena_held[hilde_arena_held_first] = arena;
    hilde_arena_held_first =
      (hilde_arena_held_first + 1) % HILDE_ARENA_QUARANTINE_LENGTH;
    if (mprotect(oldest->base, oldest->capacity,
                 PROT_READ | PROT_WRITE) != 0) {
      hilde_arena_release(oldest);
      return;
    }
    oldest->used = 0;
    if (hilde_arena_ready != NULL) {
      hilde_arena_release(hilde_arena_ready);
    }
    hilde_arena_ready = oldest;
  }
}

/* The ready arena, when it has exactly the capacity asked for; else NULL,
   and a ready arena of another size is released -- its addresses left the
   quarantine already, and keeping it would hold memory nobody asks for. */
static hilde_arena_t* hilde_arena_take_ready(size_t rounded) {
  hilde_arena_t* arena = hilde_arena_ready;

  if (arena == NULL) {
    return NULL;
  }
  hilde_arena_ready = NULL;
  if (arena->capacity != rounded) {
    hilde_arena_release(arena);
    return NULL;
  }
  arena->used = 0;
  return arena;
}

int32_t hilde_arena_quarantine_length(void) {
  return HILDE_ARENA_QUARANTINE_LENGTH;
}
#else
int32_t hilde_arena_quarantine_length(void) {
  return 0;
}
#endif /* HILDE_ARENA_QUARANTINE */

void* hilde_arena_create(size_t capacity) {
  size_t page;
  size_t rounded;
  size_t mapped;
  unsigned char* base;
  hilde_arena_t* arena;

  if (capacity == 0) {
    return NULL;
  }
  page = hilde_arena_page_size();
  rounded = ((capacity + (page - 1)) / page) * page;
  if (rounded < capacity) {
    return NULL;
  }
  mapped = rounded + page;
  if (mapped < rounded) {
    return NULL;
  }
#if defined(HILDE_ARENA_QUARANTINE)
  arena = hilde_arena_take_ready(rounded);
  if (arena != NULL) {
    return (void*) arena;
  }
#endif
  base = (unsigned char*) mmap(NULL, mapped, PROT_READ | PROT_WRITE,
                               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (base == MAP_FAILED) {
    return NULL;
  }
  /* The guard page: the last page of the mapping, unreadable and
     unwritable, so that a write past the end of the arena faults where it
     happens rather than corrupting something else later. */
  if (mprotect(base + rounded, page, PROT_NONE) != 0) {
    munmap(base, mapped);
    return NULL;
  }
  arena = (hilde_arena_t*) hilde_arena_calloc(sizeof(hilde_arena_t));
  if (arena == NULL) {
    munmap(base, mapped);
    return NULL;
  }
  arena->base = base;
  arena->capacity = rounded;
  arena->mapped = mapped;
  arena->used = 0;
  return (void*) arena;
}

/* Hands out size bytes of the arena, or NULL when they do not fit.  This is
   the only check that a piece lies within the arena.  Standard.Arena keeps no
   count of its own of how much is used or how much there is, and relies on
   this check alone.  The definition of this function for the pass-through
   mode, further down, must hold the same check. */
void* hilde_arena_alloc(void* handle, size_t size) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;
  int ok = 0;
  size_t offset;

  if (arena == NULL) {
    return NULL;
  }
  offset = hilde_arena_next_offset(arena->used, &ok);
  if (!ok) {
    return NULL;
  }
  /* Written as a subtraction so that it cannot overflow. */
  if (offset > arena->capacity || size > arena->capacity - offset) {
    return NULL;
  }
  arena->used = offset + size;
  return (void*) (arena->base + offset);
}

hilde_unit_t hilde_arena_reset(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;

  if (arena == NULL) {
    return nil;
  }
  /* The type system stops the next unit of work from holding a reference;
     the wipe stops it from reading the bytes.  hilde_wipe and not memset: a
     compiler may drop a memset of bytes that are not read again. */
  hilde_wipe(arena->base, arena->used);
  arena->used = 0;
  return nil;
}

hilde_unit_t hilde_arena_destroy(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;

  if (arena == NULL) {
    return nil;
  }
  hilde_wipe(arena->base, arena->used);
#if defined(HILDE_ARENA_QUARANTINE)
  hilde_arena_quarantine(arena);
  return nil;
#else
  munmap(arena->base, arena->mapped);
#endif
  arena->base = NULL;
  arena->capacity = 0;
  arena->mapped = 0;
  arena->used = 0;
  hilde_arena_free(arena);
  return nil;
}

#else /* HILDE_ARENA_PASSTHROUGH */

/* Pass-through takes precedence over the quarantine: every allocation is
   the system allocator's, so there is no block to hold back. */
int32_t hilde_arena_quarantine_length(void) {
  return 0;
}

void* hilde_arena_create(size_t capacity) {
  size_t page;
  size_t rounded;
  hilde_arena_t* arena;

  if (capacity == 0) {
    return NULL;
  }
  page = hilde_arena_page_size();
  rounded = ((capacity + (page - 1)) / page) * page;
  if (rounded < capacity) {
    return NULL;
  }
  arena = (hilde_arena_t*) hilde_arena_calloc(sizeof(hilde_arena_t));
  if (arena == NULL) {
    return NULL;
  }
  /* The same rounded capacity as the real one, so that a program runs out
     of arena at the same allocation in both modes. */
  arena->capacity = rounded;
  return (void*) arena;
}

static int hilde_arena_record(hilde_arena_t* arena, void* pointer, size_t size) {
  if (arena->slot_count == arena->slot_capacity) {
    size_t grown = (arena->slot_capacity == 0) ? 16 : (arena->slot_capacity * 2);
    hilde_arena_slot_t* slots;

    if (grown < arena->slot_capacity) {
      return 0;
    }
    slots = (hilde_arena_slot_t*) hilde_realloc(arena->slots,
                                                grown * sizeof(hilde_arena_slot_t));
    if (slots == NULL) {
      return 0;
    }
    arena->slots = slots;
    arena->slot_capacity = grown;
  }
  arena->slots[arena->slot_count].pointer = pointer;
  arena->slots[arena->slot_count].size = size;
  arena->slot_count = arena->slot_count + 1;
  return 1;
}

/* The same function for the pass-through mode: each piece is a separate
   calloc, but the piece is checked against the arena's capacity exactly as in
   the definition above, because Standard.Arena relies on this check alone.
   A change to the check in one of the two definitions is a change to the
   other. */
void* hilde_arena_alloc(void* handle, size_t size) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;
  int ok = 0;
  size_t offset;
  void* pointer;

  if (arena == NULL) {
    return NULL;
  }
  offset = hilde_arena_next_offset(arena->used, &ok);
  if (!ok) {
    return NULL;
  }
  if (offset > arena->capacity || size > arena->capacity - offset) {
    return NULL;
  }
  pointer = hilde_arena_calloc((size == 0) ? 1 : size);
  if (pointer == NULL) {
    return NULL;
  }
  if (!hilde_arena_record(arena, pointer, size)) {
    hilde_arena_free(pointer);
    return NULL;
  }
  arena->used = offset + size;
  return pointer;
}

hilde_unit_t hilde_arena_reset(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;
  size_t i;

  if (arena == NULL) {
    return nil;
  }
  for (i = 0; i < arena->slot_count; i++) {
    hilde_wipe(arena->slots[i].pointer, arena->slots[i].size);
    hilde_arena_free(arena->slots[i].pointer);
    arena->slots[i].pointer = NULL;
    arena->slots[i].size = 0;
  }
  arena->slot_count = 0;
  arena->used = 0;
  return nil;
}

hilde_unit_t hilde_arena_destroy(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;

  if (arena == NULL) {
    return nil;
  }
  hilde_arena_reset(handle);
  hilde_arena_free(arena->slots);
  arena->slots = NULL;
  arena->slot_capacity = 0;
  hilde_arena_free(arena);
  return nil;
}

#endif /* HILDE_ARENA_PASSTHROUGH */

/* Allocates count pieces of size bytes in one allocation, the array form
   that Standard.Arena.arenaSpan hands out as a span.  NULL when either is 0
   or when the product wraps: a wrapped product would be a small allocation
   behind a span that claims a large one.  Both builds, the mapping and
   pass-through, go through hilde_arena_alloc, so the budget is the same in
   both. */
void* hilde_arena_alloc_array(void* handle, size_t count, size_t size) {
  size_t total;

  if (count == 0 || size == 0) {
    return NULL;
  }
  if (__builtin_mul_overflow(count, size, &total)) {
    return NULL;
  }
  return hilde_arena_alloc(handle, total);
}

size_t hilde_arena_used(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;

  if (arena == NULL) {
    return 0;
  }
  return arena->used;
}

size_t hilde_arena_capacity(void* handle) {
  hilde_arena_t* arena = (hilde_arena_t*) handle;

  if (arena == NULL) {
    return 0;
  }
  return arena->capacity;
}

/*
 * Telling the time.
 */

/* Nanoseconds since the epoch, or 0 if the clock cannot be read.
   timespec_get is ISO C11: it needs no feature-test macro, and every
   platform the runtime is built for has it, except bionic below API level
   29, handled below.  It reads the wall clock, which can be set
   backwards, so a timeout must not use it. */
uint64_t hilde_time_wall_nanos(void) {
  struct timespec ts;

  /* bionic declares timespec_get from API level 29 on, so a library for
     an older level reads the same clock with clock_gettime, which bionic
     has at every level an app can name.  With NDK 30, timespec_get is
     undeclared at levels 24, 26 and 28 and declared at 29; clock_gettime
     is declared at 24. */
#if defined(__ANDROID__) && __ANDROID_API__ < 29
  if (clock_gettime(CLOCK_REALTIME, &ts) != 0) {
    return 0;
  }
#else
  if (timespec_get(&ts, TIME_UTC) != TIME_UTC) {
    return 0;
  }
#endif
  return ((uint64_t) ts.tv_sec * 1000000000u) + (uint64_t) ts.tv_nsec;
}

/* 1 when this build has a monotonic clock, 0 otherwise.  A caller asks
   instead of assuming one, because the answer differs between platforms;
   see hilde_time_monotonic_nanos. */
int hilde_time_has_monotonic(void) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
  return 1;
#else
  return 0;
#endif
}

/* Nanoseconds from a clock that does not go backwards, or -1 where there is
   none.

   glibc hides clock_gettime and the CLOCK_ constants under -std=c17, and
   the feature-test macro that reveals them takes MAP_ANON away from the
   arena on OpenBSD.  So the function is declared where it is used, as
   elsewhere in this file, and the clock number has to be a literal.

   CLOCK_MONOTONIC is 1 on Linux, 3 on OpenBSD (7.9, amd64, clang
   19.1.7) and 4 on FreeBSD (15.1, amd64, clang 19.1.7), as the headers
   say under _POSIX_C_SOURCE and, on FreeBSD, in sys/_clock_id.h.  With the
   literal, no macro and the declaration below, clock_gettime answers 0 and
   gives the uptime on all three, while a number the kernel does not know,
   such as 4711, answers -1.  A wrong number here fails silently:
   clock_gettime fails as given an invalid argument, the caller gets -1,
   and a timeout quietly
   becomes no timeout.  So a number for another system is read from its
   header, not written from memory.  The macOS header declares
   clock_gettime and CLOCK_MONOTONIC under -std=c17 itself, so there the
   names of the header are used.  Other systems have no monotonic clock
   here. */
int64_t hilde_time_monotonic_nanos(void) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__)
  {
    extern int clock_gettime(int clock_id, struct timespec* ts);
    struct timespec ts;
#if defined(__linux__)
    const int monotonic = 1;
#elif defined(__FreeBSD__)
    const int monotonic = 4;
#else
    const int monotonic = 3;
#endif

    if (clock_gettime(monotonic, &ts) != 0) {
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


/* 1 when the programme runs under valgrind, 0 otherwise.  Only a build
   with -DHILDE_VALGRIND, as hilde test --valgrind builds, asks valgrind;
   any other build answers 0.  A test that bounds a time uses it to allow
   for valgrind's slowdown and for nothing else. */
int32_t hilde_running_under_valgrind(void) {
#if defined(HILDE_VALGRIND)
  return (RUNNING_ON_VALGRIND) ? 1 : 0;
#else
  return 0;
#endif
}

/* A task runtime failure the programme cannot continue past: named, on
   standard error, and the process ends -- the same way hilde_abort does. */
static _Noreturn __attribute__((noreturn)) void hilde_task_die(const char* message) {
  hilde_stop_with(message);
}

/* Nanoseconds on the clock that timed waits use: the monotonic clock where
   this file knows its number, else ISO C's wall clock, which can jump when
   the system's time is set. */
static int64_t hilde_task_now(void) {
  int64_t monotonic = hilde_time_monotonic_nanos();
  struct timespec ts;

  if (monotonic >= 0) {
    return monotonic;
  }
  if (timespec_get(&ts, TIME_UTC) == 0) {
    return 0;
  }
  return ((int64_t) ts.tv_sec * 1000000000) + (int64_t) ts.tv_nsec;
}

/* The milliseconds from now until deadline for poll(2): 0 when it has
   passed, rounded up so that a wait never ends before it. */
static int hilde_task_poll_millis(int64_t deadline) {
  int64_t left = deadline - hilde_task_now();

  if (left <= 0) {
    return 0;
  }
  left = (left + 999999) / 1000000;
  return (left > 2147483647) ? 2147483647 : (int) left;
}

/* The calling thread waits nanos nanoseconds itself: where there is no
   task runtime, or before it could be set up. */
static void hilde_task_sleep_alone(int64_t nanos) {
  int64_t deadline = hilde_task_now() + nanos;

  while (hilde_task_now() < deadline) {
    (void) poll(NULL, 0, hilde_task_poll_millis(deadline));
  }
}

/* The answer of hilde_task_wait_fd for a poll(2) of one descriptor that
   returned rc with revents: 1 when it is ready for what was asked (1 read,
   2 write) or, for a read, has hung up, where a read says whether data or
   the end is left; 0 for an error, a descriptor that is not open, or a
   failed poll.  The runtime's own wait answers the same. */
static int hilde_task_poll_answer(int rc, short revents, int what) {
  short want = (what == 2) ? POLLOUT : POLLIN;

  if (rc <= 0) {
    return 0;
  }
  if ((revents & want) != 0) {
    return 1;
  }
  if (what != 2 && (revents & POLLHUP) != 0) {
    return 1;
  }
  return 0;
}

/* Whether block, length bytes long, holds exactly strings texts one after
   the other, each ending in a zero byte, and nothing after the last: the
   form in which Hilde hands a list of texts to C.  The Hilde side checks
   the same before the call; this check keeps a wrong count from walking
   past the end of the block whoever made the call. */
static __attribute__((unused)) int hilde_packed_holds(const uint8_t* block, size_t length, size_t strings) {
  size_t zeros = 0;
  size_t i;

  if (block == NULL || length == 0 || block[length - 1] != 0) {
    return 0;
  }
  for (i = 0; i < length; i++) {
    if (block[i] == 0) {
      zeros++;
    }
  }
  return zeros == strings;
}

/* Close-on-exec, set with fcntl after the open rather than in its flags.

   A descriptor that survives an execve is inherited by every child.  The
   one flag that closes that window entirely, O_CLOEXEC, is hidden by
   glibc's <fcntl.h> under -std=c17, the standard every generated file is
   compiled with, and the only way to reveal it is to define
   _POSIX_C_SOURCE before every include in this file.  On OpenBSD that same
   define turns off __BSD_VISIBLE and would take MAP_ANON away from the
   arena above.

   With gcc 14.2.0 and cc -std=c17 -Wall -Wextra, O_CLOEXEC in the open
   flags is an error (O_CLOEXEC undeclared); fcntl(fd, F_SETFD, FD_CLOEXEC)
   compiles clean; and _POSIX_C_SOURCE plus O_CLOEXEC compiles clean as
   well.  So the reason for not taking that route is OpenBSD, not this
   compiler.

   The price: between the open and the fcntl there is a window in which
   an exec on another thread would inherit the descriptor.  Tasks do run
   on several threads, but the only exec this file makes is the one in
   hilde_process_spawn, and its child closes every descriptor above 2
   before it, whatever flags it carries (closefrom, or one by one on
   Android), so a descriptor caught in the window does not reach that
   child.  The case this does not cover is an exec by C code outside this
   file on another thread, such as the host of a library: its child can
   inherit a descriptor opened here in that moment.

   A descriptor that could not be marked is closed and reported as a
   failure, so that the caller never holds a descriptor without the flag. */
static int hilde_file_mark_close_on_exec(int fd) {
  if (fd < 0) {
    return fd;
  }
  if (fcntl(fd, F_SETFD, FD_CLOEXEC) != 0) {
    close(fd);
    return -1;
  }
  return fd;
}

/*
 * A pipe.
 *
 * A poller can only be tested with something that can be registered with
 * it: epoll refuses a regular file as not permitted, and a pipe is the smallest
 * thing in POSIX that is pollable, needs no network, and can be made ready
 * on purpose by writing one byte into it.
 */

/* Two descriptors into ends, read end first.  1 on success, 0 on failure.
   Close-on-exec is set with fcntl on both: pipe2(2) would do it in one
   call, but like O_CLOEXEC it is not reachable under -std=c17. */
int hilde_pipe_open(int* ends) {
#if defined(__wasi__)
  (void) ends;
  return 0;
#else
  int fds[2];

  if (pipe(fds) != 0) {
    return 0;
  }
  if (hilde_file_mark_close_on_exec(fds[0]) < 0) {
    close(fds[1]);
    return 0;
  }
  if (hilde_file_mark_close_on_exec(fds[1]) < 0) {
    close(fds[0]);
    return 0;
  }
  ends[0] = fds[0];
  ends[1] = fds[1];
  return 1;
#endif
}

/*
 * CLI functions
 */

static int _hilde_argc = -1;

static char** _hilde_argv = NULL;

void hilde_store_cli_args(int argc, char** argv) {
  if (argc < 0) {
    hilde_abort_internal("Entrypoint error: argc is negative.");
  }
  if (argv == NULL) {
    hilde_abort_internal("Entrypoint error: argv is NULL.");
  }
  _hilde_argc = argc;
  _hilde_argv = argv;
  /* A write to a pipe or socket whose reader has gone is an error of that
     write (EPIPE), not the end of the programme.  A programme's own main
     ignores SIGPIPE here; a library comes here from hilde_start and leaves
     its host's signals alone.  A child gets the default back before its
     exec, in hilde_process_spawn. */
#ifdef SIGPIPE
  if (!HILDE_IN_LIBRARY) {
    signal(SIGPIPE, SIG_IGN);
  }
#endif
}

size_t hilde_get_argc(void) {
  if (_hilde_argc == -1) {
    hilde_abort_internal("Prelude error: argc was not set.");
  }
  // _hilde_argc is a non-negative int here, so it fits in a size_t.
  size_t argc = (size_t)(_hilde_argc);
  return argc;
}

/* The length of one argument.  The system ends every argument with a NUL
   byte and bounds all of them together (ARG_MAX), so the count needs no
   limit of its own: an argument of any length the system passed is read
   whole, and a long one is the programme's input, never a reason to
   stop. */
static size_t hilde_argument_length(const char* string) {
  size_t size = 0;
  while (string[size] != '\0') {
    size++;
  }
  return size;
}

hilde_span_t hilde_get_nth_arg(size_t n) {
  if (_hilde_argv == NULL) {
    hilde_abort_internal("Prelude error: argv was not set.");
  }
  size_t argc = hilde_get_argc();
  if (n >= argc) {
    hilde_abort_internal("Command line argument access out of bounds.");
  }
  char* arg = _hilde_argv[n];
  if (arg == NULL) {
    hilde_abort_internal("Prelude error: command-line argument is NULL.");
  }
  size_t size = hilde_argument_length(arg);
  hilde_span_t arg_array = ((hilde_span_t){ .data = (void*)arg, .size = size });
  return arg_array;
}
