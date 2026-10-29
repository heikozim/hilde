/*
    Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

    Hilde is derived from the Austral project and extends it substantially.
    Modified by Heiko Zimmermann, 2026.
*/
/* Runtime prelude of the Hilde compiler, derived from the Austral prelude. */
/* The epoll and kqueue backends of the poller follow src/h2_poller.c of
   the Hiawatha web server, and the sandbox, with the system calls its
   seccomp filter refuses and its handling of Landlock rights and paths,
   follows src/sandbox.c of the same server. */
/* wasm32-wasi: WASI has no true mmap, no signals and no clocks of the
   process, no process ids; its C library emulates the four when asked
   before the first header, and the link takes the four emulation
   libraries.  What WASI
   has not at all (sockets, limits, the terminal) answers its failure
   further down, in each function under __wasi__. */
#if defined(__wasi__)
#define _WASI_EMULATED_MMAN
#define _WASI_EMULATED_SIGNAL
#define _WASI_EMULATED_PROCESS_CLOCKS
#define _WASI_EMULATED_GETPID
#endif
#include <stdint.h>
/* The start of the count of Bindings.Serial, which gives every graph of
   Standard.Graph its number: 0, unless the build defines
   HILDE_SERIAL_NEAR_WRAP, which starts it two below the largest value, so
   that the third number drawn wraps round to 0 and a test can see makeGraph
   stop there (such a test defines it in its cflags.txt).  The
   ordinary build draws 1, 2, 3. */
#if defined(HILDE_SERIAL_NEAR_WRAP)
#define HILDE_SERIAL_START (UINT64_MAX - 2u)
#else
#define HILDE_SERIAL_START 0u
#endif
#include <stddef.h>
#include <stdarg.h>
/* string.h, so that memmove and memcpy are declared the way the standard
   declares them.  A declaration of one's own with a void* source, where the
   standard has const void*, is a different function to the compiler: gcc
   reports "mismatch in argument 2 type of built-in function", clang
   "incompatible redeclaration of library function", in every generated
   file. */
#include <string.h>
/* unistd.h, for write(2), which the abort message goes through.  fprintf
   would need <stdio.h>: declared by this file itself, clang warns in every
   generated file that a declaration of the built-in fprintf requires the
   header.  And <stdio.h> cannot be included here: a pragma Foreign_Import
   of a libc function makes the code generator emit its own declaration of
   it, and next to the header's prototype that is a conflicting-types
   error, not a warning (so with gcc 14.2.0 and clang 19.1.7 for fputc,
   which is why the terminal module reaches it through hilde_fputc below).
   write(2) needs no declaration of ours and no header of theirs.  The
   price: the prelude depends on POSIX for this call, not only on ISO C. */
#include <unistd.h>
/* sys/mman.h, for the memory arena: mmap, mprotect, munmap and the PROT_
   and MAP_ constants, which are platform-dependent numbers and cannot be
   written down in Hilde.  The header's prototypes clash with nothing as
   long as no module imports mmap or its siblings through pragma
   Foreign_Import, which would make the code generator emit a second,
   conflicting declaration; that is the reason <stdio.h> cannot be
   included. */
#include <sys/mman.h>
/* linux/mman.h for MAP_ANONYMOUS where <sys/mman.h> does not show it
   under -std=c17: glibc 2.36 (Debian 12) hides it without a feature macro,
   glibc 2.41 and bionic show it.  The kernel's header defines the same
   value; it is read from there and not written down, like MADV_FREE
   below. */
#if defined(__linux__) && !defined(MAP_ANONYMOUS)
#include <linux/mman.h>
#endif
/* linux/mman.h, for MADV_FREE, and only when the arena quarantine is
   compiled in.  glibc's <sys/mman.h> hides MADV_FREE, MADV_DONTNEED and
   POSIX_MADV_DONTNEED under -std=c17, with gcc and clang alike; the
   kernel's header defines it, 8, without a warning under -std=c17
   -Wpedantic.  OpenBSD's <sys/mman.h> shows it (6) under the same
   flags. */
#if defined(HILDE_ARENA_QUARANTINE) && defined(__linux__)
#include <linux/mman.h>
#endif
/* fcntl.h, for open(2) and the O_ constants.  The constants are the reason
   and not the function: O_WRONLY, O_CREAT, O_TRUNC and O_CLOEXEC are
   platform-dependent numbers -- O_CREAT is 0100 on Linux and 0x0200 on the
   BSDs -- and a number written down here would be wrong on some other
   platform.  As with <sys/mman.h> above, including it is safe only while
   no module imports open, close, read, write or unlink through pragma
   Foreign_Import, which would make the code generator emit a second,
   conflicting declaration. */
#include <fcntl.h>
/* errno.h, for EINTR.  Another platform-dependent number, and the one that
   decides whether a call that came back early is an error or a retry. */
#include <errno.h>
/* sys/epoll.h on Linux and sys/event.h on OpenBSD, FreeBSD and macOS, for
   the poller.  The structs and the constants cannot be written down by
   hand: struct epoll_event is packed on x86-64 and not on other
   architectures, and the fields of struct kevent differ in type between
   the three kqueue systems; getting either wrong is not a compile error but
   a wrong answer at run time.  On any other platform this file has no
   poller backend and says so: see hilde_poller_backend below and
   Standard.Poller.backendAvailable. */
#if defined(__linux__)
#include <sys/epoll.h>
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#endif
/* sys/stat.h, for the type of the file a name refers to: the S_IS* macros
   read a mode word whose bit layout is the platform's, and struct stat
   cannot be written down by hand at all.  Under cc -std=c17 -Wall -Wextra
   the header's struct and its macros are visible, and lstat and readlink
   are not; those two are declared where they are used, as this file does
   for calloc, free and prctl. */
#include <sys/stat.h>
/* time.h, for struct timespec and timespec_get.  Both are ISO C11 and need
   no feature-test macro under cc -std=c17 -Wall -Wextra.  What glibc does
   not show that way is clock_gettime and the CLOCK_ constants; see
   hilde_time_monotonic_nanos below.  That is why the wall time can be told
   on every platform, and the elapsed time only on the platforms whose
   value of the constant this file writes down. */
#include <time.h>
/* Under __wasi__ the four headers the C library of WASI has not are left
   out: sys/wait.h, syslog.h, pwd.h and termios.h.  What they declare is
   used only where WASI answers its failure without it. */
/* sys/wait.h and dirent.h, for a child process and for reading a
   directory.  On glibc 2.41, with gcc 14.2.0 and clang 19.1.7 under
   cc -std=c17 -Wall -Wextra: fork, execve, dup2, waitpid, the W* macros,
   opendir, readdir, closedir, struct dirent with its d_name, lseek and the
   SEEK_ constants are all visible and compile without a warning.  Not
   visible: closefrom and environ ("implicit declaration", "undeclared");
   those two are declared where they are used, as elsewhere in this file,
   and the pair links and runs against glibc 2.41.  OpenBSD 7.9 with
   clang 19.1.7 compiles this file under the same flags without a
   warning. */
#if !defined(__wasi__)
#include <sys/wait.h>
#endif
#include <dirent.h>
/* signal.h, for SIGTERM, which is ISO C: the number comes from the header
   and is not written down here. */
#include <signal.h>
/* poll.h, for the task scheduler: a task that waits for a descriptor is
   parked, and when no task can run the scheduler waits in poll(2) for any
   of them.  poll and not the poller, because poll is POSIX and the same
   call on every platform, where the poller has another backend on each:
   epoll on Linux, kqueue on the BSDs and macOS.  Under cc -std=c17 -Wall
   -Wextra, also with -Wpedantic, gcc and clang show poll, struct pollfd
   and its constants without a warning. */
#include <poll.h>
/* sys/socket.h and sys/un.h, for Unix domain sockets: struct sockaddr_un,
   whose path field has a platform size -- 108 bytes on Linux, the BSDs'
   from their own header -- and AF_UNIX, SOCK_STREAM.  Under cc -std=c17
   -Wall -Wextra, gcc and clang show the calls, the struct and the
   constants without a warning. */
#include <sys/socket.h>
#include <sys/un.h>
/* netinet/in.h, for TCP connections: struct sockaddr_in and struct
   sockaddr_in6, htons.  Under cc -std=c17 -Wall -Wextra -Wpedantic with no
   feature macro, glibc with gcc 14.2.0 shows the two structs, htons,
   in6addr_loopback, fcntl with O_NONBLOCK, poll, getsockopt with SO_ERROR
   and EINPROGRESS, but not clock_gettime; OpenBSD with clang 19.1.7 shows
   all of these and clock_gettime too, without a warning. */
#include <netinet/in.h>
/* pthread.h, for the task runtime on several threads: the workers, and the
   locks and condition variables of the scheduler, the channels and the
   scopes.  POSIX, and the same calls on Linux and the BSDs.  It brings a
   library with it on OpenBSD: a programme calling pthread_create does not
   link there without -pthread ("undefined symbol: pthread_create"), so
   every programme's link manifest names pthread; see prelude_libraries in
   lib/Compiler.ml. */
#include <pthread.h>
/* syslog.h, for the system log: openlog, syslog, closelog and the LOG_
   constants, whose values differ between the systems and are therefore
   taken from the header, never written down.  Under cc -std=c17 -Wall
   -Wextra -Wpedantic with no feature macro, OpenBSD with clang 19.1.7
   declares all of them and fchmod and dup2 as well; glibc with gcc 14.2.0
   declares them and dup2 but not fchmod, so the three functions that call
   fchmod declare it themselves, as lstat is declared below. */
#if !defined(__wasi__)
#include <syslog.h>
#endif
/* pwd.h, for struct passwd, which the lookup of an account fills.  POSIX;
   getpwnam_r itself is declared where it is called, since glibc hides it
   under -std=c17 with no feature macro. */
#if !defined(__wasi__)
#include <pwd.h>
#endif
/* sys/resource.h, for resource limits and usage: getrlimit, setrlimit,
   getrusage, struct rlimit, struct rusage and the RLIMIT_ and RUSAGE_
   constants, whose values differ between the systems and are therefore
   taken from the header.  All of it is visible under cc -std=c17 -Wall
   -Wextra -Wpedantic with no feature macro, on OpenBSD with clang 19.1.7
   and on glibc with gcc 14.2.0; on glibc clock_gettime and the CLOCK_
   constants are not, see hilde_time_boot_nanos. */
#include <sys/resource.h>
/* termios.h and sys/ioctl.h, for the terminal: tcgetattr, tcsetattr,
   tcflush, isatty, ioctl, struct termios, struct winsize, and ECHO,
   ECHONL, TCSAFLUSH, TCIFLUSH and TIOCGWINSZ, whose values differ between
   the systems (TIOCGWINSZ is 21523 on Linux and 1074295912 on OpenBSD,
   TCIFLUSH 0 and 1) and are therefore taken from the headers.  All of it
   is visible under cc -std=c17 -Wall -Wextra -Wpedantic with no feature
   macro, on glibc with gcc 14.2.0 and on OpenBSD with clang 19.1.7. */
#if !defined(__wasi__)
#include <termios.h>
#endif
#include <sys/ioctl.h>
/* sys/inotify.h on Linux and sys/event.h on OpenBSD, for watching files:
   inotify_init1, inotify_add_watch, struct inotify_event and the IN_
   constants; kqueue, kevent, EV_SET, struct kevent and the NOTE_
   constants.  Under cc -std=c17 -Wall -Wextra -Wpedantic with no feature
   macro, all of the kqueue part is visible on OpenBSD with clang 19.1.7,
   all of the inotify part on glibc with gcc 14.2.0. */
#if defined(__linux__)
#include <sys/inotify.h>
#elif defined(__OpenBSD__)
#include <sys/event.h>
#endif
/* TargetConditionals.h, limits.h, mach/mach.h and mach-o/dyld.h on
   macOS, for the sandbox: TARGET_OS_OSX tells macOS from Apple's other
   systems, PATH_MAX bounds a path, task_threads counts the threads of this
   process, and _NSGetExecutablePath names the binary that is started
   again under the Seatbelt profile.  None of them brings <stdio.h> with
   it; with Apple clang 17 under cc -std=c17 -Wall -Wextra, EOF stays
   undefined after all four. */
#if defined(__FreeBSD__)
#include <sys/capsicum.h>
/* The Capsicum sandbox, defined here, above every function that asks for
   it. */
#define HILDE_SANDBOX_CAPSICUM 1
#endif
#if defined(__APPLE__)
#include <TargetConditionals.h>
#include <limits.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#endif
/* The Seatbelt sandbox, on macOS proper and not on Apple's other systems;
   defined here, above every function that asks for it. */
#if defined(__APPLE__) && defined(__MACH__) && TARGET_OS_OSX
#define HILDE_SANDBOX_SEATBELT 1
#endif

/* The checked arithmetic of Pervasive rests on three GNU builtins:
   __builtin_add_overflow, __builtin_sub_overflow and
   __builtin_mul_overflow, used in lib/builtin/Pervasive.hiq; the third is
   used twice below as well.  They are used rather than a portable checked
   arithmetic written by hand for twelve types times three operations,
   because every supported platform compiles with gcc or clang and both
   have had them for a decade.
   This guard makes a compiler that lacks them say so here, by name;
   without it the error comes at whichever call site the compiler reaches
   first, as an implicit declaration or a link failure that names Pervasive
   and not the requirement.  A compiler that has neither __GNUC__ nor
   __clang__ is not one of the two, so it is refused.  __has_builtin is
   itself an extension and older gcc does not have it, which is why its
   absence is not treated as an answer. */
#if defined(__GNUC__) || defined(__clang__)
#  if defined(__has_builtin)
#    if !__has_builtin(__builtin_add_overflow) || \
        !__has_builtin(__builtin_sub_overflow) || \
        !__has_builtin(__builtin_mul_overflow)
#      error "Hilde needs __builtin_add_overflow, __builtin_sub_overflow and __builtin_mul_overflow; this compiler defines __GNUC__ or __clang__ but lacks one of them."
#    endif
#  endif
#else
#  error "Hilde needs a C compiler with __builtin_add_overflow, __builtin_sub_overflow and __builtin_mul_overflow, that is gcc or clang."
#endif

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
 * Pervasive
 */

typedef struct {
  void* data;
  size_t size;
} hilde_span_t;

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
   programme names through pragma Foreign_Header declares them with the type
   FILE*, which this file has not got, and glibc's <stdio.h> follows the
   declarations with #define stdout stdout: a renaming of stdout around the
   header does not survive that line, and under -O1 with gcc 14.2.0 the
   header's own inline functions then name an undeclared stdout.  An asm
   label gives the symbol a C name no header declares, so there is nothing
   left to rename.  At file scope, where the list of names the compiler
   renames (prelude_declared_names in lib/Compiler.ml) does not look. */
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
     stream object. Its address is the FILE*; reading it, the way the
     __APPLE__ branch reads its pointer variable, would hand out the first
     word of the object instead. */
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
   as a built-in of type int(int, FILE*), and in a programme that names a
   header which brings <stdio.h> -- <openssl/evp.h> does, on OpenSSL and
   LibreSSL -- it compares the module's declaration, which says uint8_t*
   for the stream, with that type and warns with
   -Wbuiltin-declaration-mismatch (gcc 14.2.0; clang says nothing).
   Declared here, above every header, the two calls meet no FILE.  The
   signatures are what the code generator declares for them -- int32_t and
   uint8_t*, no const -- so that a difference is a compile error. */
/* Where <stdio.h> is visible here after all, EOF is defined, and the four
   calls below use its prototypes instead of declaring their own: next to
   the header's, a declaration with void* for FILE* is a conflicting-types
   error.  bionic's <syslog.h> includes <stdio.h>; of this file's headers
   it is the only one that does there, and on glibc and OpenBSD none
   does. */
#if defined(EOF)
#define HILDE_STDIO_VISIBLE 1
#else
#define HILDE_STDIO_VISIBLE 0
#endif

int32_t hilde_fputc(int32_t character, uint8_t* stream) {
#if HILDE_STDIO_VISIBLE
  return fputc(character, (FILE*) stream);
#else
  extern int fputc(int character, void* stream);

  return fputc(character, stream);
#endif
}

int32_t hilde_fgetc(uint8_t* stream) {
#if HILDE_STDIO_VISIBLE
  return fgetc((FILE*) stream);
#else
  extern int fgetc(void* stream);

  return fgetc(stream);
#endif
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
   the output before the reason in a terminal.  fflush is declared here,
   with void* for FILE*, because <stdio.h> cannot be included (see the top
   of this file) -- the same form as hilde_fputc and hilde_fgetc above.
   Not called in the child after fork (the _exit of hilde_process_spawn):
   the child holds a copy of the parent's buffer, and flushing it there
   would print it twice. */
static void hilde_flush_output(void) {
#if !HILDE_STDIO_VISIBLE
  extern int fflush(void* stream);

#endif
  (void) fflush(NULL);
}

/* A library.  The C of a library defines HILDE_LIBRARY before this file,
   and HILDE_IN_LIBRARY is 1 there and 0 in a programme, so that the
   runtime can ask it in an if as well as in an #if. */
#if defined(HILDE_LIBRARY)
#define HILDE_IN_LIBRARY 1
#else
#define HILDE_IN_LIBRARY 0
#endif

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

/* a and b joined into out, cut to its size, always ending in a zero byte;
   for a message made of two parts. */
static void hilde_stop_join(char* out, size_t size, const char* a, const char* b) {
  size_t used = 0;
  const char* parts[2] = { a, b };
  int i;

  for (i = 0; i < 2; i++) {
    const char* p = parts[i];

    while (*p != '\0' && used + 1 < size) {
      out[used++] = *p++;
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
  hilde_stop_join(head, sizeof head, (const char*) message.data, (const char*) site.data);
  hilde_stop_join(joined, sizeof joined, head, tail);
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

  hilde_stop_join(message, sizeof message,
                  "Hilde: control reached the end of a function with no return: ", where);
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

/*
 * The runtime of a library
 *
 * hilde_start and hilde_end bracket the calls of a library's exported
 * functions, and every wrapper checks at its entrance that it lies between
 * them and that no other exported function runs: a call outside is a stop
 * with a message, never undefined behaviour.  One call at a time, because
 * the runtime keeps process-wide state and its concurrent use from threads
 * of the host has not been tested.  In a programme the checks do nothing.
 */

/* 0 before hilde_start, 1 between it and hilde_end, 2 after. */
static int hilde_library_state;

/* 1 while an exported function runs. */
static int hilde_library_busy;

/* The bytes of a span handed in as NULL with the length 0. */
static uint8_t hilde_library_no_bytes[1];

void hilde_store_cli_args(int argc, char** argv);

/* A stop for a wrong call of the named function: "Hilde: " and the name,
   then what was wrong. */
static _Noreturn __attribute__((noreturn)) void hilde_library_refuse(const char* name, const char* what) {
  char message[512];
  char head[256];

  hilde_stop_join(head, sizeof head, "Hilde: ", name);
  hilde_stop_join(message, sizeof message, head, what);
  hilde_stop_with(message);
}

/* The entrance of every wrapper, with its export name. */
void hilde_library_enter(const char* name) {
  int state;

  if (!HILDE_IN_LIBRARY) {
    return;
  }
  state = __atomic_load_n(&hilde_library_state, __ATOMIC_SEQ_CST);
  if (state == 0) {
    hilde_library_refuse(name, " was called before hilde_start");
  }
  if (state == 2) {
    hilde_library_refuse(name, " was called after hilde_end");
  }
  if (__atomic_exchange_n(&hilde_library_busy, 1, __ATOMIC_SEQ_CST) != 0) {
    hilde_library_refuse(name, " was called while another exported function ran");
  }
}

/* The exit of every wrapper. */
void hilde_library_leave(void) {
  if (HILDE_IN_LIBRARY) {
    __atomic_store_n(&hilde_library_busy, 0, __ATOMIC_SEQ_CST);
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

  if (__atomic_load_n(&hilde_library_busy, __ATOMIC_SEQ_CST) != 0) {
    hilde_library_refuse("hilde_end", " was called while an exported function ran");
  }
  if (!__atomic_compare_exchange_n(&hilde_library_state, &expected, 2, 0,
                                   __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)) {
    hilde_library_refuse("hilde_end", expected == 0 ? " was called before hilde_start"
                                                    : " was called twice");
  }
  hilde_flush_output();
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

/* The working memory of libargon2, which Bindings.Argon2 hands it through
   allocate_cbk and free_cbk: two blocks are kept and handed out again, so
   that a hash does not fault in 64 MiB of new pages each time.  A block is
   taken with an atomic exchange of its busy flag, and only its taker
   changes it.  libargon2 wipes the memory before it gives it back.  When
   both are busy, or a size differs, the memory is the C library's. */
#define HILDE_ARGON2_KEPT 2
static uint8_t* hilde_argon2_block[HILDE_ARGON2_KEPT];
static size_t hilde_argon2_size[HILDE_ARGON2_KEPT];
static int hilde_argon2_busy[HILDE_ARGON2_KEPT];

int hilde_argon2_allocate(uint8_t** memory, size_t bytes) {
  extern void* malloc(size_t size);
  extern void free(void* ptr);
  int i;

  for (i = 0; i < HILDE_ARGON2_KEPT; i++) {
    int idle = 0;
    if (__atomic_compare_exchange_n(&hilde_argon2_busy[i], &idle, 1, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
      if (hilde_argon2_block[i] == NULL || hilde_argon2_size[i] != bytes) {
        free(hilde_argon2_block[i]);
        hilde_argon2_block[i] = (uint8_t*) malloc(bytes);
        hilde_argon2_size[i] = (hilde_argon2_block[i] == NULL) ? 0 : bytes;
      }
      if (hilde_argon2_block[i] != NULL) {
        *memory = hilde_argon2_block[i];
        return 0;
      }
      __atomic_store_n(&hilde_argon2_busy[i], 0, __ATOMIC_RELEASE);
    }
  }
  *memory = (uint8_t*) malloc(bytes);
  return (*memory == NULL) ? -1 : 0;
}

void hilde_argon2_free(uint8_t* memory, size_t bytes) {
  extern void free(void* ptr);
  int i;

  (void) bytes;
  for (i = 0; i < HILDE_ARGON2_KEPT; i++) {
    if (memory == hilde_argon2_block[i] && __atomic_load_n(&hilde_argon2_busy[i], __ATOMIC_ACQUIRE) == 1) {
      __atomic_store_n(&hilde_argon2_busy[i], 0, __ATOMIC_RELEASE);
      return;
    }
  }
  free(memory);
}


/* Checks a password against a bcrypt hash.  A bcrypt hash is only ever
   checked here, never made: an old hash is checked through the system's
   own library, so that a programme can store the password again with
   Argon2id.  That library is crypt_checkpass of OpenBSD's libc, and
   crypt_rn of libxcrypt on Linux, which Bindings.Bcrypt links there and
   nowhere else, and crypt_r of libcrypt on FreeBSD.  The C library of
   macOS has only the old form of crypt with a two-letter salt and neither
   function, so there
   every check answers -1.

   Static, and unused in a programme that does not call it: then it is not
   emitted and references neither function, so a programme without
   Bindings.Bcrypt does not need libxcrypt.  This holds with gcc 14 and
   clang 19; the attribute keeps clang from warning about the unused
   function.

   Both texts come as spans without a terminating zero, and a copy with one
   is made for C.  A password holding a zero byte does not match: C would
   read it only up to that byte.  Returns 1 when the password matches, 0
   when it does not, and -1 when it cannot be checked: no library, no
   memory, a hash the library does not take. */
static inline __attribute__((unused))
hilde_int32_t hilde_bcrypt_check(hilde_span_t password, hilde_span_t hash) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);

  if (password.size > 0 && memchr(password.data, 0, password.size) != NULL) {
    return 0;
  }
  if (hash.size == 0 || memchr(hash.data, 0, hash.size) != NULL) {
    return -1;
  }
  char* pw = calloc(password.size + 1, 1);
  char* stored = calloc(hash.size + 1, 1);
  if (pw == NULL || stored == NULL) {
    free(pw);
    free(stored);
    return -1;
  }
  if (password.size > 0) {
    memcpy(pw, password.data, password.size);
  }
  memcpy(stored, hash.data, hash.size);
  hilde_int32_t result = -1;
#if defined(__OpenBSD__)
  {
    extern int crypt_checkpass(const char* password, const char* hash);

    /* -1 with EACCES is a password that does not match; -1 with any other
       errno is a hash the library cannot check. */
    if (crypt_checkpass(pw, stored) == 0) {
      result = 1;
    } else if (errno == EACCES) {
      result = 0;
    }
  }
#elif defined(__linux__)
  {
    extern char* crypt_rn(const char* phrase, const char* setting, void* data, int size);
    /* sizeof (struct crypt_data) in libxcrypt 4.4.38.  A later libxcrypt
       that wants more answers NULL, which is -1 here and not a wrong
       answer. */
    const int data_size = 32768;
    void* data = calloc(1, (size_t) data_size);

    if (data != NULL) {
      const char* made = crypt_rn(pw, stored, data, data_size);

      if (made != NULL) {
        size_t made_size = strlen(made);
        size_t common = made_size < hash.size ? made_size : hash.size;
        unsigned char differ = (made_size == hash.size) ? 0 : 1;

        for (size_t i = 0; i < common; i++) {
          differ |= (unsigned char) (made[i] ^ stored[i]);
        }
        result = (differ == 0) ? 1 : 0;
      }
      hilde_wipe(data, (size_t) data_size);
      free(data);
    }
  }
#elif defined(__FreeBSD__)
  {
    /* FreeBSD's libcrypt (linked with -lcrypt) hashes the phrase under the
       stored hash as its setting and answers the hash that comes out;
       unistd.h declares crypt_r and its struct crypt_data.  An answer of
       NULL is -1 and not a wrong answer. */
    struct crypt_data data;
    const char* made;

    memset(&data, 0, sizeof data);
    made = crypt_r(pw, stored, &data);
    if (made != NULL) {
      size_t made_size = strlen(made);
      size_t common = made_size < hash.size ? made_size : hash.size;
      unsigned char differ = (made_size == hash.size) ? 0 : 1;

      for (size_t i = 0; i < common; i++) {
        differ |= (unsigned char) (made[i] ^ stored[i]);
      }
      result = (differ == 0) ? 1 : 0;
    }
    hilde_wipe(&data, sizeof data);
  }
#endif
  hilde_wipe(pw, password.size + 1);
  free(pw);
  free(stored);
  return result;
}

/* Name resolution through getaddrinfo of the C library, asked for every
   address of a name, of both families, for a stream socket so that each
   address comes once and not once per socket type.

   Under -std=c17 glibc's <netdb.h> declares neither getaddrinfo nor struct
   addrinfo: gcc 14.2.0 reports the size of hints as unknown and
   getaddrinfo as implicitly declared.  A feature macro before every include
   would change what the rest of this file sees (see O_CLOEXEC below).  So
   the struct is declared here under a name of its own, with the layout
   both systems' headers give it: 48 bytes, the same eight offsets on Linux
   arm64 and OpenBSD amd64.  The two functions are reached through asm
   labels, as the stream variables are above.
   scripts/resolver/check-header.sh checks the layout, the offsets of the
   two socket addresses and the four EAI_ values used below against the
   real headers on all four systems.  FreeBSD and macOS have the BSD order
   of the fields, ai_canonname before ai_addr, and the BSD numbers for the
   EAI_ values.  Other systems get -3: their layout is not checked. */
/* Run fn(arg), a call that may block for long, so that the calling task's
   worker runs other tasks meanwhile; see the task runtime below.  Declared
   for every platform: the calls of the poller and of the watcher below
   stand outside the platform switches. */
static void hilde_task_blocking(void (*fn)(void*), void* arg);

/* The name a C function has in the assembler, for an asm label or a call
   from asm: Mach-O puts an underscore before every C name, the object
   files of Linux and the BSDs do not. */
#if defined(__APPLE__)
#define HILDE_ASM_NAME(name) "_" name
#else
#define HILDE_ASM_NAME(name) name
#endif

#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
typedef struct hilde_addrinfo {
  int ai_flags;
  int ai_family;
  int ai_socktype;
  int ai_protocol;
  uint32_t ai_addrlen;
#if defined(__FreeBSD__) || defined(__APPLE__)
  char* ai_canonname;
  void* ai_addr;
#else
  void* ai_addr;
  char* ai_canonname;
#endif
  struct hilde_addrinfo* ai_next;
} hilde_addrinfo_t;

/* The four EAI_ values hilde_resolve sorts the answers by, written down
   because the header is not included. */
#if defined(__FreeBSD__) || defined(__APPLE__)
#define HILDE_EAI_NONAME 8
#define HILDE_EAI_AGAIN 2
#define HILDE_EAI_FAIL 4
#define HILDE_EAI_NODATA 7
#else
#define HILDE_EAI_NONAME (-2)
#define HILDE_EAI_AGAIN (-3)
#define HILDE_EAI_FAIL (-4)
#define HILDE_EAI_NODATA (-5)
#endif

extern int hilde_libc_getaddrinfo(const char* node, const char* service,
                                  const hilde_addrinfo_t* hints,
                                  hilde_addrinfo_t** result) __asm__(HILDE_ASM_NAME("getaddrinfo"));
extern void hilde_libc_freeaddrinfo(hilde_addrinfo_t* list) __asm__(HILDE_ASM_NAME("freeaddrinfo"));
#endif

/* The addresses of name, written to out as records of 17 bytes each: the
   length of the address, 4 or 16, then the address in network byte order,
   padded with zeros to 16.  An IPv6 address that maps an IPv4 one
   (::ffff:a.b.c.d) is written as that IPv4 address.  The count records
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
  static const unsigned char mapped[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff };
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
      if (memcmp(socket_address + 8, mapped, sizeof mapped) == 0) {
        at[0] = 4;
        memcpy(at + 1, socket_address + 20, 4);
      } else {
        at[0] = 16;
        memcpy(at + 1, socket_address + 8, 16);
      }
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
 * Confining the running process, cut down to what a library can decide.
 * OpenBSD unveils each path, locks the view and pledges, in that order.
 * Linux sets no new privileges, applies a Landlock ruleset built from the
 * same paths, and installs a seccomp filter that refuses up to 23 system
 * calls; eight of them only where the kernel headers define their number.
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
      const char* at = (const char*) grants;
      int32_t first = -1;
      int32_t k;

      close(fds[0]);
      for (k = 0; k < count; k++) {
        const char* permissions = at + strlen(at) + 1;

        if ((unveil(at, permissions) == -1) && (errno == E2BIG)) {
          first = k;
          break;
        }
        at = permissions + strlen(permissions) + 1;
      }
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

#if defined(HILDE_SANDBOX_SEATBELT) || defined(HILDE_SANDBOX_CAPSICUM)
/* Whether the promises, words separated by one space, hold the word. */
static int hilde_sandbox_promised(const char* promises, const char* word) {
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
#endif

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
   It cannot build the profile again itself: resolving a path reads the
   directories above it, which the profile no longer lets it read.  On a second pipe it says that it has
   started; a first process that hears nothing knows the programme never
   ran under the profile, carries on unconfined and reports so. */
#if defined(HILDE_SANDBOX_SEATBELT)
#define HILDE_SEATBELT_HANDSHAKE_FD 197
#define HILDE_SEATBELT_STARTED_FD 198
#define HILDE_SEATBELT_MAGIC "HildeSbx"
#define HILDE_SEATBELT_MAGIC_LENGTH 8
#define HILDE_SEATBELT_MESSAGE_LENGTH (HILDE_SEATBELT_MAGIC_LENGTH + 16)
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
   bytes makes this the confined process; anything else at that number is
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
  if ((got != (ssize_t) sizeof message) ||
      (memcmp(message, HILDE_SEATBELT_MAGIC, HILDE_SEATBELT_MAGIC_LENGTH) != 0)) {
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
   permissions, each ending in a zero byte, and promises the words of the
   policy when with_promises is 1.  In the process started under the
   profile: the number of paths in the profile, when it was built from
   this policy, else -2.  In the first process it does not
   return when the confined one started, and answers -2 when it did not.
   -1 on a platform without Seatbelt. */
int32_t hilde_sandbox_seatbelt(uint8_t* grants, int32_t count, uint8_t* promises, int32_t with_promises) {
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
   that leaves it.  A path below no grant is refused with EACCES.  Calls
   made by C libraries on their own, such as a database opening its file,
   are not routed and fail in capability mode, which narrows what is
   reachable and never widens it.

   Capability mode allows neither a connection to a new address nor exec,
   so it is entered only for promises that need neither; with other
   promises, or none, nothing is applied and the report says why.  The
   standard descriptors are limited too: 0 to reading, 1 and 2 to
   writing.  A descriptor the programme opened before is left as it is. */
#if defined(HILDE_SANDBOX_CAPSICUM)
/* One path of the policy in capability mode: absolute, without a slash at
   its end ("/" for the root), and its descriptor. */
struct hilde_capsicum_grant {
  char* path;
  size_t length;
  int fd;
  int directory;
};

static struct hilde_capsicum_grant* hilde_capsicum_grants;
static int32_t hilde_capsicum_count;
static int hilde_capsicum_entered;
/* The working directory when capability mode was entered, which cannot
   change after it: a relative path is taken from here. */
static char hilde_capsicum_cwd[PATH_MAX];

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

/* path made absolute from the working directory into out and cleaned by
   its letters alone: no empty name, no "." and no ".." is left, a ".."
   takes the name before it away and stays at the root, and no slash ends
   it but the root's.  A grant and a path asked for are cleaned the same
   way, so that "." and "notes.txt" meet.  The cleaning only picks the
   grant; the kernel resolves the rest below the grant's descriptor and
   refuses a name that leaves it, so it never widens what is reachable.
   0 when it does not fit. */
static int hilde_capsicum_absolute(const char* path, const char* cwd, char out[PATH_MAX]) {
  char joined[PATH_MAX];
  size_t length;
  size_t used = 0;
  size_t at = 0;

  if (path[0] == '/') {
    length = strlen(path);
    if (length >= PATH_MAX) {
      return 0;
    }
    memcpy(joined, path, length + 1);
  } else {
    size_t head = strlen(cwd);
    size_t tail = strlen(path);

    if ((head == 0) || (head + 1 + tail >= PATH_MAX)) {
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
static int hilde_path_open(const char* path, int flags, mode_t mode) {
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

static int hilde_path_stat(const char* path, struct stat* info, int follow) {
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
static int hilde_path_remove(const char* path, int directory) {
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

static int hilde_path_mkdir(const char* path, mode_t mode) {
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

static int hilde_path_rename(const char* from, const char* to) {
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

static int hilde_path_link(const char* existing, const char* name) {
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
static int hilde_path_symlink(const char* target, const char* name) {
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

static ssize_t hilde_path_readlink(const char* path, char* out, size_t size) {
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
static DIR* hilde_path_opendir(const char* path) {
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

/* One path as a rule of the ruleset: a directory gets the directory
   rights, an existing file (or a device node) the file rights, and a file
   that may be created ("c") the
   directory rights on its parent.  1 when the path is covered, 0 when it is
   not: it does not exist and may not be created, the kernel refused to
   look at it, or the rule was refused.
   The path is opened first and its kind read from the open descriptor
   with fstat(2), and the rule is made on that descriptor.  A stat of the
   name before the open would leave a moment in which a file could be
   swapped for a directory, which would then get the file rights for
   everything beneath it. */
int32_t hilde_sandbox_landlock_add(int32_t ruleset, int32_t abi,
                                   uint8_t* path,
                                   uint8_t* permissions) {
#if defined(HILDE_SANDBOX_LINUX) && defined(HILDE_SANDBOX_LANDLOCK_PATHS)
  {
    extern long syscall(long number, ...);

    const char* name = (const char*) path;
    const char* rights = (const char*) permissions;
    char parent[4096];
    struct stat st;
    struct landlock_path_beneath_attr rule;
    uint64_t access = 0;
    int create = (strchr(rights, 'c') != NULL);
    int use_parent = 0;
    int fd;
    long added;

    fd = open(name, HILDE_O_PATH | HILDE_O_CLOEXEC);
    if (fd >= 0) {
      if (fstat(fd, &st) != 0) {
        close(fd);
        return 0;
      }
      if (S_ISDIR(st.st_mode)) {
        access = hilde_sandbox_directory_rights(rights);
      } else if ((!create) || S_ISCHR(st.st_mode) || S_ISBLK(st.st_mode)) {
        access = hilde_sandbox_file_rights(rights);
      } else {
        close(fd);
        use_parent = 1;
      }
    } else {
      if (!create) {
        return 0;
      }
      use_parent = 1;
    }
    if (use_parent) {
      size_t size = strlen(name);
      char* slash;

      if (size >= sizeof(parent)) {
        return 0;
      }
      memcpy(parent, name, size + 1);
      slash = strrchr(parent, '/');
      if (slash == NULL) {
        parent[0] = '.';
        parent[1] = '\0';
      } else if (slash == parent) {
        parent[1] = '\0';
      } else {
        *slash = '\0';
      }
      fd = open(parent, HILDE_O_PATH | HILDE_O_CLOEXEC);
      if (fd < 0) {
        return 0;
      }
      if (fstat(fd, &st) != 0 || !S_ISDIR(st.st_mode)) {
        close(fd);
        return 0;
      }
      access = hilde_sandbox_directory_rights(rights);
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
   refused, the calls below answer EPERM (23, or fewer where the kernel
   headers lack a number an #ifdef asks for), and every other call is
   allowed.  Installed for every thread of the process
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

/*
 * Files.
 *
 * Each call here wraps what cannot be said in Hilde: a descriptor is a
 * number the kernel owns, the O_ constants are platform numbers, and EINTR
 * is a retry the caller must not have to remember.
 */

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
   way whole, in one write as far as the kernel takes it.  This file does
   not include <stdio.h>, so where the header is not visible anyway, fflush
   is declared here with void* for FILE*, as in hilde_flush_output.  1 when
   every byte was written. */
int32_t hilde_stderr_write_all(const uint8_t* buffer, size_t count) {
#if HILDE_STDIO_VISIBLE
  (void) fflush((FILE*) hilde_stderr());
#else
  extern int fflush(void* stream);

  (void) fflush(hilde_stderr());
#endif
  return hilde_file_write_all(2, buffer, count);
}

/*
 * The terminal.
 */

int hilde_terminal_is(int fd) {
  return isatty(fd) ? 1 : 0;
}

/* The echo of the terminal at fd switched on (on is 1) or off (0), as
   readpassphrase(3) does it: ECHO and ECHONL together, with TCSAFLUSH,
   which also drops what was typed before the switch.  1 on success. */
int hilde_terminal_echo(int fd, int on) {
#if defined(__wasi__)
  /* WASI has no settings of a terminal. */
  (void) fd;
  (void) on;
  return 0;
#else
  struct termios t;

  if (tcgetattr(fd, &t) != 0) {
    return 0;
  }
  if (on != 0) {
    t.c_lflag |= (tcflag_t) ECHO;
  } else {
    t.c_lflag &= ~((tcflag_t) ECHO | (tcflag_t) ECHONL);
  }
  return (tcsetattr(fd, TCSAFLUSH, &t) == 0) ? 1 : 0;
#endif
}

/* The columns of the terminal at fd, or 0 when it is none or does not say. */
uint32_t hilde_terminal_width(int fd) {
#if defined(__wasi__)
  (void) fd;
  return 0;
#else
  struct winsize w;

  memset(&w, 0, sizeof w);
  if (ioctl(fd, TIOCGWINSZ, &w) != 0) {
    return 0;
  }
  return (uint32_t) w.ws_col;
#endif
}

/* What waits to be read on the terminal at fd, dropped with tcflush(3).
   1 on success, and for an fd that is no terminal, which has nothing of
   the kind. */
int hilde_terminal_drain(int fd) {
  if (!isatty(fd)) {
    return 1;
  }
#if defined(__wasi__)
  /* WASI cannot drop what waits on a terminal. */
  return 0;
#else
  return (tcflush(fd, TCIFLUSH) == 0) ? 1 : 0;
#endif
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

/* ------------------------------------------------------------------------
   The system log, for Standard.Log through Bindings.SystemLog.

   openlog(3) keeps the pointer to its name and reads it at every syslog(3),
   so the name lives here, in a buffer of this file, and not in a Hilde
   string that is freed.  A longer name is cut to 63 bytes.  LOG_NDELAY
   connects at once, before a sandbox could close the way to the log.  The
   facilities and priorities are passed as indexes and turned into the
   values of this system's syslog.h here, so no number of one system is
   written into a Hilde source.  syslog(3) gets the text through "%.*s",
   never as its format: a per cent sign in a message stays a per cent sign.
   ------------------------------------------------------------------------ */

#if defined(__wasi__)
/* WASI has no system log: the three functions do nothing there, and a
   log written to a file is untouched. */
void hilde_syslog_open(const uint8_t* name, size_t length, uint8_t facility) {
  (void) name;
  (void) length;
  (void) facility;
}

void hilde_syslog_write(uint8_t priority, const uint8_t* text, size_t length) {
  (void) priority;
  (void) text;
  (void) length;
}

void hilde_syslog_close(void) {
}
#else
static char hilde_syslog_name[64];

static const int hilde_syslog_facilities[] = {
  LOG_USER, LOG_DAEMON, LOG_LOCAL0, LOG_LOCAL1, LOG_LOCAL2,
  LOG_LOCAL3, LOG_LOCAL4, LOG_LOCAL5, LOG_LOCAL6, LOG_LOCAL7
};

static const int hilde_syslog_priorities[] = {
  LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERR
};

void hilde_syslog_open(const uint8_t* name, size_t length, uint8_t facility) {
  size_t kept = length;

  if (kept > sizeof hilde_syslog_name - 1) {
    kept = sizeof hilde_syslog_name - 1;
  }
  closelog();
  if (kept > 0) {
    memcpy(hilde_syslog_name, name, kept);
  }
  hilde_syslog_name[kept] = '\0';
  if (facility >= sizeof hilde_syslog_facilities / sizeof hilde_syslog_facilities[0]) {
    facility = 0;
  }
  openlog(hilde_syslog_name, LOG_PID | LOG_NDELAY, hilde_syslog_facilities[facility]);
}

void hilde_syslog_write(uint8_t priority, const uint8_t* text, size_t length) {
  int shown = (length > (size_t) INT32_MAX) ? INT32_MAX : (int) length;

  if (priority >= sizeof hilde_syslog_priorities / sizeof hilde_syslog_priorities[0]) {
    priority = 3;
  }
  syslog(hilde_syslog_priorities[priority], "%.*s", shown, (const char*) text);
}

void hilde_syslog_close(void) {
  closelog();
}
#endif

/* ------------------------------------------------------------------------
   Signals, for Standard.Signal through Bindings.Signal.

   The handler does two things only, both async-signal-safe: it adds one to
   the count of its kind with a GNU atomic builtin, as the tasks in this
   file do, and it writes one byte to the write end of a pipe the runtime
   keeps.  A programme reads the counts and waits on the pipe; it never
   runs its own code in the handler.  The pipe is made at the first watch
   and never closed: closing it would let a handler that is still running
   on another thread write into whatever file the kernel gives that number
   next.  Both ends are non-blocking, so a full pipe drops a byte instead
   of stopping the handler, and close-on-exec.

   OpenBSD, FreeBSD and macOS declare sigaction and SA_RESTART under -std=c17;
   glibc does not: with gcc 14.2.0, struct sigaction is incomplete and sigset_t,
   SA_RESTART, sigemptyset and sigaction are undeclared, while the signal
   numbers, alarm and getpid are declared.  So on Linux the struct is
   declared here with glibc's layout and sigaction is reached through an
   asm label, as for getaddrinfo above; scripts/signal/check-header.sh
   checks the layout and SA_RESTART against the real header on Linux.  The
   mask is set to zero with memset, which leaves none of the five signals
   in it on either system, as sigismember confirms.  glibc's own
   sigemptyset clears only the first 8 bytes, the 64 signals of the
   kernel, and leaves the rest as it was, so the runtime does not copy
   that and clears the whole mask.
   ------------------------------------------------------------------------ */

#define HILDE_SIGNAL_KINDS 5

#if defined(__linux__)
/* glibc's layout: the handler, a mask of 1024 bits, the flags, the
   restorer; 152 bytes on arm64, with the mask at offset 8 and the flags
   at 136.  The fields have names of their own, since with a feature-test
   macro glibc makes sa_handler a macro. */
typedef struct hilde_sigaction {
  void (*handler)(int);
  uint64_t mask[16];
  int flags;
  void (*restorer)(void);
} hilde_sigaction_t;

extern int hilde_libc_sigaction(int number, const hilde_sigaction_t* act,
                                hilde_sigaction_t* old) __asm__("sigaction");
#define HILDE_SA_RESTART 0x10000000
static const int hilde_signal_numbers[HILDE_SIGNAL_KINDS] = {
  SIGHUP, SIGINT, SIGTERM, SIGUSR1, SIGUSR2
};
#define HILDE_SIGACTION_HANDLER(act) ((act).handler)
#define HILDE_SIGACTION_FLAGS(act) ((act).flags)
#elif defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
typedef struct sigaction hilde_sigaction_t;
#define hilde_libc_sigaction sigaction
#define HILDE_SA_RESTART SA_RESTART
static const int hilde_signal_numbers[HILDE_SIGNAL_KINDS] = {
  SIGHUP, SIGINT, SIGTERM, SIGUSR1, SIGUSR2
};
#define HILDE_SIGACTION_HANDLER(act) ((act).sa_handler)
#define HILDE_SIGACTION_FLAGS(act) ((act).sa_flags)
#endif

#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
static uint32_t hilde_signal_counts[HILDE_SIGNAL_KINDS];
static int hilde_signal_pipe[2] = { -1, -1 };
static uint8_t hilde_signal_mask = 0;

static void hilde_signal_handler(int number) {
  int saved = errno;
  const uint8_t byte = 0;

  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if (hilde_signal_numbers[i] == number) {
      __atomic_add_fetch(&hilde_signal_counts[i], 1, __ATOMIC_SEQ_CST);
    }
  }
  if (write(hilde_signal_pipe[1], &byte, 1) < 0) {
    /* A full pipe: a byte is waiting already, which is all a wait needs. */
  }
  errno = saved;
}

/* Makes fd non-blocking and close-on-exec.  0 on success, -1 otherwise. */
static int hilde_signal_mark(int fd) {
  int flags = fcntl(fd, F_GETFL);

  if (flags < 0 || fcntl(fd, F_SETFL, flags | O_NONBLOCK) != 0) {
    return -1;
  }
  return (fcntl(fd, F_SETFD, FD_CLOEXEC) == 0) ? 0 : -1;
}

/* Every watched kind back to its default action.  1 when the kernel took
   each one back, 0 when it refused one; the watch is over either way. */
int32_t hilde_signal_stop(void) {
  hilde_sigaction_t act;
  int32_t all = 1;

  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = SIG_DFL;
  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if ((hilde_signal_mask & (1u << i)) != 0
        && hilde_libc_sigaction(hilde_signal_numbers[i], &act, NULL) != 0) {
      all = 0;
    }
  }
  hilde_signal_mask = 0;
  return all;
}

/* Installs the handler for every kind whose bit is set in mask.  1 on
   success; 0 when a watch is in place, the pipe could not be made, or the
   kernel refused a kind -- and then the kinds installed before it get their
   default action back. */
int32_t hilde_signal_watch(uint8_t mask) {
  hilde_sigaction_t act;

  /* In a library the handlers would take the host programme's signals. */
  if (HILDE_IN_LIBRARY) {
    return 0;
  }
  if (hilde_signal_mask != 0 || mask == 0 || mask >= (1u << HILDE_SIGNAL_KINDS)) {
    return 0;
  }
  if (hilde_signal_pipe[0] < 0) {
    int ends[2];

    if (pipe(ends) != 0) {
      return 0;
    }
    if (hilde_signal_mark(ends[0]) != 0 || hilde_signal_mark(ends[1]) != 0) {
      close(ends[0]);
      close(ends[1]);
      return 0;
    }
    hilde_signal_pipe[0] = ends[0];
    hilde_signal_pipe[1] = ends[1];
  }
  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = hilde_signal_handler;
  HILDE_SIGACTION_FLAGS(act) = HILDE_SA_RESTART;
  for (int i = 0; i < HILDE_SIGNAL_KINDS; i++) {
    if ((mask & (1u << i)) != 0) {
      if (hilde_libc_sigaction(hilde_signal_numbers[i], &act, NULL) != 0) {
        /* The watch failed, and 0 says so whatever the undoing of the
           kinds installed before it answers. */
        hilde_signal_stop();
        return 0;
      }
      hilde_signal_mask = (uint8_t) (hilde_signal_mask | (1u << i));
    }
  }
  return 1;
}

uint32_t hilde_signal_count(uint8_t kind) {
  if (kind >= HILDE_SIGNAL_KINDS) {
    return 0;
  }
  return __atomic_load_n(&hilde_signal_counts[kind], __ATOMIC_SEQ_CST);
}

/* Reads every byte the pipe holds. */
void hilde_signal_drain(void) {
  uint8_t bytes[64];

  if (hilde_signal_pipe[0] < 0) {
    return;
  }
  while (read(hilde_signal_pipe[0], bytes, sizeof bytes) > 0) {
  }
}

/* Waits with poll(2) until the pipe holds a byte or milliseconds have
   passed, then empties it.  1 when a byte was there. */
int32_t hilde_signal_wait(uint32_t milliseconds) {
  struct pollfd watched;
  int timeout = (milliseconds > (uint32_t) INT32_MAX) ? INT32_MAX : (int) milliseconds;
  int ready;

  if (hilde_signal_pipe[0] < 0) {
    return 0;
  }
  watched.fd = hilde_signal_pipe[0];
  watched.events = POLLIN;
  watched.revents = 0;
  ready = poll(&watched, 1, timeout);
  if (ready < 0 && errno == EINTR) {
    /* The signal that ended the wait may be the watched one: its handler
       has written its byte by now, and poll does not restart on Linux. */
    watched.revents = 0;
    ready = poll(&watched, 1, 0);
  }
  hilde_signal_drain();
  return (ready > 0 && (watched.revents & POLLIN) != 0) ? 1 : 0;
}

/* kill(2) with the signal of kind, declared here as in
   hilde_process_terminate.  0 for a number below 1, which kill reads as
   a process group. */
int32_t hilde_signal_send(int32_t pid, uint8_t kind) {
  extern int kill(pid_t pid, int sig);

  if (pid < 1 || kind >= HILDE_SIGNAL_KINDS) {
    return 0;
  }
  return (kill((pid_t) pid, hilde_signal_numbers[kind]) == 0) ? 1 : 0;
}

#else
int32_t hilde_signal_watch(uint8_t mask) {
  (void) mask;
  return 0;
}

uint32_t hilde_signal_count(uint8_t kind) {
  (void) kind;
  return 0;
}

void hilde_signal_drain(void) {
}

int32_t hilde_signal_wait(uint32_t milliseconds) {
  (void) milliseconds;
  return 0;
}

int32_t hilde_signal_stop(void) {
  return 1;
}

int32_t hilde_signal_send(int32_t pid, uint8_t kind) {
  (void) pid;
  (void) kind;
  return 0;
}
#endif

/* alarm(2): the kernel sends SIGALRM after seconds, whose default action
   ends the process; 0 takes an alarm back.  The seconds that were left. */
uint32_t hilde_signal_alarm(uint32_t seconds) {
#if defined(__wasi__)
  (void) seconds;
  return 0;
#else
  /* In a library, SIGALRM's default action would end the host's process. */
  if (HILDE_IN_LIBRARY) {
    hilde_stop_with("Hilde: alarm(2) is not available in a library: SIGALRM would end the host's process");
  }
  return (uint32_t) alarm((unsigned int) seconds);
#endif
}

int32_t hilde_process_number(void) {
  return (int32_t) getpid();
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

/* The mode of an open file, set with fchmod(2).  1 on success. */
int hilde_file_set_mode(int fd, uint32_t mode) {
  extern int fchmod(int fd, mode_t mode);

  return (fchmod(fd, (mode_t) mode) == 0) ? 1 : 0;
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
   clock_gettime answers EINVAL, the caller gets -1, and a timeout quietly
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

/*
 * Resource limits and usage, and how long the system has been up.
 */

/* The RLIMIT_ number of which: 0 the data segment, 1 open files, 2 the
   size of a core file; -1 for any other. */
#if !defined(__wasi__)
static int hilde_resource_number(uint32_t which) {
  switch (which) {
  case 0:
    return RLIMIT_DATA;
  case 1:
    return RLIMIT_NOFILE;
  case 2:
    return RLIMIT_CORE;
  default:
    return -1;
  }
}
#endif

/* A limit as the caller writes it: RLIM_INFINITY as the largest 64-bit
   number on every platform, since it is that number on Linux and 2^63 - 1
   on OpenBSD. */
#if !defined(__wasi__)
static uint64_t hilde_resource_out(rlim_t value) {
  return (value == RLIM_INFINITY) ? UINT64_MAX : (uint64_t) value;
}
#endif

/* A limit as the kernel takes it, into out: the largest 64-bit number as
   RLIM_INFINITY.  0 for a number rlim_t cannot hold, anything from
   RLIM_INFINITY up that is not the largest number. */
#if !defined(__wasi__)
static int hilde_resource_in(uint64_t value, rlim_t* out) {
  if (value == UINT64_MAX) {
    *out = RLIM_INFINITY;
    return 1;
  }
  if (value >= (uint64_t) RLIM_INFINITY) {
    return 0;
  }
  *out = (rlim_t) value;
  return 1;
}
#endif

/* The soft and the hard limit of which, with getrlimit(2), into pair.  1
   on success. */
int hilde_resource_limit(uint32_t which, uint64_t* pair) {
#if defined(__wasi__)
  (void) which;
  (void) pair;
  return 0;
#else
  struct rlimit limit;
  int number = hilde_resource_number(which);

  if (number < 0) {
    return 0;
  }
  if (getrlimit(number, &limit) != 0) {
    return 0;
  }
  pair[0] = hilde_resource_out(limit.rlim_cur);
  pair[1] = hilde_resource_out(limit.rlim_max);
  return 1;
#endif
}

/* The soft and the hard limit of which set with setrlimit(2).  1 on
   success; 0 for a value no limit can have, a soft limit above the hard
   one, or a refusal of the kernel, which raising a hard limit without
   privilege is. */
int hilde_resource_set_limit(uint32_t which, uint64_t soft, uint64_t hard) {
#if defined(__wasi__)
  (void) which;
  (void) soft;
  (void) hard;
  return 0;
#else
  struct rlimit limit;
  int number = hilde_resource_number(which);

  if (number < 0 || soft > hard) {
    return 0;
  }
  if (!hilde_resource_in(soft, &limit.rlim_cur) || !hilde_resource_in(hard, &limit.rlim_max)) {
    return 0;
  }
  return (setrlimit(number, &limit) == 0) ? 1 : 0;
#endif
}

/* What the process has used, with getrusage(2), into three slots: the CPU
   time in the process and in the kernel for it, in microseconds, and the
   largest resident set so far in bytes.  ru_maxrss counts kilobytes on
   Linux and OpenBSD.  1 on success. */
int hilde_resource_usage(uint64_t* slots) {
#if defined(__wasi__)
  (void) slots;
  return 0;
#else
  struct rusage usage;

  if (getrusage(RUSAGE_SELF, &usage) != 0) {
    return 0;
  }
  slots[0] = ((uint64_t) usage.ru_utime.tv_sec * 1000000) + (uint64_t) usage.ru_utime.tv_usec;
  slots[1] = ((uint64_t) usage.ru_stime.tv_sec * 1000000) + (uint64_t) usage.ru_stime.tv_usec;
  slots[2] = (usage.ru_maxrss < 0) ? 0 : (uint64_t) usage.ru_maxrss * 1024;
  return 1;
#endif
}

/* Nanoseconds since the system started, time asleep included, or -1
   where there is no such clock.

   The clock is CLOCK_BOOTTIME, and its number is written as a literal for
   the reason hilde_time_monotonic_nanos gives: glibc's headers hide
   clock_gettime and the CLOCK_ constants under -std=c17.  With a
   feature-test macro the header says CLOCK_BOOTTIME is 7 with glibc (gcc
   14.2.0, aarch64) and 6 on OpenBSD (clang 19.1.7).  FreeBSD (15.1, clang
   19.1.7) defines it as CLOCK_MONOTONIC, which is 4.  With the literal, no
   macro and the declaration below, clock_gettime answers 0 and gives the
   uptime on all three, while an unknown number such as 4711 answers -1.
   On macOS CLOCK_MONOTONIC starts at boot and counts on while the system
   sleeps, and its header declares it under -std=c17. */
int64_t hilde_time_boot_nanos(void) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__)
  {
    extern int clock_gettime(int clock_id, struct timespec* ts);
    struct timespec ts;
#if defined(__linux__)
    const int boot = 7;
#elif defined(__FreeBSD__)
    const int boot = 4;
#else
    const int boot = 6;
#endif

    if (clock_gettime(boot, &ts) != 0) {
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
 * A pipe.
 *
 * A poller can only be tested with something that can be registered with
 * it: epoll refuses a regular file (EPERM), and a pipe is the smallest
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
  int fd;
  int flags;
  int ready;
  int error = 0;
  socklen_t error_size = sizeof error;
  struct pollfd waiting;

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

/* Wait until the socket can be read, or written when writing is 1, at most
   milliseconds, or without a limit when it is negative.  1 when it is
   ready or a signal came (the caller then asks again and waits again with
   what is left), 0 when the time ran out, -1 when poll failed.  An error
   or a hang-up on the socket counts as ready: the next read or write then
   says what happened. */
int32_t hilde_socket_wait(int32_t fd, int32_t writing, int32_t milliseconds) {
  struct pollfd waiting;
  int ready;

  waiting.fd = fd;
  waiting.events = (writing == 1) ? POLLOUT : POLLIN;
  waiting.revents = 0;
  ready = poll(&waiting, 1, milliseconds < 0 ? -1 : (int) milliseconds);
  if (ready < 0) {
    return (errno == EINTR) ? 1 : -1;
  }
  return (ready > 0) ? 1 : 0;
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

/* What tls_connect does before its handshake, so that the socket is the
   runtime's and goes through the two functions above: every address of
   host for port, a number or a service name, from getaddrinfo, tried in
   its order with a blocking stream socket until one connects.  The socket
   is close-on-exec.  Its number, or -1 when the name has no address or no
   address took the connection; on a system whose resolver layout is not
   checked, always -1. */
static inline __attribute__((unused))
int32_t hilde_tls_tcp_connect(const char* host, const char* port) {
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__) || \
    defined(__APPLE__)
  hilde_addrinfo_t hints;
  hilde_addrinfo_t* list = NULL;
  int32_t fd = -1;

  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  if (hilde_libc_getaddrinfo(host, port, &hints, &list) != 0) {
    return -1;
  }
  for (hilde_addrinfo_t* at = list; at != NULL && fd < 0; at = at->ai_next) {
    int s = socket(at->ai_family, at->ai_socktype, at->ai_protocol);
    int r;

    if (s < 0) {
      continue;
    }
    if (fcntl(s, F_SETFD, FD_CLOEXEC) != 0) {
      close(s);
      continue;
    }
    r = connect(s, (const struct sockaddr*) at->ai_addr, (socklen_t) at->ai_addrlen);
    if (r != 0 && errno == EINTR) {
      /* An interrupted connect(2) goes on by itself; it is waited for
         and its outcome read, as POSIX says, not asked a second time. */
      struct pollfd waiting;
      int error = 0;
      socklen_t size = (socklen_t) sizeof error;

      waiting.fd = s;
      waiting.events = POLLOUT;
      waiting.revents = 0;
      while ((r = poll(&waiting, 1, -1)) < 0 && errno == EINTR) {
      }
      r = (r == 1 && getsockopt(s, SOL_SOCKET, SO_ERROR, &error, &size) == 0 && error == 0) ? 0 : -1;
    }
    if (r == 0) {
      fd = s;
    } else {
      close(s);
    }
  }
  hilde_libc_freeaddrinfo(list);
  return fd;
#else
  (void) host;
  (void) port;
  return -1;
#endif
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

/* Start the programme at path with count arguments packed into block, each
   followed by a zero byte; the first is what the child sees as its own
   name.  A block of length bytes that does not hold count such texts is
   refused.  The child's standard input, output and error are three pipes; the
   parent's ends go into ends in that order (the end to write the child's
   input into, then the two ends to read from).  The process id, or -1 when
   anything failed, including execve(2) in the child, which is reported
   back rather than discovered later as an exit status of 127.

   There is no PATH search: path is used as it stands, so a programme names
   its binary rather than letting the environment choose one.

   Every descriptor above 2 is closed in the child, whatever flags it
   carries (closefrom(3)): a descriptor opened by C code this file does not
   control, without close-on-exec, would otherwise reach every child.  One
   descriptor is kept until the exec: the status pipe, moved to 3 and
   marked close-on-exec, so that a successful exec closes it and a failed
   one writes errno into it. */
int32_t hilde_process_spawn(const uint8_t* path, const uint8_t* block,
                            size_t length, size_t count, int* ends) {
  extern char** environ;
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
      child_errno = errno;
      (void) write(status[1], &child_errno, sizeof(child_errno));
      _exit(127);
    }
    if (status[1] != 3) {
      if (dup2(status[1], 3) < 0) {
        _exit(127);
      }
    }
    if (fcntl(3, F_SETFD, FD_CLOEXEC) != 0) {
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
    execve((const char*) path, argv, environ);
    child_errno = errno;
    (void) write(3, &child_errno, sizeof(child_errno));
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
    /* The exec failed, and nothing ran; or the read failed, and whether the
       child runs is not known, so it is ended.  Either way the process id
       is collected here so that it does not become a zombie, and a running
       child does not hold the wait. */
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

int32_t hilde_process_wait(int32_t pid) {
  (void) pid;
  return -1;
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

/*
 * Tasks: fibers on N OS threads.
 *
 * A task is a fiber: its own stack, and a register switch to move between
 * stacks.  The fibers run on N OS threads, the workers, one per processor
 * the system reports: M fibers on N threads, the shape Go has.  A fiber runs
 * on whichever worker takes it, and may continue on another after it
 * waited -- except the programme's own first task, main, which runs on the
 * thread the process started on and only there.
 *
 * Each worker has a queue of runnable fibers and takes from its own first;
 * a worker whose queue is empty takes from another's.  A fiber that waits
 * is parked on a key -- the address of what it waits for -- in a table of
 * keys, and made runnable again by a wake on the same key.  Every wait is
 * made under the lock that guards the condition it waits for, and the
 * fiber is in the table before that lock is let go, so a wake cannot fall
 * between the test and the park.
 *
 * When no worker has anything to run and no fiber waits for a descriptor,
 * every task is waiting on every other and the programme ends with a
 * message saying so: a deadlock that is reported, not a hang.
 */

/* The register switch exists for two architectures, and the task runtime is
   compiled only where one of them meets Linux, OpenBSD or macOS, or where
   x86-64 meets FreeBSD, the one pair of FreeBSD and an architecture that was
   run.  Anywhere else the task functions below answer that there are no
   tasks, the same way the poller answers for a missing backend. */
#if ((defined(__linux__) || defined(__OpenBSD__) || defined(__APPLE__)) && \
     (defined(__x86_64__) || defined(__aarch64__))) || \
    (defined(__FreeBSD__) && defined(__x86_64__))
#define HILDE_TASKS 1
#endif

/* ThreadSanitizer does not see a stack switch it was not told about, and a
   fiber that moves between threads is exactly what it would then report as
   a race.  Under -fsanitize=thread the switch below tells it, through the
   fiber interface both gcc's and clang's runtimes carry; in every other
   build these lines compile to nothing. */
#if defined(__SANITIZE_THREAD__)
#define HILDE_TSAN 1
#elif defined(__has_feature)
#if __has_feature(thread_sanitizer)
#define HILDE_TSAN 1
#endif
#endif
#if defined(HILDE_TSAN)
extern void* __tsan_get_current_fiber(void);
extern void* __tsan_create_fiber(unsigned flags);
extern void __tsan_destroy_fiber(void* fiber);
extern void __tsan_switch_to_fiber(void* fiber, unsigned flags);
#endif

/* AddressSanitizer does not see such a switch either.  It keeps the bounds
   of the stack it believes is running, and a call of a function that does
   not return -- _Exit on a deadlock -- from a stack outside those bounds
   makes it warn that false reports may follow.  Under -fsanitize=address
   the switch below names the stack it goes to, and the stack it lands on
   says so, through the fiber interface of gcc's and clang's runtimes; in
   every other build these lines compile to nothing. */
#if defined(__SANITIZE_ADDRESS__)
#define HILDE_ASAN 1
#elif defined(__has_feature)
#if __has_feature(address_sanitizer)
#define HILDE_ASAN 1
#endif
#endif
#if defined(HILDE_ASAN)
extern void __sanitizer_start_switch_fiber(void** fake_stack_save,
                                           const void* bottom, size_t size);
extern void __sanitizer_finish_switch_fiber(void* fake_stack_save,
                                            const void** bottom_old,
                                            size_t* size_old);

/* A task goes on on whichever worker takes it.  To find a use of a frame
   after its function returned, AddressSanitizer moves frames into a store
   of the thread that made them, and a task that goes on on another worker
   reads its frames from the wrong store.  So that check is off in every
   programme built with the sanitizer; an ASAN_OPTIONS of the environment
   still decides over it. */
const char* __asan_default_options(void);
const char* __asan_default_options(void) {
  return "detect_stack_use_after_return=0";
}
#endif

/* Valgrind does not know that a task's stack is a stack.  When two stacks
   lie closer together than its --max-stackframe, it takes a switch between
   them for a stack that grew or shrank and marks what lies between as not
   addressable, and then reports errors in hilde_task_switch and in reads of
   memory other tasks had just written.  Built with -DHILDE_VALGRIND, as
   hilde test --valgrind builds, every task stack is registered with
   valgrind while it is mapped, through valgrind's own header; no other
   build reads that header. */
#if defined(HILDE_VALGRIND)
#include <valgrind/valgrind.h>
#endif

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

/* The switch: save the callee-saved registers of the running stack on that
   stack, store its stack pointer through save, load next as the stack
   pointer and restore what is saved there.  A fiber that has never run has a
   frame prepared by hilde_task_prepare_stack below, whose return address is
   the trampoline.

   Written by hand, per architecture, and not with ucontext: ucontext does not
   compile under the flags this runtime is compiled with, and spends half its
   time in a sigprocmask it does not need.  Both switches follow the
   platform's calling convention -- AAPCS64 on aarch64 (x19-x28, the frame
   pointer, the link register, d8-d15) and the System V AMD64 ABI on x86-64
   (rbx, rbp, r12-r15, and the MXCSR and x87 control words). */

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

#if defined(HILDE_TASKS)

void hilde_task_switch(void** save, void* next);
void hilde_task_start(void* fiber);

/* The switch is written once for the object files of Linux and the BSDs and
   for Mach-O.  Mach-O puts an underscore
   before every C name, keeps a symbol inside the image with .private_extern
   instead of .hidden, and has no .type and no .size. */
#if defined(__APPLE__)
#define HILDE_ASM_BEGIN(name, type) \
  ".globl _" name "\n.private_extern _" name "\n.p2align 4\n_" name ":\n"
#define HILDE_ASM_END(name) ""
#else
#define HILDE_ASM_BEGIN(name, type) \
  ".globl " name "\n.hidden " name "\n.type " name ", " type "\n" name ":\n"
#define HILDE_ASM_END(name) ".size " name ", .-" name "\n"
#endif

#if defined(__aarch64__)
__asm__(
  ".text\n"
  HILDE_ASM_BEGIN("hilde_task_switch", "%function")
  "  sub sp, sp, #176\n"
  "  stp x19, x20, [sp, #0]\n"
  "  stp x21, x22, [sp, #16]\n"
  "  stp x23, x24, [sp, #32]\n"
  "  stp x25, x26, [sp, #48]\n"
  "  stp x27, x28, [sp, #64]\n"
  "  stp x29, x30, [sp, #80]\n"
  "  stp d8, d9, [sp, #96]\n"
  "  stp d10, d11, [sp, #112]\n"
  "  stp d12, d13, [sp, #128]\n"
  "  stp d14, d15, [sp, #144]\n"
  "  mov x9, sp\n"
  "  str x9, [x0]\n"
  "  mov sp, x1\n"
  "  ldp x19, x20, [sp, #0]\n"
  "  ldp x21, x22, [sp, #16]\n"
  "  ldp x23, x24, [sp, #32]\n"
  "  ldp x25, x26, [sp, #48]\n"
  "  ldp x27, x28, [sp, #64]\n"
  "  ldp x29, x30, [sp, #80]\n"
  "  ldp d8, d9, [sp, #96]\n"
  "  ldp d10, d11, [sp, #112]\n"
  "  ldp d12, d13, [sp, #128]\n"
  "  ldp d14, d15, [sp, #144]\n"
  "  add sp, sp, #176\n"
  "  ret\n"
  HILDE_ASM_END("hilde_task_switch")
  HILDE_ASM_BEGIN("hilde_task_trampoline", "%function")
  "  mov x0, x19\n"
  "  bl " HILDE_ASM_NAME("hilde_task_start") "\n"
  "  brk #0\n"
  HILDE_ASM_END("hilde_task_trampoline")
);
#elif defined(__x86_64__)
__asm__(
  ".text\n"
  HILDE_ASM_BEGIN("hilde_task_switch", "@function")
  "  endbr64\n"
  "  pushq %rbp\n"
  "  pushq %rbx\n"
  "  pushq %r12\n"
  "  pushq %r13\n"
  "  pushq %r14\n"
  "  pushq %r15\n"
  "  subq $8, %rsp\n"
  "  stmxcsr (%rsp)\n"
  "  fnstcw 4(%rsp)\n"
  "  movq %rsp, (%rdi)\n"
  "  movq %rsi, %rsp\n"
  "  ldmxcsr (%rsp)\n"
  "  fldcw 4(%rsp)\n"
  "  addq $8, %rsp\n"
  "  popq %r15\n"
  "  popq %r14\n"
  "  popq %r13\n"
  "  popq %r12\n"
  "  popq %rbx\n"
  "  popq %rbp\n"
  "  ret\n"
  HILDE_ASM_END("hilde_task_switch")
  HILDE_ASM_BEGIN("hilde_task_trampoline", "@function")
  "  movq %r12, %rdi\n"
  "  call " HILDE_ASM_NAME("hilde_task_start") "\n"
  "  ud2\n"
  HILDE_ASM_END("hilde_task_trampoline")
);
#endif

void hilde_task_trampoline(void);

#define HILDE_TASK_RUNNING 2
#define HILDE_TASK_DONE 4

/* Where a parked fiber stands between the moment it decided to wait and the
   moment its registers are saved.  A wake can come in that window -- from
   another thread, which could otherwise start the fiber on a second stack
   pointer while the first is still being written -- so the two sides meet
   on this one word with a compare-and-swap, and whichever comes second
   queues the fiber.  A running fiber is HILDE_TASK_PARK_NONE: running
   counts as not parked. */
#define HILDE_TASK_PARK_NONE 0
#define HILDE_TASK_PARK_LEAVING 1
#define HILDE_TASK_PARK_PARKED 2
#define HILDE_TASK_PARK_WOKEN 3

/* Reserved per task: 64 KiB of stack and HILDE_TASK_GUARD_PAGES guard pages
   below it.  Address space is free and only a touched page costs memory:
   10,000 untouched 64 KiB stacks cost 7 bytes each, one touched page 4096
   bytes.  The stack does not grow; running off its end hits a guard page
   and the process ends there, not somewhere else later.  Sixteen pages,
   not one: a frame larger than a page could step over a single guard page
   into the mapping below it, and code built with -fstack-clash-protection
   touches every page of a large frame, so it lands in one of them. */
#define HILDE_TASK_STACK (64u * 1024u)
#define HILDE_TASK_GUARD_PAGES 16u

/* The most stack a scope may ask for its tasks.  A scope opened with a
   size takes it rounded up to a page, at least HILDE_TASK_STACK and at
   most this; only a touched page costs memory, as above. */
#define HILDE_TASK_STACK_MOST (8u * 1024u * 1024u)

/* The most workers a process starts, whatever the system reports: a number
   that bounds threads is a hardening number.  The messages of
   hilde_task_count_workers spell this number out as text. */
#define HILDE_TASK_MAX_WORKERS 64

/* The key table: parked fibers, by the address they wait on, spread over
   this many lists so that two unrelated waits do not share one lock. */
#define HILDE_TASK_BUCKETS 64

typedef struct hilde_task_scope {
  pthread_mutex_t lock;
  size_t live;                     /* tasks started in it and not ended */
  size_t stack;                    /* bytes of stack for each of its tasks */
} hilde_task_scope_t;

typedef struct hilde_task_fiber {
  void* sp;                        /* saved while it is not running */
  unsigned char* mapping;          /* NULL for the programme's own stack */
  size_t mapped;
  size_t stack;                    /* the usable part of mapped */
  hilde_unit_t (*entry)(uint8_t*);
  uint8_t* argument;
  pthread_mutex_t lock;            /* guards state for join */
  int state;
  int park;                        /* HILDE_TASK_PARK_, atomic */
  int pinned;                      /* runs on worker 0 only: main */
  const void* wait_key;            /* what it is parked on */
  int wait_fd;                     /* the descriptor, when parked on one */
  short wait_events;
  short got_events;
  int64_t deadline;                /* when a timed wait ends, hilde_task_now */
  const void* timer_key;           /* the key a timed wait is parked on */
  struct hilde_task_fiber* timer_next; /* in the timer list, earliest first */
  hilde_task_scope_t* scope;
  struct hilde_task_fiber* next;   /* in one list at a time: a run queue,
                                      a key's list or the descriptor list */
#if defined(HILDE_TSAN)
  void* tsan;
#endif
#if defined(HILDE_ASAN)
  const void* asan_bottom;         /* its stack's lowest usable address */
  size_t asan_size;
#endif
#if defined(HILDE_VALGRIND)
  unsigned valgrind_stack;         /* its stack's number with valgrind */
#endif
} hilde_task_fiber_t;

/* What a worker does after a fiber has left it, on the worker's own stack,
   once the fiber's registers are saved and it is safe to hand the fiber to
   another thread. */
#define HILDE_TASK_AFTER_PARK 1      /* it waits: see HILDE_TASK_PARK_ */
#define HILDE_TASK_AFTER_READY 2     /* it yielded: queue it */
#define HILDE_TASK_AFTER_DONE 3      /* it ended: tell its scope and joiner */

typedef struct hilde_task_worker {
  pthread_mutex_t lock;            /* guards the queue and main_queued */
  hilde_task_fiber_t* head;
  hilde_task_fiber_t* tail;
  int main_queued;                 /* worker 0: main is in its queue */
  hilde_task_fiber_t* current;     /* the fiber this worker runs, or NULL */
  void* home;                      /* the worker's own stack, saved */
  int after;                       /* HILDE_TASK_AFTER_, for leaving */
  hilde_task_fiber_t* leaving;
  pthread_cond_t wake;             /* with hilde_task_idle_lock */
  int asleep;                      /* under hilde_task_idle_lock */
  int busy;                        /* runs a fiber now, atomic */
  unsigned long runs;              /* fibers it has started to run, atomic */
  int preempt;                     /* asked to let others run, atomic */
  int index;
  pthread_t thread;
#if defined(HILDE_TSAN)
  void* tsan;
#endif
#if defined(HILDE_ASAN)
  const void* asan_bottom;         /* the worker's own stack, see home */
  size_t asan_size;
#endif
} hilde_task_worker_t;

typedef struct hilde_task_bucket {
  pthread_mutex_t lock;
  hilde_task_fiber_t* head;
} hilde_task_bucket_t;

static hilde_task_worker_t hilde_task_workers[HILDE_TASK_MAX_WORKERS];
static hilde_task_bucket_t hilde_task_buckets[HILDE_TASK_BUCKETS];

/* The programme's own stack is a task too, the first one, and worker 0's
   own stack is a mapping like a task's: the process's stack belongs to
   main, so worker 0 needs another to schedule from.  Static, because there
   is one of each per process; everything else is allocated. */
static hilde_task_fiber_t hilde_task_main;
static hilde_task_fiber_t hilde_task_home0;

/* Set once, on the thread the process started on, before any worker thread
   exists; read-only afterwards.  hilde_task_wanted is how many workers the
   system reports (or HILDE_TASK_THREADS says), hilde_task_started how many
   run: 1 until the first spawn, which starts the others. */
static int hilde_task_initialised = 0;
static int hilde_task_wanted = 1;
static int hilde_task_started = 1;

/* The worker the calling thread is.  Read only through hilde_task_here(),
   never cached across a switch: a fiber that waited may continue on another
   thread, and a compiler is allowed to keep a thread-local's address in a
   register for the whole of a function. */
static _Thread_local hilde_task_worker_t* hilde_task_worker_of_thread = NULL;

/* Workers with nothing to do.  hilde_task_idle counts the ones asleep and
   the one in poll(2); hilde_task_polling says whether one is.
   hilde_task_generation changes after every fiber made runnable, so a
   worker that looked at the queues, found them empty and is about to sleep
   can tell that something came in meanwhile. */
static pthread_mutex_t hilde_task_idle_lock = PTHREAD_MUTEX_INITIALIZER;
static int hilde_task_idle = 0;
static int hilde_task_polling = 0;
static unsigned long hilde_task_generation = 0;

/* Fibers parked on a descriptor, and the pipe that interrupts the worker
   sitting in poll(2) when the set changes or work arrives. */
static pthread_mutex_t hilde_task_fd_lock = PTHREAD_MUTEX_INITIALIZER;
static hilde_task_fiber_t* hilde_task_fd_head = NULL;
static size_t hilde_task_fd_count = 0;
static int hilde_task_interrupt[2] = { -1, -1 };

/* Fibers waiting until a time, earliest first, and how many.  A worker
   that looks for work first makes runnable the ones whose time has come;
   an idle one waits no longer than until the earliest. */
static pthread_mutex_t hilde_task_timer_lock = PTHREAD_MUTEX_INITIALIZER;
static hilde_task_fiber_t* hilde_task_timer_head = NULL;
static size_t hilde_task_timer_count = 0;

/* Blocking calls handed to a helper thread and not yet answered. */
static size_t hilde_task_calls = 0;

static __attribute__((noinline)) hilde_task_worker_t* hilde_task_here(void) {
  hilde_task_worker_t* worker = hilde_task_worker_of_thread;

  __asm__ volatile ("" ::: "memory");
  return worker;
}

static void hilde_task_lock(pthread_mutex_t* lock) {
  if (pthread_mutex_lock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}

static void hilde_task_unlock(pthread_mutex_t* lock) {
  if (pthread_mutex_unlock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}

/* The switch, and what the sanitizers have to be told about it.  next_bottom
   and next_size are the bounds of the stack switched to.  When the switch
   returns, another stack has switched back to this one, and came_bottom and
   came_size receive that stack's bounds.  came_bottom is NULL for a task
   that has ended and is never switched back to: AddressSanitizer then drops
   what it kept for this stack.  Every switch goes between a worker's own
   stack and a fiber, never from fiber to fiber, so the stack that comes back
   is always known to the caller. */
static void hilde_task_jump(void** save, void* next, void* next_tsan,
                            const void* next_bottom, size_t next_size,
                            const void** came_bottom, size_t* came_size) {
#if defined(HILDE_ASAN)
  void* fake = NULL;

  __sanitizer_start_switch_fiber(came_bottom == NULL ? NULL : &fake,
                                 next_bottom, next_size);
#else
  (void) next_bottom;
  (void) next_size;
  (void) came_bottom;
  (void) came_size;
#endif
#if defined(HILDE_TSAN)
  __tsan_switch_to_fiber(next_tsan, 0);
#else
  (void) next_tsan;
#endif
  hilde_task_switch(save, next);
#if defined(HILDE_ASAN)
  __sanitizer_finish_switch_fiber(fake, came_bottom, came_size);
#endif
}

#if defined(HILDE_TSAN)
#define HILDE_TASK_TSAN_OF(x) ((x)->tsan)
#else
#define HILDE_TASK_TSAN_OF(x) NULL
#endif

#if defined(HILDE_ASAN)
#define HILDE_TASK_ASAN_BOTTOM(x) ((x)->asan_bottom)
#define HILDE_TASK_ASAN_SIZE(x) ((x)->asan_size)
#else
#define HILDE_TASK_ASAN_BOTTOM(x) NULL
#define HILDE_TASK_ASAN_SIZE(x) 0
#endif

/* The bounds AddressSanitizer is given for a stack.  A task's stack and
   worker 0's own are mappings of a known size, set when they are made.  The
   programme's own stack and the other workers' stacks belong to their
   threads, and their bounds are learnt when a switch comes back from them:
   a fiber is always entered from its worker's own stack, and a worker's own
   stack always from the fiber that left it. */
static void hilde_task_note_home(hilde_task_worker_t* worker,
                                 const void* bottom, size_t size) {
#if defined(HILDE_ASAN)
  worker->asan_bottom = bottom;
  worker->asan_size = size;
#else
  (void) worker;
  (void) bottom;
  (void) size;
#endif
}

static void hilde_task_note_fiber(hilde_task_fiber_t* fiber,
                                  const void* bottom, size_t size) {
#if defined(HILDE_ASAN)
  fiber->asan_bottom = bottom;
  fiber->asan_size = size;
#else
  (void) fiber;
  (void) bottom;
  (void) size;
#endif
}

/* A mapped stack made known to valgrind, and forgotten before it is
   unmapped; nothing in any other build. */
static void hilde_task_register_stack(hilde_task_fiber_t* fiber) {
#if defined(HILDE_VALGRIND)
  fiber->valgrind_stack =
    VALGRIND_STACK_REGISTER(fiber->mapping + (fiber->mapped - fiber->stack),
                            fiber->mapping + fiber->mapped);
#else
  (void) fiber;
#endif
}

static void hilde_task_deregister_stack(hilde_task_fiber_t* fiber) {
#if defined(HILDE_VALGRIND)
  VALGRIND_STACK_DEREGISTER(fiber->valgrind_stack);
#else
  (void) fiber;
#endif
}

/* HILDE_TASK_THREADS as a number from 1 to HILDE_TASK_MAX_WORKERS, or 0
   when it is anything else: not a number, out of range, or longer than
   three digits. */
static int hilde_task_threads_value(const char* text) {
  int value = 0;
  size_t i;

  for (i = 0; text[i] != '\0'; i++) {
    if (text[i] < '0' || text[i] > '9' || i >= 3) {
      return 0;
    }
    value = value * 10 + (text[i] - '0');
  }
  if (value < 1 || value > HILDE_TASK_MAX_WORKERS) {
    return 0;
  }
  return value;
}

/* How many workers: HILDE_TASK_THREADS when it is set, not empty and a
   number from 1 to HILDE_TASK_MAX_WORKERS, else the processors the system
   reports online, at most HILDE_TASK_MAX_WORKERS and at least 1.  A value
   that is not such a number is ignored, and one line on standard error says
   so: the variable comes from outside the programme, which cannot catch a
   stop in the runtime, and bending the value into range would hide the
   mistake. */
static int hilde_task_count_workers(void) {
  extern char* getenv(const char* name);
  const char* text = getenv("HILDE_TASK_THREADS");
  long online;

  if (text != NULL && text[0] != '\0') {
    int value = hilde_task_threads_value(text);

    if (value > 0) {
      return value;
    }
    {
      static const char warning[] =
        "Hilde: HILDE_TASK_THREADS is not a number from 1 to 64 and is ignored\n";
      ssize_t written = write(2, warning, sizeof(warning) - 1);

      (void) written;
    }
  }
  online = sysconf(_SC_NPROCESSORS_ONLN);
  if (online < 1) {
    return 1;
  }
  if (online > HILDE_TASK_MAX_WORKERS) {
    return HILDE_TASK_MAX_WORKERS;
  }
  return (int) online;
}

/* A stack of stack bytes with the guard pages below it. */
static void* hilde_task_map_stack(size_t stack, size_t* mapped_out) {
  size_t page = hilde_arena_page_size();
  size_t guard = HILDE_TASK_GUARD_PAGES * page;
  size_t mapped = stack + guard;
  int flags = MAP_PRIVATE | MAP_ANONYMOUS;
  unsigned char* mapping;

#if defined(__OpenBSD__)
  /* OpenBSD ends a process whose stack pointer is outside a MAP_STACK
     mapping at a system call or a fault, the documented rule of that
     kernel.  Without this flag no task could run there. */
  flags |= MAP_STACK;
#endif
  mapping = (unsigned char*) mmap(NULL, mapped, PROT_READ | PROT_WRITE,
                                  flags, -1, 0);
  if (mapping == MAP_FAILED) {
    return NULL;
  }
  /* The guard pages are the lowest pages: a stack grows down. */
  if (mprotect(mapping, guard, PROT_NONE) != 0) {
    munmap(mapping, mapped);
    return NULL;
  }
  *mapped_out = mapped;
  return mapping;
}

/* Lay out the first frame on a new stack, so that the first switch to it
   "returns" into the trampoline with the fiber in the register the
   trampoline reads.  The frame stands 16 bytes below the top, so that the
   trampoline starts with its stack pointer inside the mapping and not on
   its end: OpenBSD checks the stack pointer at every fault, and after a
   fork the first write to a page is one. */
static void* hilde_task_prepare_stack(hilde_task_fiber_t* fiber,
                                      unsigned char* top) {
  top -= 16;
#if defined(__aarch64__)
  uint64_t* frame = (uint64_t*) (top - 176);

  memset(frame, 0, 176);
  frame[0] = (uint64_t) (uintptr_t) fiber;                        /* x19 */
  frame[10] = 0;                                                  /* x29 */
  frame[11] = (uint64_t) (uintptr_t) &hilde_task_trampoline;      /* x30 */
  return (void*) frame;
#elif defined(__x86_64__)
  uint64_t* frame = (uint64_t*) (top - 64);

  memset(frame, 0, 64);
  /* The control words are copied from the running thread rather than
     written down: they are whatever this programme runs with. */
  __asm__ volatile ("stmxcsr %0" : "=m" (*(uint32_t*) frame));
  __asm__ volatile ("fnstcw %0" : "=m" (*(uint16_t*) ((unsigned char*) frame + 4)));
  frame[4] = (uint64_t) (uintptr_t) fiber;                        /* r12 */
  frame[7] = (uint64_t) (uintptr_t) &hilde_task_trampoline;       /* ret */
  return (void*) frame;
#endif
}

static void hilde_task_run_worker(hilde_task_worker_t* worker);

/* Worker 0's own stack runs this; its fiber record exists only so that the
   trampoline has something to hand to hilde_task_start. */
static hilde_unit_t hilde_task_home0_entry(uint8_t* unused) {
  (void) unused;
  hilde_task_run_worker(&hilde_task_workers[0]);
  return nil;
}

/* Once, on the thread the process started on, at its first use of any task
   function: the interrupt pipe, the key table, worker 0 and its stack.  No
   other thread exists yet, so nothing here races.  1 when the runtime is
   ready.  0 when the interrupt pipe cannot be made, which happens when the
   process has used up its descriptors: that is a state its input can bring
   about, so it is an answer and not a stop.  The pipe comes first and
   nothing else is changed before it, so a later call tries again from the
   start. */
static int hilde_task_initialise(void) {
  hilde_task_worker_t* zero = &hilde_task_workers[0];
  size_t mapped = 0;
  unsigned char* mapping;
  int i;

  if (hilde_task_initialised) {
    return 1;
  }
  if (hilde_pipe_open(hilde_task_interrupt) == 0) {
    return 0;
  }
  if (fcntl(hilde_task_interrupt[0], F_SETFL, O_NONBLOCK) != 0 ||
      fcntl(hilde_task_interrupt[1], F_SETFL, O_NONBLOCK) != 0) {
    close(hilde_task_interrupt[0]);
    close(hilde_task_interrupt[1]);
    hilde_task_interrupt[0] = -1;
    hilde_task_interrupt[1] = -1;
    return 0;
  }
  for (i = 0; i < HILDE_TASK_BUCKETS; i++) {
    if (pthread_mutex_init(&hilde_task_buckets[i].lock, NULL) != 0) {
      hilde_task_die("Hilde: the task runtime could not be set up");
    }
    hilde_task_buckets[i].head = NULL;
  }
  for (i = 0; i < HILDE_TASK_MAX_WORKERS; i++) {
    hilde_task_worker_t* worker = &hilde_task_workers[i];

    if (pthread_mutex_init(&worker->lock, NULL) != 0 ||
        pthread_cond_init(&worker->wake, NULL) != 0) {
      hilde_task_die("Hilde: the task runtime could not be set up");
    }
    worker->index = i;
  }
  if (pthread_mutex_init(&hilde_task_main.lock, NULL) != 0) {
    hilde_task_die("Hilde: the task runtime could not be set up");
  }
  hilde_task_main.state = HILDE_TASK_RUNNING;
  hilde_task_main.pinned = 1;
  hilde_task_main.wait_fd = -1;
#if defined(HILDE_TSAN)
  hilde_task_main.tsan = __tsan_get_current_fiber();
#endif
  mapping = (unsigned char*) hilde_task_map_stack(HILDE_TASK_STACK, &mapped);
  if (mapping == NULL) {
    hilde_task_die("Hilde: the task runtime could not map a stack for its first worker");
  }
  hilde_task_home0.mapping = mapping;
  hilde_task_home0.mapped = mapped;
  hilde_task_home0.stack = HILDE_TASK_STACK;
  hilde_task_home0.entry = hilde_task_home0_entry;
  zero->home = hilde_task_prepare_stack(&hilde_task_home0, mapping + mapped);
  hilde_task_note_home(zero, mapping + (mapped - HILDE_TASK_STACK), HILDE_TASK_STACK);
  hilde_task_register_stack(&hilde_task_home0);
#if defined(HILDE_TSAN)
  zero->tsan = __tsan_create_fiber(0);
#endif
  zero->current = &hilde_task_main;
  /* main runs on worker 0 from the start, without the worker loop that
     marks a fiber it runs. */
  __atomic_store_n(&zero->busy, 1, __ATOMIC_RELEASE);
  __atomic_store_n(&zero->runs, 1, __ATOMIC_RELEASE);
  hilde_task_wanted = hilde_task_count_workers();
  hilde_task_worker_of_thread = zero;
  hilde_task_initialised = 1;
  return 1;
}

/* Whether the runtime can be used by the calling thread, setting it up at
   the first call.  The scheduler makes the thread that first uses a task
   worker 0 and runs main on its stack, which a library, called from the
   host's threads, cannot give it: there a task function is a mistake of the
   programme, which tasksAvailable answers beforehand. */
static int hilde_task_ready(void) {
  if (HILDE_IN_LIBRARY) {
    hilde_task_die("Hilde: tasks are not available in a library");
  }
  return hilde_task_initialise();
}

/* The fiber running on the calling thread.  Only called once the runtime is
   set up: every path that can come first -- opening a scope, yielding,
   waiting for a descriptor -- asks hilde_task_ready and answers without the
   runtime when it is not. */
static hilde_task_fiber_t* hilde_task_self(void) {
  if (!hilde_task_ready()) {
    hilde_task_die("Hilde: the task runtime could not make its interrupt pipe");
  }
  return hilde_task_here()->current;
}

static int hilde_task_started_count(void) {
  return __atomic_load_n(&hilde_task_started, __ATOMIC_ACQUIRE);
}

/* With the idle lock held: wake one sleeping worker.  1 when there was one.
   The woken worker counts as awake from here on: it can clear the mark only
   once it has the idle lock, which the caller holds, so a second call made
   before that would signal the same worker again and leave the next
   sleeper asleep while a fiber waits in a queue. */
static int hilde_task_signal_sleeper(void) {
  int n = hilde_task_started_count();
  int i;

  for (i = 0; i < n; i++) {
    if (hilde_task_workers[i].asleep) {
      hilde_task_workers[i].asleep = 0;
      pthread_cond_signal(&hilde_task_workers[i].wake);
      return 1;
    }
  }
  return 0;
}

/* With the idle lock held: bring the worker in poll(2) back.  Best effort:
   a full pipe already holds an interruption. */
static void hilde_task_interrupt_poller(void) {
  ssize_t written = write(hilde_task_interrupt[1], "!", 1);

  (void) written;
}

#define HILDE_TASK_NOTIFY_RUNNABLE 0  /* a fiber any worker may run */
#define HILDE_TASK_NOTIFY_MAIN 1      /* main, which only worker 0 runs */
#define HILDE_TASK_NOTIFY_FD 2        /* a fiber now waits for a descriptor */
#define HILDE_TASK_NOTIFY_TIMER 3     /* a fiber now waits until a time */

/* Something changed that an idle worker has to act on.  A runnable fiber
   wakes a sleeping worker, or the one in poll(2) when none sleeps; main
   wakes worker 0 and nobody else; a new descriptor to wait for interrupts
   the worker in poll(2), whose set it is not in, or wakes a sleeper to
   become the one that polls. */
static void hilde_task_notify(int what) {
  __atomic_add_fetch(&hilde_task_generation, 1, __ATOMIC_SEQ_CST);
  if (__atomic_load_n(&hilde_task_idle, __ATOMIC_SEQ_CST) == 0) {
    return;
  }
  hilde_task_lock(&hilde_task_idle_lock);
  if (what == HILDE_TASK_NOTIFY_MAIN) {
    if (hilde_task_workers[0].asleep) {
      hilde_task_workers[0].asleep = 0;
      pthread_cond_signal(&hilde_task_workers[0].wake);
    } else if (hilde_task_polling) {
      hilde_task_interrupt_poller();
    }
  } else if (what == HILDE_TASK_NOTIFY_FD || what == HILDE_TASK_NOTIFY_TIMER) {
    if (hilde_task_polling) {
      hilde_task_interrupt_poller();
    } else {
      (void) hilde_task_signal_sleeper();
    }
  } else {
    if (!hilde_task_signal_sleeper() && hilde_task_polling) {
      hilde_task_interrupt_poller();
    }
  }
  hilde_task_unlock(&hilde_task_idle_lock);
}

/* Queue a runnable fiber at the end of a queue: main at the end of worker
   0's, every other at the end of the calling thread's own, where it runs on
   this thread in its turn unless an idle worker takes it first.  main goes
   to the end too and not into a slot of its own, so that on one worker the
   order is one plain first-in-first-out queue.  No field of the fiber is
   read once the worker's lock is let go: another worker can take it from
   the queue at once, run it to its end, and its joiner free it. */
static void hilde_task_push(hilde_task_fiber_t* fiber) {
  hilde_task_worker_t* worker;
  int pinned = fiber->pinned;

  worker = pinned ? &hilde_task_workers[0] : hilde_task_here();
  if (worker == NULL) {
    /* Made runnable by a helper thread, which is no worker. */
    worker = &hilde_task_workers[0];
  }
  fiber->next = NULL;
  hilde_task_lock(&worker->lock);
  if (worker->tail == NULL) {
    worker->head = fiber;
  } else {
    worker->tail->next = fiber;
  }
  worker->tail = fiber;
  if (pinned) {
    worker->main_queued = 1;
  }
  hilde_task_unlock(&worker->lock);
  hilde_task_notify(pinned ? HILDE_TASK_NOTIFY_MAIN : HILDE_TASK_NOTIFY_RUNNABLE);
}

/* With the worker's lock held: take the first fiber of its queue that the
   caller may run -- any when thief is 0, the worker itself, and anything
   but main when thief is 1, another worker.  NULL when there is none. */
static hilde_task_fiber_t* hilde_task_unqueue(hilde_task_worker_t* worker,
                                              int thief) {
  hilde_task_fiber_t* before = NULL;
  hilde_task_fiber_t* fiber = worker->head;

  while (fiber != NULL && thief && fiber->pinned) {
    before = fiber;
    fiber = fiber->next;
  }
  if (fiber == NULL) {
    return NULL;
  }
  if (before == NULL) {
    worker->head = fiber->next;
  } else {
    before->next = fiber->next;
  }
  if (worker->tail == fiber) {
    worker->tail = before;
  }
  if (fiber->pinned) {
    worker->main_queued = 0;
  }
  fiber->next = NULL;
  return fiber;
}

/* The waker's half of the meeting on the park field.  The fiber has been
   taken out of whatever list it waited in.  If it has not finished leaving
   yet, the
   worker it is leaving will queue it; otherwise it is queued here. */
static void hilde_task_make_ready(hilde_task_fiber_t* fiber) {
  int expected = HILDE_TASK_PARK_LEAVING;

  if (__atomic_compare_exchange_n(&fiber->park, &expected,
                                  HILDE_TASK_PARK_WOKEN, 0,
                                  __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
    return;
  }
  if (expected != HILDE_TASK_PARK_PARKED) {
    hilde_task_die("Hilde: a task was woken that was not waiting");
  }
  __atomic_store_n(&fiber->park, HILDE_TASK_PARK_NONE, __ATOMIC_RELEASE);
  hilde_task_push(fiber);
}

static hilde_task_bucket_t* hilde_task_bucket(const void* key) {
  uintptr_t value = (uintptr_t) key;

  return &hilde_task_buckets[(value >> 4) % HILDE_TASK_BUCKETS];
}

/* Wake every fiber parked on key.  The caller holds the lock that guards
   the condition those fibers wait for, which is what makes the wake find
   every one of them (see hilde_task_park).  Before the runtime is set up no
   fiber can be parked, and the bucket locks are not made yet: a zeroed
   mutex is an unlocked one on Linux and the BSDs, but not on macOS. */
static void hilde_task_wake_key(const void* key) {
  hilde_task_bucket_t* bucket = hilde_task_bucket(key);
  hilde_task_fiber_t* woken = NULL;
  hilde_task_fiber_t** at;

  if (!hilde_task_initialised) {
    return;
  }
  hilde_task_lock(&bucket->lock);
  at = &bucket->head;
  while (*at != NULL) {
    hilde_task_fiber_t* fiber = *at;

    if (fiber->wait_key == key) {
      *at = fiber->next;
      fiber->next = woken;
      woken = fiber;
    } else {
      at = &fiber->next;
    }
  }
  hilde_task_unlock(&bucket->lock);
  while (woken != NULL) {
    hilde_task_fiber_t* fiber = woken;

    woken = fiber->next;
    fiber->next = NULL;
    fiber->wait_key = NULL;
    hilde_task_make_ready(fiber);
  }
}

/* Put fiber into the timer list, which is ordered by the time each waits
   until; a fiber that waits until the same time as another comes after
   it. */
static void hilde_task_timer_insert(hilde_task_fiber_t* fiber, int64_t deadline) {
  hilde_task_fiber_t** at;

  fiber->deadline = deadline;
  hilde_task_lock(&hilde_task_timer_lock);
  at = &hilde_task_timer_head;
  while (*at != NULL && (*at)->deadline <= deadline) {
    at = &(*at)->timer_next;
  }
  fiber->timer_next = *at;
  *at = fiber;
  __atomic_add_fetch(&hilde_task_timer_count, 1, __ATOMIC_SEQ_CST);
  hilde_task_unlock(&hilde_task_timer_lock);
}

/* Take fiber out of the timer list; nothing when its time came and it was
   taken out already. */
static void hilde_task_timer_cancel(hilde_task_fiber_t* fiber) {
  hilde_task_fiber_t** at;

  hilde_task_lock(&hilde_task_timer_lock);
  at = &hilde_task_timer_head;
  while (*at != NULL && *at != fiber) {
    at = &(*at)->timer_next;
  }
  if (*at != NULL) {
    *at = fiber->timer_next;
    fiber->timer_next = NULL;
    __atomic_sub_fetch(&hilde_task_timer_count, 1, __ATOMIC_SEQ_CST);
  }
  hilde_task_unlock(&hilde_task_timer_lock);
}

/* Take fiber out of the list of key and make it runnable -- nothing when a
   wake of the key took it out first and made it runnable already. */
static void hilde_task_unpark(hilde_task_fiber_t* fiber, const void* key) {
  hilde_task_bucket_t* bucket = hilde_task_bucket(key);
  hilde_task_fiber_t** at;
  int found = 0;

  hilde_task_lock(&bucket->lock);
  at = &bucket->head;
  while (*at != NULL) {
    if (*at == fiber) {
      *at = fiber->next;
      found = 1;
      break;
    }
    at = &(*at)->next;
  }
  hilde_task_unlock(&bucket->lock);
  if (found) {
    fiber->next = NULL;
    fiber->wait_key = NULL;
    hilde_task_make_ready(fiber);
  }
}

/* Make runnable every fiber whose time has come.  A fiber taken out of the
   timer list here is the one fiber that can still wake it, besides a wake
   of its key: whichever takes it out of the key's list first does.

   The due fibers are taken one at a time under the lock and each is woken
   before the next is taken, with its key read under the lock.  No field of
   a fiber is read after the lock is let go: a wake of its key can run it
   on another worker at once, and a fiber that parks again with a deadline
   writes timer_next and timer_key while it goes back into the list.  A
   list of the due fibers chained through timer_next would then lead into
   the live timer list and break it, and later deadlines would not fire. */
static void hilde_task_fire_timers(void) {
  int64_t now;

  if (__atomic_load_n(&hilde_task_timer_count, __ATOMIC_SEQ_CST) == 0) {
    return;
  }
  now = hilde_task_now();
  for (;;) {
    hilde_task_fiber_t* fiber;
    const void* key;

    hilde_task_lock(&hilde_task_timer_lock);
    fiber = hilde_task_timer_head;
    if (fiber == NULL || fiber->deadline > now) {
      hilde_task_unlock(&hilde_task_timer_lock);
      return;
    }
    hilde_task_timer_head = fiber->timer_next;
    fiber->timer_next = NULL;
    key = fiber->timer_key;
    __atomic_sub_fetch(&hilde_task_timer_count, 1, __ATOMIC_SEQ_CST);
    hilde_task_unlock(&hilde_task_timer_lock);
    hilde_task_unpark(fiber, key);
  }
}

/* The time the earliest timer waits until, or -1 when none waits. */
static int64_t hilde_task_next_deadline(void) {
  int64_t deadline = -1;

  if (__atomic_load_n(&hilde_task_timer_count, __ATOMIC_SEQ_CST) == 0) {
    return -1;
  }
  hilde_task_lock(&hilde_task_timer_lock);
  if (hilde_task_timer_head != NULL) {
    deadline = hilde_task_timer_head->deadline;
  }
  hilde_task_unlock(&hilde_task_timer_lock);
  return deadline;
}

/* Leave the running fiber and go back to the worker, which does what after
   names once the fiber's registers are saved.  Returns when the fiber runs
   again -- on this thread or another, so nothing read from the thread
   before the switch is used after it. */
static void hilde_task_leave(int after) {
  hilde_task_worker_t* worker = hilde_task_here();
  hilde_task_fiber_t* self = worker->current;
  const void* came_bottom = NULL;
  size_t came_size = 0;

  worker->after = after;
  worker->leaving = self;
  hilde_task_jump(&self->sp, worker->home, HILDE_TASK_TSAN_OF(worker),
                  HILDE_TASK_ASAN_BOTTOM(worker), HILDE_TASK_ASAN_SIZE(worker),
                  after == HILDE_TASK_AFTER_DONE ? NULL : &came_bottom,
                  &came_size);
#if defined(HILDE_ASAN)
  /* Running again, perhaps on another thread: the stack that switched back
     is the own stack of the worker this fiber runs on now. */
  hilde_task_note_home(hilde_task_here(), came_bottom, came_size);
#endif
}

/* Park the running fiber on key.  The caller holds lock, the lock that
   guards what the fiber waits for, and has just seen that it must wait.
   The fiber goes into the key's list first and the lock is let go after:
   whoever changes the condition takes the same lock, so it can only wake
   after the fiber is findable.  Returns with the lock not held. */
static void hilde_task_park(const void* key, pthread_mutex_t* lock) {
  hilde_task_fiber_t* self = hilde_task_self();
  hilde_task_bucket_t* bucket = hilde_task_bucket(key);

  __atomic_store_n(&self->park, HILDE_TASK_PARK_LEAVING, __ATOMIC_RELEASE);
  self->wait_key = key;
  hilde_task_lock(&bucket->lock);
  self->next = bucket->head;
  bucket->head = self;
  hilde_task_unlock(&bucket->lock);
  hilde_task_unlock(lock);
  hilde_task_leave(HILDE_TASK_AFTER_PARK);
}

/* Park the running fiber on key while the caller holds two locks, as
   hilde_task_park does with one: the fiber goes into the key's list before
   either lock is let go.  A wait on two channels holds the locks of both. */
static void hilde_task_park2(const void* key, pthread_mutex_t* first, pthread_mutex_t* second) {
  hilde_task_fiber_t* self = hilde_task_self();
  hilde_task_bucket_t* bucket = hilde_task_bucket(key);

  __atomic_store_n(&self->park, HILDE_TASK_PARK_LEAVING, __ATOMIC_RELEASE);
  self->wait_key = key;
  hilde_task_lock(&bucket->lock);
  self->next = bucket->head;
  bucket->head = self;
  hilde_task_unlock(&bucket->lock);
  hilde_task_unlock(first);
  hilde_task_unlock(second);
  hilde_task_leave(HILDE_TASK_AFTER_PARK);
}

/* Park the running fiber on key as hilde_task_park does, and until
   deadline at the latest: then a worker takes it out of the key's list and
   makes it runnable.  The fiber is in the key's list before it is in the
   timer list, so that a timer that fires at once finds it there.  Returns
   with the lock not held; the caller looks at the time to tell a wake
   from the end of the wait. */
static void hilde_task_park_until(const void* key, pthread_mutex_t* lock, int64_t deadline) {
  hilde_task_fiber_t* self = hilde_task_self();
  hilde_task_bucket_t* bucket = hilde_task_bucket(key);

  __atomic_store_n(&self->park, HILDE_TASK_PARK_LEAVING, __ATOMIC_RELEASE);
  self->wait_key = key;
  self->timer_key = key;
  hilde_task_lock(&bucket->lock);
  self->next = bucket->head;
  bucket->head = self;
  hilde_task_unlock(&bucket->lock);
  hilde_task_timer_insert(self, deadline);
  hilde_task_unlock(lock);
  /* An idle worker waits only until the earliest time it knew of. */
  hilde_task_notify(HILDE_TASK_NOTIFY_TIMER);
  hilde_task_leave(HILDE_TASK_AFTER_PARK);
  /* Woken by the key before its time: the timer goes. */
  hilde_task_timer_cancel(hilde_task_self());
}

/* Take a runnable fiber for worker: the first of its own queue, else the
   first another worker's queue holds that is not main. */
static hilde_task_fiber_t* hilde_task_take(hilde_task_worker_t* worker) {
  hilde_task_fiber_t* fiber;
  int n = hilde_task_started_count();
  int k;

  hilde_task_lock(&worker->lock);
  fiber = hilde_task_unqueue(worker, 0);
  hilde_task_unlock(&worker->lock);
  if (fiber != NULL) {
    return fiber;
  }
  for (k = 1; k < n; k++) {
    hilde_task_worker_t* other = &hilde_task_workers[(worker->index + k) % n];

    hilde_task_lock(&other->lock);
    fiber = hilde_task_unqueue(other, 1);
    hilde_task_unlock(&other->lock);
    if (fiber != NULL) {
      return fiber;
    }
  }
  return NULL;
}

/* Wait in poll(2) for every fiber parked on a descriptor and for the
   interrupt pipe, then make runnable the fibers whose descriptor answered.
   One worker at a time does this; the others sleep. */
static void hilde_task_poll(void) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  struct pollfd* fds;
  hilde_task_fiber_t** who;
  hilde_task_fiber_t* fiber;
  hilde_task_fiber_t* woken = NULL;
  size_t count;
  size_t at;
  int rc;

  hilde_task_lock(&hilde_task_fd_lock);
  count = __atomic_load_n(&hilde_task_fd_count, __ATOMIC_SEQ_CST);
  fds = (struct pollfd*) calloc(count + 1, sizeof(struct pollfd));
  who = (hilde_task_fiber_t**) calloc(count + 1, sizeof(hilde_task_fiber_t*));
  if (fds == NULL || who == NULL) {
    hilde_task_die("Hilde: out of memory while tasks wait for input or output");
  }
  fds[0].fd = hilde_task_interrupt[0];
  fds[0].events = POLLIN;
  at = 1;
  for (fiber = hilde_task_fd_head; fiber != NULL; fiber = fiber->next) {
    fds[at].fd = fiber->wait_fd;
    fds[at].events = fiber->wait_events;
    who[at] = fiber;
    at++;
  }
  hilde_task_unlock(&hilde_task_fd_lock);
  do {
    int64_t deadline = hilde_task_next_deadline();

    rc = poll(fds, (nfds_t) (count + 1), (deadline < 0) ? -1 : hilde_task_poll_millis(deadline));
  } while (rc < 0 && errno == EINTR);
  if (rc < 0) {
    hilde_task_die("Hilde: poll failed while tasks wait for input or output");
  }
  if (fds[0].revents != 0) {
    char drain[64];

    while (read(hilde_task_interrupt[0], drain, sizeof(drain)) > 0) {
    }
  }
  /* Only this function takes a fiber out of the descriptor list, and one
     worker at a time runs it, so every fiber in who is still there. */
  hilde_task_lock(&hilde_task_fd_lock);
  for (at = 1; at <= count; at++) {
    if (fds[at].revents != 0) {
      hilde_task_fiber_t** link = &hilde_task_fd_head;

      while (*link != who[at]) {
        link = &(*link)->next;
      }
      *link = who[at]->next;
      __atomic_sub_fetch(&hilde_task_fd_count, 1, __ATOMIC_SEQ_CST);
      who[at]->got_events = fds[at].revents;
      who[at]->next = woken;
      woken = who[at];
    }
  }
  hilde_task_unlock(&hilde_task_fd_lock);
  free(fds);
  free(who);
  while (woken != NULL) {
    fiber = woken;
    woken = fiber->next;
    fiber->next = NULL;
    hilde_task_make_ready(fiber);
  }
}

/* Whether main waits in worker 0's queue.  Only worker 0 takes it from
   there, so another worker's own look at the queues does not see it -- and
   worker 0 counts as idle from the moment it went to sleep until it has
   woken and taken the lock again, which is exactly when a worker that did
   not look here would call the programme deadlocked. */
static int hilde_task_main_is_runnable(void) {
  int waiting;

  hilde_task_lock(&hilde_task_workers[0].lock);
  waiting = hilde_task_workers[0].main_queued;
  hilde_task_unlock(&hilde_task_workers[0].lock);
  return waiting;
}

/* A runnable fiber for worker, waiting for one when there is none.  This
   is also where a deadlock is recognised: the last worker to run out of
   work, with no fiber waiting for a descriptor, knows that nothing is left
   that could ever make a fiber runnable. */
static hilde_task_fiber_t* hilde_task_find(hilde_task_worker_t* worker) {
  for (;;) {
    hilde_task_fiber_t* fiber;
    unsigned long seen;

    hilde_task_fire_timers();
    fiber = hilde_task_take(worker);

    if (fiber != NULL) {
      return fiber;
    }
    hilde_task_lock(&hilde_task_idle_lock);
    seen = __atomic_load_n(&hilde_task_generation, __ATOMIC_SEQ_CST);
    fiber = hilde_task_take(worker);
    if (fiber != NULL) {
      hilde_task_unlock(&hilde_task_idle_lock);
      return fiber;
    }
    __atomic_add_fetch(&hilde_task_idle, 1, __ATOMIC_SEQ_CST);
    if (!hilde_task_polling &&
        __atomic_load_n(&hilde_task_fd_count, __ATOMIC_SEQ_CST) > 0) {
      hilde_task_polling = 1;
      hilde_task_unlock(&hilde_task_idle_lock);
      hilde_task_poll();
      hilde_task_lock(&hilde_task_idle_lock);
      hilde_task_polling = 0;
      __atomic_sub_fetch(&hilde_task_idle, 1, __ATOMIC_SEQ_CST);
      /* This worker goes back to running fibers.  If descriptors are still
         waited for, a sleeping worker takes over the polling, or they would
         wait until this worker runs out of work again. */
      if (__atomic_load_n(&hilde_task_fd_count, __ATOMIC_SEQ_CST) > 0) {
        (void) hilde_task_signal_sleeper();
      }
      hilde_task_unlock(&hilde_task_idle_lock);
      continue;
    }
    if (!hilde_task_polling &&
        __atomic_load_n(&hilde_task_idle, __ATOMIC_SEQ_CST) ==
          hilde_task_started_count() &&
        __atomic_load_n(&hilde_task_timer_count, __ATOMIC_SEQ_CST) == 0 &&
        __atomic_load_n(&hilde_task_calls, __ATOMIC_SEQ_CST) == 0 &&
        !hilde_task_main_is_runnable()) {
      hilde_task_die("Hilde: deadlock -- every task is waiting, and nothing is left that could wake one");
    }
    while (__atomic_load_n(&hilde_task_generation, __ATOMIC_SEQ_CST) == seen &&
           !(!hilde_task_polling &&
             __atomic_load_n(&hilde_task_fd_count, __ATOMIC_SEQ_CST) > 0)) {
      int64_t deadline = hilde_task_next_deadline();

      /* Marked again on every round: a waker clears the mark when it
         signals, and a worker woken with nothing changed sleeps on. */
      worker->asleep = 1;
      if (deadline < 0) {
        if (pthread_cond_wait(&worker->wake, &hilde_task_idle_lock) != 0) {
          hilde_task_die("Hilde: a lock of the task runtime failed");
        }
      } else {
        /* The condition's clock is the wall clock: the time left on the
           timers' clock is added to it. */
        struct timespec until;
        int64_t left = deadline - hilde_task_now();
        int rc;

        if (left <= 0) {
          break;
        }
        if (timespec_get(&until, TIME_UTC) == 0) {
          hilde_task_die("Hilde: the clock could not be read");
        }
        left += (int64_t) until.tv_nsec;
        until.tv_sec += (time_t) (left / 1000000000);
        until.tv_nsec = (long) (left % 1000000000);
        rc = pthread_cond_timedwait(&worker->wake, &hilde_task_idle_lock, &until);
        if (rc == ETIMEDOUT) {
          break;
        }
        if (rc != 0) {
          hilde_task_die("Hilde: a lock of the task runtime failed");
        }
      }
    }
    worker->asleep = 0;
    __atomic_sub_fetch(&hilde_task_idle, 1, __ATOMIC_SEQ_CST);
    hilde_task_unlock(&hilde_task_idle_lock);
  }
}

/* A fiber has ended; this runs on its worker's own stack.  Whoever joins it
   hears of it first, then its scope; this order decides who runs first on
   one worker.  The scope is read before the fiber is
   marked done, because after that unlock the joiner may give the fiber
   back; the scope cannot go away before its count is lowered here. */
static void hilde_task_finished(hilde_task_fiber_t* fiber) {
  hilde_task_scope_t* scope = fiber->scope;

  hilde_task_lock(&fiber->lock);
  fiber->state = HILDE_TASK_DONE;
  hilde_task_wake_key(fiber);
  hilde_task_unlock(&fiber->lock);
  hilde_task_lock(&scope->lock);
  scope->live--;
  /* Every end, not only the last: hilde_task_scope_wait_below waits for
     fewer tasks, close for none, and both look at the count again. */
  hilde_task_wake_key(scope);
  hilde_task_unlock(&scope->lock);
}

/* Do what the fiber that just left this worker left for.  Nothing when no
   fiber left -- a new worker thread's first round. */
static void hilde_task_after_leaving(hilde_task_worker_t* worker) {
  hilde_task_fiber_t* left = worker->leaving;
  int after = worker->after;

  worker->current = NULL;
  worker->leaving = NULL;
  worker->after = 0;
  if (after == HILDE_TASK_AFTER_READY) {
    hilde_task_push(left);
  } else if (after == HILDE_TASK_AFTER_DONE) {
    hilde_task_finished(left);
  } else if (after == HILDE_TASK_AFTER_PARK) {
    int expected = HILDE_TASK_PARK_LEAVING;

    if (!__atomic_compare_exchange_n(&left->park, &expected,
                                     HILDE_TASK_PARK_PARKED, 0,
                                     __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
      /* Woken while it was still leaving: queue it now. */
      __atomic_store_n(&left->park, HILDE_TASK_PARK_NONE, __ATOMIC_RELEASE);
      hilde_task_push(left);
    }
  }
}

/* Preemption.  A task runs until it waits, yields or ends; one that
   computes for long would keep the others of its worker from running.  A
   monitor thread, started with the first task, looks at every worker every
   10 milliseconds, and asks a worker that has run the same fiber since its
   last look to let the others run.  The fiber does so at the next head of
   a loop, where the compiler writes HILDE_PREEMPT_POINT: one load of the
   count below while nothing is asked, and a yield when its worker is. */
static int hilde_task_preempt_pending = 0;     /* workers asked, atomic */
static int hilde_task_monitor_started = 0;     /* atomic */

#define HILDE_PREEMPT_POINT() \
  do { \
    if (__builtin_expect(__atomic_load_n(&hilde_task_preempt_pending, __ATOMIC_RELAXED) != 0, 0)) { \
      hilde_task_preempt_check(); \
    } \
  } while (0)

/* A loop head while some worker is asked: the fiber yields when it is its
   own worker. */
static void hilde_task_preempt_check(void) {
  hilde_task_worker_t* worker = hilde_task_here();

  if (worker == NULL || worker->current == NULL) {
    return;
  }
  if (__atomic_exchange_n(&worker->preempt, 0, __ATOMIC_ACQ_REL) == 0) {
    return;
  }
  __atomic_sub_fetch(&hilde_task_preempt_pending, 1, __ATOMIC_ACQ_REL);
  hilde_task_leave(HILDE_TASK_AFTER_READY);
}

/* The monitor: every 10 milliseconds, a worker that has run one fiber
   since the last look is asked to let the others run.  It runs as long as
   the process does, as the workers do. */
static void* hilde_task_monitor(void* unused) {
  unsigned long seen[HILDE_TASK_MAX_WORKERS];
  int i;

  (void) unused;
  for (i = 0; i < HILDE_TASK_MAX_WORKERS; i++) {
    seen[i] = 0;
  }
  for (;;) {
    int n;

    (void) poll(NULL, 0, 10);
    n = hilde_task_started_count();
    for (i = 0; i < n; i++) {
      hilde_task_worker_t* worker = &hilde_task_workers[i];
      unsigned long runs = __atomic_load_n(&worker->runs, __ATOMIC_ACQUIRE);

      if (__atomic_load_n(&worker->busy, __ATOMIC_ACQUIRE) && runs == seen[i] &&
          __atomic_load_n(&worker->preempt, __ATOMIC_ACQUIRE) == 0) {
        __atomic_store_n(&worker->preempt, 1, __ATOMIC_RELEASE);
        __atomic_add_fetch(&hilde_task_preempt_pending, 1, __ATOMIC_ACQ_REL);
      }
      seen[i] = runs;
    }
  }
  return NULL;
}

/* Start the monitor, once, at the first spawn.  A monitor that cannot be
   started is not there: tasks then run until they wait, as before. */
static void hilde_task_start_monitor(void) {
  pthread_t thread;
  int expected = 0;

  if (!__atomic_compare_exchange_n(&hilde_task_monitor_started, &expected, 1, 0,
                                   __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
    return;
  }
  if (pthread_create(&thread, NULL, hilde_task_monitor, NULL) == 0) {
    (void) pthread_detach(thread);
  }
}

/* Blocking calls.  A call that may block for long -- a child to end, a
   name to resolve -- would hold its worker and every task queued there.
   Once a task has been started, such a call runs on a helper thread while
   its task waits, and the worker runs the others meanwhile.  Helpers are
   started as calls need them, at most HILDE_TASK_MAX_HELPERS, and stay;
   when none can be had, the call runs where it was made.  Before the first
   task, and in a library, it runs where it was made: there is nothing else
   to run.  A call counts as something that can still wake a task, so a
   programme whose tasks all wait for one is not a deadlock. */
#define HILDE_TASK_MAX_HELPERS 16

typedef struct hilde_task_call {
  void (*fn)(void*);
  void* arg;
  int done;                        /* under hilde_task_call_lock */
  struct hilde_task_call* next;
} hilde_task_call_t;

static pthread_mutex_t hilde_task_call_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t hilde_task_call_ready = PTHREAD_COND_INITIALIZER;
static hilde_task_call_t* hilde_task_call_head = NULL;
static hilde_task_call_t* hilde_task_call_tail = NULL;
static int hilde_task_helpers = 0;       /* under hilde_task_call_lock */
static int hilde_task_helpers_idle = 0;  /* under hilde_task_call_lock */

static void* hilde_task_helper(void* unused) {
  (void) unused;
  for (;;) {
    hilde_task_call_t* call;

    hilde_task_lock(&hilde_task_call_lock);
    while (hilde_task_call_head == NULL) {
      hilde_task_helpers_idle++;
      if (pthread_cond_wait(&hilde_task_call_ready, &hilde_task_call_lock) != 0) {
        hilde_task_die("Hilde: a lock of the task runtime failed");
      }
      hilde_task_helpers_idle--;
    }
    call = hilde_task_call_head;
    hilde_task_call_head = call->next;
    if (hilde_task_call_head == NULL) {
      hilde_task_call_tail = NULL;
    }
    hilde_task_unlock(&hilde_task_call_lock);
    call->fn(call->arg);
    hilde_task_lock(&hilde_task_call_lock);
    call->done = 1;
    hilde_task_wake_key(call);
    hilde_task_unlock(&hilde_task_call_lock);
  }
  return NULL;
}

static void hilde_task_blocking(void (*fn)(void*), void* arg) {
  hilde_task_call_t call;

  if (HILDE_IN_LIBRARY ||
      __atomic_load_n(&hilde_task_monitor_started, __ATOMIC_ACQUIRE) == 0 ||
      !hilde_task_ready()) {
    fn(arg);
    return;
  }
  call.fn = fn;
  call.arg = arg;
  call.done = 0;
  call.next = NULL;
  hilde_task_lock(&hilde_task_call_lock);
  if (hilde_task_helpers_idle == 0 && hilde_task_helpers < HILDE_TASK_MAX_HELPERS) {
    pthread_t thread;

    if (pthread_create(&thread, NULL, hilde_task_helper, NULL) == 0) {
      (void) pthread_detach(thread);
      hilde_task_helpers++;
    }
  }
  if (hilde_task_helpers == 0) {
    hilde_task_unlock(&hilde_task_call_lock);
    fn(arg);
    return;
  }
  if (hilde_task_call_tail == NULL) {
    hilde_task_call_head = &call;
  } else {
    hilde_task_call_tail->next = &call;
  }
  hilde_task_call_tail = &call;
  __atomic_add_fetch(&hilde_task_calls, 1, __ATOMIC_SEQ_CST);
  (void) pthread_cond_signal(&hilde_task_call_ready);
  while (!call.done) {
    hilde_task_park(&call, &hilde_task_call_lock);
    hilde_task_lock(&hilde_task_call_lock);
  }
  hilde_task_unlock(&hilde_task_call_lock);
  __atomic_sub_fetch(&hilde_task_calls, 1, __ATOMIC_SEQ_CST);
}

/* What every worker runs on its own stack, forever: do what the last fiber
   left for, take a fiber, run it until it leaves.  The first step comes
   first because worker 0's stack is first entered when main leaves,
   through the trampoline and not through the switch below, and what main
   left for has to be done all the same. */
static void hilde_task_run_worker(hilde_task_worker_t* worker) {
  for (;;) {
    hilde_task_fiber_t* fiber;
    const void* came_bottom = NULL;
    size_t came_size = 0;

    hilde_task_after_leaving(worker);
    fiber = hilde_task_find(worker);
    worker->current = fiber;
    __atomic_add_fetch(&worker->runs, 1, __ATOMIC_ACQ_REL);
    __atomic_store_n(&worker->busy, 1, __ATOMIC_RELEASE);
    hilde_task_jump(&worker->home, fiber->sp, HILDE_TASK_TSAN_OF(fiber),
                    HILDE_TASK_ASAN_BOTTOM(fiber), HILDE_TASK_ASAN_SIZE(fiber),
                    &came_bottom, &came_size);
    __atomic_store_n(&hilde_task_here()->busy, 0, __ATOMIC_RELEASE);
    /* The stack that switched back is the fiber that left, which is not
       handed on before hilde_task_after_leaving above. */
    hilde_task_note_fiber(worker->leaving, came_bottom, came_size);
  }
}

static void* hilde_task_thread_main(void* raw) {
  hilde_task_worker_t* worker = (hilde_task_worker_t*) raw;

  hilde_task_worker_of_thread = worker;
#if defined(HILDE_TSAN)
  worker->tsan = __tsan_get_current_fiber();
#endif
  hilde_task_run_worker(worker);
  return NULL;
}

/* Start the other workers, once, at the first spawn.  A thread that cannot
   be started is not there: the runtime runs on the ones that did, at least
   worker 0. */
static void hilde_task_start_workers(void) {
  int i;
  int started = 1;

  if (hilde_task_started_count() > 1 || hilde_task_wanted <= 1) {
    return;
  }
  for (i = 1; i < hilde_task_wanted; i++) {
    hilde_task_worker_t* worker = &hilde_task_workers[i];

    /* Counted before its thread runs, so that no worker ever sees a count
       that leaves itself out. */
    hilde_task_lock(&hilde_task_idle_lock);
    __atomic_store_n(&hilde_task_started, started + 1, __ATOMIC_RELEASE);
    hilde_task_unlock(&hilde_task_idle_lock);
    if (pthread_create(&worker->thread, NULL, hilde_task_thread_main,
                       (void*) worker) != 0) {
      hilde_task_lock(&hilde_task_idle_lock);
      __atomic_store_n(&hilde_task_started, started, __ATOMIC_RELEASE);
      hilde_task_unlock(&hilde_task_idle_lock);
      break;
    }
    started++;
  }
}

/* The entry of a task is called through a pointer to a function taking one
   uint8_t*, whatever the pointer type of its own parameter: a conversion
   between function pointer types that ISO C does not bless and that both
   ABIs of this runtime make harmless.  clang's UndefinedBehaviorSanitizer
   reports such a call at run time, as gcc's never does; the one function
   that makes the call says it is meant. */
#if defined(__clang__)
#define HILDE_ENTRY_CALL __attribute__((no_sanitize("function")))
#else
#define HILDE_ENTRY_CALL
#endif

/* Where every task begins, on its own stack, reached through the
   trampoline.  It never returns: a finished task leaves for good, and its
   stack is given back by whoever joins it. */
HILDE_ENTRY_CALL void hilde_task_start(void* raw) {
  hilde_task_fiber_t* fiber = (hilde_task_fiber_t*) raw;
#if defined(HILDE_ASAN)
  const void* came_bottom = NULL;
  size_t came_size = 0;

  /* A new stack is entered through the trampoline and not through the
     return of a switch, so the switch is finished here.  Worker 0's own
     stack is first entered from the programme's stack, which is leaving;
     every other new stack from its worker's own. */
  __sanitizer_finish_switch_fiber(NULL, &came_bottom, &came_size);
  if (fiber == &hilde_task_home0) {
    hilde_task_note_fiber(hilde_task_workers[0].leaving, came_bottom, came_size);
  } else {
    hilde_task_note_home(hilde_task_here(), came_bottom, came_size);
  }
#endif

  fiber->entry(fiber->argument);
  hilde_task_leave(HILDE_TASK_AFTER_DONE);
  hilde_task_die("Hilde: a finished task was resumed");
}

/* Start a task in scope that will call entry(argument).  Returns the fiber,
   or NULL when its memory, its lock or its stack could not be had. */
void* hilde_task_spawn(void* scope, hilde_fnptr_t entry, uint8_t* argument) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_task_fiber_t* fiber;
  hilde_task_scope_t* into = (hilde_task_scope_t*) scope;
  size_t mapped = 0;
  unsigned char* mapping;

  (void) hilde_task_self();
  fiber = (hilde_task_fiber_t*) calloc(1, sizeof(hilde_task_fiber_t));
  if (fiber == NULL) {
    return NULL;
  }
  if (pthread_mutex_init(&fiber->lock, NULL) != 0) {
    free(fiber);
    return NULL;
  }
  mapping = (unsigned char*) hilde_task_map_stack(into->stack, &mapped);
  if (mapping == NULL) {
    pthread_mutex_destroy(&fiber->lock);
    free(fiber);
    return NULL;
  }
  fiber->mapping = mapping;
  fiber->mapped = mapped;
  fiber->stack = into->stack;
  fiber->entry = (hilde_unit_t (*)(uint8_t*)) entry;
  fiber->argument = argument;
  fiber->wait_fd = -1;
  fiber->scope = into;
  fiber->sp = hilde_task_prepare_stack(fiber, mapping + mapped);
  hilde_task_note_fiber(fiber, mapping + (mapped - fiber->stack), fiber->stack);
  hilde_task_register_stack(fiber);
#if defined(HILDE_TSAN)
  fiber->tsan = __tsan_create_fiber(0);
#endif
  hilde_task_lock(&into->lock);
  into->live++;
  hilde_task_unlock(&into->lock);
  hilde_task_start_workers();
  hilde_task_start_monitor();
  hilde_task_push(fiber);
  return (void*) fiber;
}

/* Wait until the task has ended, then give back its stack.  After this the
   fiber is gone; its result was stored by the task itself. */
hilde_unit_t hilde_task_join(void* raw) {
  extern void free(void* ptr);
  hilde_task_fiber_t* fiber = (hilde_task_fiber_t*) raw;

  (void) hilde_task_self();
  hilde_task_lock(&fiber->lock);
  while (fiber->state != HILDE_TASK_DONE) {
    hilde_task_park(fiber, &fiber->lock);
    hilde_task_lock(&fiber->lock);
  }
  hilde_task_unlock(&fiber->lock);
  pthread_mutex_destroy(&fiber->lock);
  hilde_task_deregister_stack(fiber);
  munmap(fiber->mapping, fiber->mapped);
#if defined(HILDE_TSAN)
  __tsan_destroy_fiber(fiber->tsan);
#endif
  free(fiber);
  return nil;
}

/* Without the runtime there is no other task to let run. */
hilde_unit_t hilde_task_yield(void) {
  if (!hilde_task_ready()) {
    return nil;
  }
  (void) hilde_task_self();
  hilde_task_leave(HILDE_TASK_AFTER_READY);
  return nil;
}

/* The running task waits nanos nanoseconds while others run: it parks on
   a key of its own, which nothing but its timer wakes.  0 or less lets the
   others run once, as a yield does.  Without the runtime the calling
   thread waits itself. */
hilde_unit_t hilde_task_sleep_ns(int64_t nanos) {
  hilde_task_fiber_t* self;
  int64_t deadline;

  if (nanos <= 0) {
    return hilde_task_yield();
  }
  if (!hilde_task_ready()) {
    hilde_task_sleep_alone(nanos);
    return nil;
  }
  self = hilde_task_self();
  deadline = hilde_task_now() + nanos;
  for (;;) {
    hilde_task_lock(&self->lock);
    hilde_task_park_until(&self->deadline, &self->lock, deadline);
    self = hilde_task_self();
    if (hilde_task_now() >= deadline) {
      return nil;
    }
  }
}

/* The wait of hilde_task_wait_fd when the runtime could not be set up: the
   calling thread waits in poll(2) itself, as on a platform without tasks. */
static int hilde_task_poll_alone(int fd, int what) {
  struct pollfd p;
  int rc;

  p.fd = fd;
  p.events = (what == 2) ? POLLOUT : POLLIN;
  p.revents = 0;
  do {
    rc = poll(&p, 1, -1);
  } while (rc < 0 && errno == EINTR);
  return hilde_task_poll_answer(rc, p.revents, what);
}

/* Park the running task until fd is ready for what (1 read, 2 write).
   1 when it is, 0 when it failed or hung up without being ready. */
int hilde_task_wait_fd(int fd, int what) {
  hilde_task_fiber_t* self;
  short want = (what == 2) ? POLLOUT : POLLIN;

  if (!hilde_task_ready()) {
    return hilde_task_poll_alone(fd, what);
  }
  self = hilde_task_self();

  self->wait_fd = fd;
  self->wait_events = want;
  self->got_events = 0;
  __atomic_store_n(&self->park, HILDE_TASK_PARK_LEAVING, __ATOMIC_RELEASE);
  hilde_task_lock(&hilde_task_fd_lock);
  self->next = hilde_task_fd_head;
  hilde_task_fd_head = self;
  __atomic_add_fetch(&hilde_task_fd_count, 1, __ATOMIC_SEQ_CST);
  hilde_task_unlock(&hilde_task_fd_lock);
  /* A worker already in poll(2) does not have this descriptor in its set,
     and a sleeping one may have to become the one that polls. */
  hilde_task_notify(HILDE_TASK_NOTIFY_FD);
  hilde_task_leave(HILDE_TASK_AFTER_PARK);
  self = hilde_task_self();
  self->wait_fd = -1;
  if ((self->got_events & want) != 0) {
    return 1;
  }
  /* A hang-up on a read end still has data to deliver or an end of file to
     report, and a read will say which. */
  if (what != 2 && (self->got_events & POLLHUP) != 0) {
    return 1;
  }
  return 0;
}

/* Before a read of hilde_file_read: a task whose descriptor has nothing to
   read yet is parked until it has, and its worker runs the other tasks
   meanwhile.  Without this a read of a socket or a pipe holds the worker
   until the peer writes, and main runs on worker 0 only: a task on worker 0
   that reads what main is about to send waits for ever, and so does main.
   A file always polls ready and is read at once.  A programme that never
   used a task, and a thread that is no worker, read as before; nothing here
   sets the runtime up. */
static void hilde_task_before_read(int fd) {
  struct pollfd p;
  int rc;

  if (!hilde_task_initialised || hilde_task_here() == NULL) {
    return;
  }
  p.fd = fd;
  p.events = POLLIN;
  p.revents = 0;
  do {
    rc = poll(&p, 1, 0);
  } while (rc < 0 && errno == EINTR);
  if (rc == 0) {
    /* Its answer is not needed: when the wait failed or the descriptor hung
       up, the read that follows reports what happened. */
    (void) hilde_task_wait_fd(fd, 1);
  }
}

/* A scope whose tasks get stack bytes of stack each, rounded up to a page
   and held between HILDE_TASK_STACK and HILDE_TASK_STACK_MOST. */
void* hilde_task_scope_open_sized(size_t stack) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_task_scope_t* scope;
  size_t page = hilde_arena_page_size();

  /* No scope when the runtime cannot be set up: openScope answers None. */
  if (!hilde_task_ready()) {
    return NULL;
  }
  if (stack < HILDE_TASK_STACK) {
    stack = HILDE_TASK_STACK;
  }
  if (stack > HILDE_TASK_STACK_MOST) {
    stack = HILDE_TASK_STACK_MOST;
  }
  stack = ((stack + page - 1) / page) * page;
  scope = (hilde_task_scope_t*) calloc(1, sizeof(hilde_task_scope_t));
  if (scope == NULL) {
    return NULL;
  }
  if (pthread_mutex_init(&scope->lock, NULL) != 0) {
    free(scope);
    return NULL;
  }
  scope->stack = stack;
  return (void*) scope;
}

void* hilde_task_scope_open(void) {
  return hilde_task_scope_open_sized(HILDE_TASK_STACK);
}

/* 1 when the task has ended, so that a join of it does not wait. */
int32_t hilde_task_done(void* raw) {
  hilde_task_fiber_t* fiber = (hilde_task_fiber_t*) raw;
  int32_t done;

  hilde_task_lock(&fiber->lock);
  done = (fiber->state == HILDE_TASK_DONE) ? 1 : 0;
  hilde_task_unlock(&fiber->lock);
  return done;
}

/* Wait until fewer than count of the tasks started in the scope are
   running: one of them has ended, when count is how many were. */
hilde_unit_t hilde_task_scope_wait_below(void* raw, size_t count) {
  hilde_task_scope_t* scope = (hilde_task_scope_t*) raw;

  (void) hilde_task_self();
  hilde_task_lock(&scope->lock);
  while (scope->live >= count && scope->live > 0) {
    hilde_task_park(scope, &scope->lock);
    hilde_task_lock(&scope->lock);
  }
  hilde_task_unlock(&scope->lock);
  return nil;
}

/* The bytes of stack the caller may still use below its own frame: in a
   task, down to the guard pages of the task's stack; on a stack the
   runtime did not map, the programme's own, SIZE_MAX, since the system
   grows that one itself.  A function with a large frame asks this first,
   so that it does not step over the guard pages. */
size_t hilde_task_stack_left(void) {
  hilde_task_worker_t* worker = hilde_task_worker_of_thread;
  hilde_task_fiber_t* fiber;
  unsigned char here;
  uintptr_t low;
  uintptr_t at;

  if (worker == NULL || worker->current == NULL || worker->current->mapping == NULL) {
    return SIZE_MAX;
  }
  fiber = worker->current;
  low = (uintptr_t) fiber->mapping + (uintptr_t) HILDE_TASK_GUARD_PAGES * (uintptr_t) hilde_arena_page_size();
  at = (uintptr_t) &here;
  return (at > low) ? (size_t) (at - low) : 0;
}

/* Wait until every task started in the scope has ended -- structured
   concurrency's one rule -- and give the scope back. */
hilde_unit_t hilde_task_scope_close(void* raw) {
  extern void free(void* ptr);
  hilde_task_scope_t* scope = (hilde_task_scope_t*) raw;

  (void) hilde_task_self();
  hilde_task_lock(&scope->lock);
  while (scope->live > 0) {
    hilde_task_park(scope, &scope->lock);
    hilde_task_lock(&scope->lock);
  }
  hilde_task_unlock(&scope->lock);
  pthread_mutex_destroy(&scope->lock);
  free(scope);
  return nil;
}

int hilde_task_available(void) {
  return HILDE_IN_LIBRARY ? 0 : 1;
}

/* For the tests of the scheduler, which read it from outside: how many of
   the workers 1 to 3 are marked asleep, read under the idle lock; the same
   after two wake-ups in a row under one hold of that lock; a write into
   the fifteenth page of the mapping of the calling task, a guard page when
   there are sixteen; and how many times the worker the caller runs on has
   run a fiber.  Where there are no tasks the stand-ins below answer 0. */
int32_t hilde_task_test_sleepers(void) {
  int32_t count;

  hilde_task_lock(&hilde_task_idle_lock);
  count = hilde_task_workers[1].asleep + hilde_task_workers[2].asleep + hilde_task_workers[3].asleep;
  hilde_task_unlock(&hilde_task_idle_lock);
  return count;
}

int32_t hilde_task_test_wake_two(void) {
  int32_t count;

  hilde_task_lock(&hilde_task_idle_lock);
  (void) hilde_task_signal_sleeper();
  (void) hilde_task_signal_sleeper();
  count = hilde_task_workers[1].asleep + hilde_task_workers[2].asleep + hilde_task_workers[3].asleep;
  hilde_task_unlock(&hilde_task_idle_lock);
  return count;
}

int32_t hilde_task_test_touch_guard(void) {
  *(volatile unsigned char*) (hilde_task_self()->mapping + 15u * hilde_arena_page_size()) = 1;
  return 1;
}

int64_t hilde_task_test_runs(void) {
  return (int64_t) __atomic_load_n(&hilde_task_here()->runs, __ATOMIC_ACQUIRE);
}

/* How many workers this programme runs on, starting them if a spawn has not
   yet, and which one the calling task runs on at this moment.  No module
   calls them: they are for tests, which have to show that more than one
   worker ran their tasks, or a test that passes on one thread would say
   nothing about several. */
int32_t hilde_task_workers_running(void) {
  if (!hilde_task_ready()) {
    return 1;
  }
  hilde_task_start_workers();
  return (int32_t) hilde_task_started_count();
}

int32_t hilde_task_worker_index(void) {
  if (!hilde_task_ready()) {
    return 0;
  }
  return (int32_t) hilde_task_here()->index;
}

#else

#define HILDE_PREEMPT_POINT() ((void) 0)

static void hilde_task_blocking(void (*fn)(void*), void* arg) {
  fn(arg);
}

/* No task support on this platform: one thread, one fiber.  A wait can only
   ever be a deadlock, and the locks guard nothing but are taken all the
   same so that the channel code below is the same code everywhere. */
static void hilde_task_park(const void* key, pthread_mutex_t* lock) {
  (void) key;
  (void) lock;
  hilde_stop_with("Hilde: deadlock -- a task waits on a platform without tasks");
}

static void hilde_task_park2(const void* key, pthread_mutex_t* first, pthread_mutex_t* second) {
  (void) key;
  (void) first;
  (void) second;
  hilde_stop_with("Hilde: deadlock -- a task waits on a platform without tasks");
}

static void hilde_task_wake_key(const void* key) {
  (void) key;
}

static void hilde_task_lock(pthread_mutex_t* lock) {
  if (pthread_mutex_lock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}

static void hilde_task_unlock(pthread_mutex_t* lock) {
  if (pthread_mutex_unlock(lock) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
}


/* One thread: nothing else can wake it, so it waits until deadline. */
static void hilde_task_park_until(const void* key, pthread_mutex_t* lock, int64_t deadline) {
  (void) key;
  hilde_task_unlock(lock);
  hilde_task_sleep_alone(deadline - hilde_task_now());
}

hilde_unit_t hilde_task_sleep_ns(int64_t nanos) {
  hilde_task_sleep_alone(nanos);
  return nil;
}

void* hilde_task_spawn(void* scope, hilde_fnptr_t entry, uint8_t* argument) {
  (void) scope;
  (void) entry;
  (void) argument;
  return NULL;
}

hilde_unit_t hilde_task_join(void* raw) {
  (void) raw;
  return nil;
}

/* Without tasks a task ran to its end when it was started. */
int32_t hilde_task_done(void* raw) {
  (void) raw;
  return 1;
}

hilde_unit_t hilde_task_scope_wait_below(void* raw, size_t count) {
  (void) raw;
  (void) count;
  return nil;
}

/* Without tasks there is only the programme's own stack. */
size_t hilde_task_stack_left(void) {
  return SIZE_MAX;
}

hilde_unit_t hilde_task_yield(void) {
  return nil;
}

int hilde_task_wait_fd(int fd, int what) {
  struct pollfd p;
  int rc;

  p.fd = fd;
  p.events = (what == 2) ? POLLOUT : POLLIN;
  p.revents = 0;
  do {
    rc = poll(&p, 1, -1);
  } while (rc < 0 && errno == EINTR);
  return hilde_task_poll_answer(rc, p.revents, what);
}

/* Without tasks a read has no worker to give back. */
static void hilde_task_before_read(int fd) {
  (void) fd;
}

void* hilde_task_scope_open(void) {
  extern void* calloc(size_t count, size_t size);

  return calloc(1, 1);
}

void* hilde_task_scope_open_sized(size_t stack) {
  (void) stack;
  return hilde_task_scope_open();
}

hilde_unit_t hilde_task_scope_close(void* raw) {
  extern void free(void* ptr);

  free(raw);
  return nil;
}

int hilde_task_available(void) {
  return 0;
}

int32_t hilde_task_test_sleepers(void) {
  return 0;
}

int32_t hilde_task_test_wake_two(void) {
  return 0;
}

int32_t hilde_task_test_touch_guard(void) {
  return 0;
}

int64_t hilde_task_test_runs(void) {
  return 0;
}

int32_t hilde_task_workers_running(void) {
  return 1;
}

int32_t hilde_task_worker_index(void) {
  return 0;
}

#endif

/*
 * Channels.
 *
 * The bookkeeping lives here and the values live in Hilde: the slots are a
 * Pointer[T] that Standard.Task allocates and reads and writes, because
 * only Hilde knows what a T is.  This side hands out slot numbers and
 * decides who waits.  One sender and one receiver -- both ends are Linear,
 * so neither can be shared.
 *
 * Every field is read and written under the channel's lock, and the lock is
 * what carries a value from one thread to the other: the sender writes its
 * slot and then takes the lock in hilde_channel_sent; the receiver takes the
 * lock in hilde_channel_receive_slot and then reads the slot.  A slot handed
 * to the sender is not one the receiver can read before hilde_channel_sent
 * counts it, and a receive moves head and count together, so head + count
 * -- the sender's slot -- does not move under the sender.
 */

typedef struct hilde_channel {
  pthread_mutex_t lock;
  size_t physical;          /* slots allocated: the capacity, or 1 */
  size_t head;              /* the oldest value */
  size_t count;             /* values in the slots */
  int rendezvous;           /* capacity 0: a send waits for a receiver */
  int sender_open;
  int receiver_open;
  int receiver_waiting;     /* a receive is parked, empty-handed */
  const void* selector;     /* the key a wait on two channels is parked on */
  int select_turn;          /* which one such a wait takes when both hold a value */
} hilde_channel_t;

/* A channel of capacity values.  0 is allowed and means a rendezvous: the
   sender waits until a receiver is there to take the value.  NULL when out
   of memory. */
void* hilde_channel_open(size_t capacity) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_channel_t* channel;

  channel = (hilde_channel_t*) calloc(1, sizeof(hilde_channel_t));
  if (channel == NULL) {
    return NULL;
  }
  if (pthread_mutex_init(&channel->lock, NULL) != 0) {
    free(channel);
    return NULL;
  }
  channel->physical = (capacity == 0) ? 1 : capacity;
  channel->rendezvous = (capacity == 0) ? 1 : 0;
  channel->sender_open = 1;
  channel->receiver_open = 1;
  return (void*) channel;
}

size_t hilde_channel_slots(void* raw) {
  return ((hilde_channel_t*) raw)->physical;
}

/* The slot a send may write into, after waiting for room -- or -1 when the
   receiver is gone, and the value goes back to the sender. */
int64_t hilde_channel_send_slot(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int64_t slot;

  hilde_task_lock(&channel->lock);
  while (channel->receiver_open &&
         (channel->count == channel->physical ||
          (channel->rendezvous && !channel->receiver_waiting))) {
    hilde_task_park(raw, &channel->lock);
    hilde_task_lock(&channel->lock);
  }
  if (!channel->receiver_open) {
    slot = -1;
  } else {
    slot = (int64_t) ((channel->head + channel->count) % channel->physical);
  }
  hilde_task_unlock(&channel->lock);
  return slot;
}

hilde_unit_t hilde_channel_sent(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;

  hilde_task_lock(&channel->lock);
  channel->count++;
  hilde_task_wake_key(raw);
  if (channel->selector != NULL) {
    hilde_task_wake_key(channel->selector);
  }
  hilde_task_unlock(&channel->lock);
  return nil;
}

/* The slot a receive may read from, after waiting for a value -- or -1 when
   the channel is empty and the sender is gone: the ordinary end of a
   stream, not an error. */
int64_t hilde_channel_receive_slot(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int64_t slot;

  hilde_task_lock(&channel->lock);
  while (channel->count == 0 && channel->sender_open) {
    channel->receiver_waiting = 1;
    hilde_task_wake_key(raw);
    hilde_task_park(raw, &channel->lock);
    hilde_task_lock(&channel->lock);
  }
  channel->receiver_waiting = 0;
  slot = (channel->count == 0) ? -1 : (int64_t) channel->head;
  hilde_task_unlock(&channel->lock);
  return slot;
}

hilde_unit_t hilde_channel_received(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;

  hilde_task_lock(&channel->lock);
  channel->head = (channel->head + 1) % channel->physical;
  channel->count--;
  hilde_task_wake_key(raw);
  hilde_task_unlock(&channel->lock);
  return nil;
}

/* The slot a receive may read from now, without waiting: the slot, -1 when
   the channel is empty and its sender is gone, -2 when it is empty and the
   sender may still send.  On a channel of capacity 0 a sender hands over
   its value only to a receive that waits, so this finds none there. */
int64_t hilde_channel_poll_slot(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int64_t slot;

  hilde_task_lock(&channel->lock);
  if (channel->count > 0) {
    slot = (int64_t) channel->head;
  } else {
    slot = channel->sender_open ? -2 : -1;
  }
  hilde_task_unlock(&channel->lock);
  return slot;
}

/* The slot a receive may read from, after waiting at most nanos
   nanoseconds for a value: the slot, -1 when the channel is empty and its
   sender is gone, -2 when the time ran out first.  On a channel of
   capacity 0 the waiting lets a sender hand over its value; one handed
   over after the time ran out waits for the next receive. */
int64_t hilde_channel_receive_slot_within(void* raw, int64_t nanos) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int64_t deadline = hilde_task_now() + ((nanos > 0) ? nanos : 0);
  int64_t slot;

  hilde_task_lock(&channel->lock);
  while (channel->count == 0 && channel->sender_open) {
    if (hilde_task_now() >= deadline) {
      channel->receiver_waiting = 0;
      hilde_task_unlock(&channel->lock);
      return -2;
    }
    channel->receiver_waiting = 1;
    hilde_task_wake_key(raw);
    hilde_task_park_until(raw, &channel->lock, deadline);
    hilde_task_lock(&channel->lock);
  }
  channel->receiver_waiting = 0;
  slot = (channel->count == 0) ? -1 : (int64_t) channel->head;
  hilde_task_unlock(&channel->lock);
  return slot;
}

/* Wait until one of two channels holds a value, or until both are empty
   and their senders gone.  1 or 2 names the channel to receive from, whose
   receive then takes the value without waiting; 0 means both are done.
   The fiber parks on the first channel's key, and while it waits the
   second channel's selector names that key, so that a send or a close on
   either wakes it.  Both locks are taken in the order of their addresses.
   When both hold a value, the one taken is the one not taken the last
   time both did, so that neither can starve the other.  On a channel of
   capacity 0 the waiting lets a sender hand over its value; a value the
   other channel's sender handed over meanwhile waits for the next
   receive. */
int32_t hilde_channel_select2(void* first_raw, void* second_raw) {
  hilde_channel_t* a = (hilde_channel_t*) first_raw;
  hilde_channel_t* b = (hilde_channel_t*) second_raw;
  hilde_channel_t* low = ((uintptr_t) first_raw < (uintptr_t) second_raw) ? a : b;
  hilde_channel_t* high = (low == a) ? b : a;
  int32_t chosen;

  for (;;) {
    hilde_task_lock(&low->lock);
    hilde_task_lock(&high->lock);
    if (a->count > 0 && b->count > 0) {
      chosen = a->select_turn ? 2 : 1;
      a->select_turn = !a->select_turn;
      break;
    }
    if (a->count > 0) {
      chosen = 1;
      break;
    }
    if (b->count > 0) {
      chosen = 2;
      break;
    }
    if (!a->sender_open && !b->sender_open) {
      chosen = 0;
      break;
    }
    a->receiver_waiting = 1;
    b->receiver_waiting = 1;
    b->selector = first_raw;
    hilde_task_wake_key(first_raw);
    hilde_task_wake_key(second_raw);
    hilde_task_park2(first_raw, &high->lock, &low->lock);
  }
  a->receiver_waiting = 0;
  b->receiver_waiting = 0;
  b->selector = NULL;
  hilde_task_unlock(&high->lock);
  hilde_task_unlock(&low->lock);
  return chosen;
}

/* Close the sending end.  1 when the receiving end is closed too, and the
   caller is the one to give the channel back. */
int hilde_channel_close_sender(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int last;

  hilde_task_lock(&channel->lock);
  channel->sender_open = 0;
  hilde_task_wake_key(raw);
  if (channel->selector != NULL) {
    hilde_task_wake_key(channel->selector);
  }
  last = channel->receiver_open ? 0 : 1;
  hilde_task_unlock(&channel->lock);
  return last;
}

/* Close the receiving end.  Values still in the channel would be lost, and a
   value may own a resource such as a descriptor or a buffer, so closing with
   values left stops the programme with a message instead of leaking them in
   silence.  1 when the sending end is closed too. */
int hilde_channel_close_receiver(void* raw) {
  hilde_channel_t* channel = (hilde_channel_t*) raw;
  int last;

  hilde_task_lock(&channel->lock);
  if (channel->count > 0) {
    hilde_task_die("Hilde: a channel's receiving end was closed with values still in it -- they would be lost; receive until the sender has closed");
  }
  channel->receiver_open = 0;
  hilde_task_wake_key(raw);
  last = channel->sender_open ? 0 : 1;
  hilde_task_unlock(&channel->lock);
  return last;
}

hilde_unit_t hilde_channel_free(void* raw) {
  extern void free(void* ptr);
  hilde_channel_t* channel = (hilde_channel_t*) raw;

  pthread_mutex_destroy(&channel->lock);
  free(raw);
  return nil;
}

/*
 * Mutexes.
 *
 * A lock that tasks share through a lent reference, to take turns at a
 * value they all change.  As with a channel, the bookkeeping lives here
 * and the value lives in Hilde, beside the lock.  A task that finds the
 * lock held parks on it as a receive parks on an empty channel: its
 * worker runs other tasks meanwhile, and a lock that is never given back
 * ends in the deadlock message.  The lock of the mutex is what carries
 * the value from one thread to the next: release writes the value back
 * before it takes the lock, acquire reads it after.
 */

typedef struct hilde_mutex {
  pthread_mutex_t lock;
  int held;
} hilde_mutex_t;

/* A mutex that is not held.  NULL when out of memory. */
void* hilde_mutex_open(void) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_mutex_t* mutex;

  mutex = (hilde_mutex_t*) calloc(1, sizeof(hilde_mutex_t));
  if (mutex == NULL) {
    return NULL;
  }
  if (pthread_mutex_init(&mutex->lock, NULL) != 0) {
    free(mutex);
    return NULL;
  }
  return (void*) mutex;
}

/* Wait until the mutex is not held, then hold it. */
hilde_unit_t hilde_mutex_acquire(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  hilde_task_lock(&mutex->lock);
  while (mutex->held) {
    hilde_task_park(raw, &mutex->lock);
    hilde_task_lock(&mutex->lock);
  }
  mutex->held = 1;
  hilde_task_unlock(&mutex->lock);
  return nil;
}

/* Hold the mutex when it is not held: 1, and 0 without waiting when it is. */
int32_t hilde_mutex_try(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;
  int32_t took;

  hilde_task_lock(&mutex->lock);
  took = mutex->held ? 0 : 1;
  mutex->held = 1;
  hilde_task_unlock(&mutex->lock);
  return took;
}

/* Let the mutex go and wake the tasks that wait for it. */
hilde_unit_t hilde_mutex_release(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  hilde_task_lock(&mutex->lock);
  mutex->held = 0;
  hilde_task_wake_key(raw);
  hilde_task_unlock(&mutex->lock);
  return nil;
}

/* Whether the mutex is held now. */
int32_t hilde_mutex_held(void* raw) {
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;
  int32_t held;

  hilde_task_lock(&mutex->lock);
  held = mutex->held ? 1 : 0;
  hilde_task_unlock(&mutex->lock);
  return held;
}

hilde_unit_t hilde_mutex_free(void* raw) {
  extern void free(void* ptr);
  hilde_mutex_t* mutex = (hilde_mutex_t*) raw;

  pthread_mutex_destroy(&mutex->lock);
  free(raw);
  return nil;
}

/* Atomic operations on a word of 64 bits that Hilde allocated, each
   sequentially consistent: every task sees the operations on one word in
   one order. */

int64_t hilde_atomic_load(void* word) {
  return __atomic_load_n((int64_t*) word, __ATOMIC_SEQ_CST);
}

hilde_unit_t hilde_atomic_store(void* word, int64_t value) {
  __atomic_store_n((int64_t*) word, value, __ATOMIC_SEQ_CST);
  return nil;
}

int64_t hilde_atomic_exchange(void* word, int64_t value) {
  return __atomic_exchange_n((int64_t*) word, value, __ATOMIC_SEQ_CST);
}

/* 1 when the word held expected and now holds desired, 0 when it held
   something else and is unchanged. */
int32_t hilde_atomic_compare_swap(void* word, int64_t expected, int64_t desired) {
  return __atomic_compare_exchange_n((int64_t*) word, &expected, desired, 0,
                                     __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST) ? 1 : 0;
}

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
     write (EPIPE), not the end of the programme.  Only a programme's own
     main gets here; a library leaves its host's signals alone.  A child
     gets the default back before its exec, in hilde_process_spawn. */
#ifdef SIGPIPE
  signal(SIGPIPE, SIG_IGN);
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

/* The system and the machine this programme was compiled for, from the
   macros the C compiler defines for its target: what Standard.Platform
   answers, and where Standard.Paths puts a programme's files.  unknown
   when the compiler names neither. */
hilde_span_t hilde_platform_system(void) {
#if defined(__linux__)
  static const char name[] = "linux";
#elif defined(__OpenBSD__)
  static const char name[] = "openbsd";
#elif defined(__FreeBSD__)
  static const char name[] = "freebsd";
#elif defined(__APPLE__)
  static const char name[] = "macos";
#elif defined(__wasi__)
  static const char name[] = "wasi";
#else
  static const char name[] = "unknown";
#endif
  return (hilde_span_t){ .data = (void*) (uintptr_t) name, .size = sizeof name - 1 };
}

hilde_span_t hilde_platform_machine(void) {
#if defined(__x86_64__)
  static const char name[] = "x86_64";
#elif defined(__aarch64__)
  static const char name[] = "aarch64";
#elif defined(__i386__)
  static const char name[] = "i386";
#elif defined(__arm__)
  static const char name[] = "arm";
#elif defined(__riscv) && (__riscv_xlen == 64)
  static const char name[] = "riscv64";
#elif defined(__powerpc64__)
  static const char name[] = "ppc64";
#elif defined(__wasm32__)
  static const char name[] = "wasm32";
#else
  static const char name[] = "unknown";
#endif
  return (hilde_span_t){ .data = (void*) (uintptr_t) name, .size = sizeof name - 1 };
}

/* The name of the host the programme runs on, asked of the kernel once,
   the first time, and kept: unknown when gethostname fails or gives an
   empty name.  A longer name is cut at 255 bytes.  gethostname is
   declared here, as kill is: glibc hides it under -std=c17. */
static char hilde_platform_host_name[256];
static size_t hilde_platform_host_size;

static void hilde_platform_host_once(void) {
  extern int gethostname(char* name, size_t size);
  char name[256];
  size_t n = 0;

  memset(name, 0, sizeof name);
  if ((gethostname(name, sizeof name - 1) != 0) || (name[0] == '\0')) {
    memcpy(hilde_platform_host_name, "unknown", 7);
    hilde_platform_host_size = 7;
    return;
  }
  while ((n < sizeof name - 1) && (name[n] != '\0')) {
    n++;
  }
  memcpy(hilde_platform_host_name, name, n);
  hilde_platform_host_size = n;
}

hilde_span_t hilde_platform_host(void) {
  static pthread_once_t once = PTHREAD_ONCE_INIT;
  if (pthread_once(&once, hilde_platform_host_once) != 0) {
    hilde_abort_internal("Prelude error: pthread_once failed.");
  }
  return (hilde_span_t){ .data = (void*) hilde_platform_host_name, .size = hilde_platform_host_size };
}

/* The user number (group false) or the group number (group true) of the
   account name in the password database: -1 when there is no such account
   or the name holds a zero byte or is longer than 255 bytes, -2 when the
   lookup failed.  getpwnam_r is declared here, as kill is: glibc hides it
   under -std=c17. */
int64_t hilde_account_number(const uint8_t* name, size_t size, int group) {
#if defined(__wasi__)
  /* WASI has no password database, so the lookup fails. */
  (void) name;
  (void) size;
  (void) group;
  return -2;
#else
  extern int getpwnam_r(const char* name, struct passwd* entry, char* storage, size_t capacity, struct passwd** found);
  char wanted[256];
  char storage[4096];
  struct passwd entry;
  struct passwd* found = NULL;

  if ((size == 0) || (size >= sizeof wanted) || (memchr(name, 0, size) != NULL)) {
    return -1;
  }
  memcpy(wanted, name, size);
  wanted[size] = '\0';
  if (getpwnam_r(wanted, &entry, storage, sizeof storage, &found) != 0) {
    return -2;
  }
  if (found == NULL) {
    return -1;
  }
  return group ? (int64_t) entry.pw_gid : (int64_t) entry.pw_uid;
#endif
}

/* The effective user number of the process. */
uint32_t hilde_account_effective(void) {
  extern uid_t geteuid(void);

  return (uint32_t) geteuid();
}

/* A secret read from the terminal of the process, /dev/tty, never from
   standard input or an argument, with the echo off and nothing shown in its
   place.  prompt is written first.  Up to capacity bytes go into buffer, a
   line feed ends the input and is not kept.  The length, or -1 when the
   process has no terminal, -2 when the line was longer than capacity, -3
   when reading failed.  On -2 and -3 the buffer is wiped.

   The BSDs and macOS have readpassphrase(3), which does all of it.  On
   Linux the same is done here: the terminal opened, its echo switched off,
   and the signals that end or stop the process caught while it is off; the
   echo goes back on before such a signal is raised again, so that it is
   never left off. */
#if defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
#if defined(__has_include)
#if __has_include(<readpassphrase.h>)
#include <readpassphrase.h>
#else
/* The header is not in every set of headers of a toolchain that builds for
   the system (zig's libc for macOS has none); the function and the flag
   are the same on OpenBSD, FreeBSD and macOS. */
extern char* readpassphrase(const char* prompt, char* buf, size_t bufsiz, int flags);
#define RPP_REQUIRE_TTY 0x02
#endif
#else
#include <readpassphrase.h>
#endif

int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  char text[256];
  char line[1026];
  size_t n;

  if (prompt_size >= sizeof text || capacity + 2 > sizeof line) {
    return -3;
  }
  memcpy(text, prompt, prompt_size);
  text[prompt_size] = '\0';
  errno = 0;
  if (readpassphrase(text, line, capacity + 2, RPP_REQUIRE_TTY) == NULL) {
    int no_tty = (errno == ENOTTY || errno == ENXIO || errno == ENOENT);
    hilde_wipe(line, sizeof line);
    return no_tty ? -1 : -3;
  }
  n = strlen(line);
  if (n > capacity) {
    hilde_wipe(line, sizeof line);
    hilde_wipe(buffer, capacity);
    return -2;
  }
  memcpy(buffer, line, n);
  hilde_wipe(line, sizeof line);
  return (int64_t) n;
}
#elif defined(__linux__)
static volatile sig_atomic_t hilde_secret_signal = 0;

static void hilde_secret_caught(int number) {
  hilde_secret_signal = number;
}

int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  extern int kill(pid_t pid, int sig);
  static const int caught[] = {
    SIGINT, SIGHUP, SIGQUIT, SIGTERM, SIGTSTP, SIGTTIN, SIGTTOU
  };
  enum { kinds = sizeof caught / sizeof caught[0] };
  hilde_sigaction_t act;
  hilde_sigaction_t saved[kinds];
  struct termios before;
  struct termios quiet;
  int64_t result = 0;
  size_t used = 0;
  int over = 0;
  int fd;
  int i;

  do {
    fd = open("/dev/tty", O_RDWR | O_NOCTTY);
  } while (fd < 0 && errno == EINTR);
  fd = hilde_file_mark_close_on_exec(fd);
  if (fd < 0) {
    return -1;
  }
  if (tcgetattr(fd, &before) != 0) {
    close(fd);
    return -1;
  }
  hilde_secret_signal = 0;
  memset(&act, 0, sizeof act);
  HILDE_SIGACTION_HANDLER(act) = hilde_secret_caught;
  for (i = 0; i < kinds; i++) {
    (void) hilde_libc_sigaction(caught[i], &act, &saved[i]);
  }
  quiet = before;
  quiet.c_lflag &= ~((tcflag_t) ECHO | (tcflag_t) ECHONL);
  if (hilde_file_write_all(fd, prompt, prompt_size) != 1
      || tcsetattr(fd, TCSAFLUSH, &quiet) != 0) {
    result = -3;
  }
  while (result == 0 && hilde_secret_signal == 0) {
    uint8_t byte;
    ssize_t got = read(fd, &byte, 1);
    if (got < 0) {
      if (errno == EINTR) {
        continue;
      }
      result = -3;
      break;
    }
    if (got == 0 || byte == '\n' || byte == '\r') {
      break;
    }
    if (used < capacity) {
      buffer[used++] = byte;
    } else {
      over = 1;
    }
  }
  (void) tcsetattr(fd, TCSAFLUSH, &before);
  (void) hilde_file_write_all(fd, (const uint8_t*) "\n", 1);
  for (i = 0; i < kinds; i++) {
    (void) hilde_libc_sigaction(caught[i], &saved[i], NULL);
  }
  close(fd);
  if (hilde_secret_signal != 0) {
    hilde_wipe(buffer, capacity);
    kill(getpid(), hilde_secret_signal);
    return -3;
  }
  if (result != 0 || over) {
    hilde_wipe(buffer, capacity);
    return over ? -2 : result;
  }
  return (int64_t) used;
}
#else
int64_t hilde_secret_read_tty(const uint8_t* prompt, size_t prompt_size,
                              uint8_t* buffer, size_t capacity) {
  (void) prompt;
  (void) prompt_size;
  (void) buffer;
  (void) capacity;
  return -1;
}
#endif

/* One line of a secret from fd, standard input for --password-stdin: up to
   capacity bytes into buffer, the line feed not kept.  The length, -2 when
   the line was longer (the buffer is wiped), -3 when reading failed. */
int64_t hilde_secret_read_fd(int fd, uint8_t* buffer, size_t capacity) {
  size_t used = 0;
  int over = 0;

  for (;;) {
    uint8_t byte;
    ssize_t got = read(fd, &byte, 1);
    if (got < 0) {
      if (errno == EINTR) {
        continue;
      }
      hilde_wipe(buffer, capacity);
      return -3;
    }
    if (got == 0 || byte == (uint8_t) 10) {
      break;
    }
    if (used < capacity) {
      buffer[used++] = byte;
    } else {
      over = 1;
    }
  }
  if (over) {
    hilde_wipe(buffer, capacity);
    return -2;
  }
  return (int64_t) used;
}
