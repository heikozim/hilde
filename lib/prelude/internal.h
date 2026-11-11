/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

    The epoll and kqueue backends of the poller follow src/h2_poller.c of
    the Hiawatha web server, and the sandbox, with the system calls its
    seccomp filter refuses and its handling of Landlock rights and paths,
    follows src/sandbox.c of the same server.
*/

/*
 * What the parts of the runtime prelude share: the headers, the types of
 * the generated C, and the functions one part calls in another.
 */

#ifndef HILDE_PRELUDE_INTERNAL_H
#define HILDE_PRELUDE_INTERNAL_H
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
/* errno.h, for the number of an interrupted call.  Another
   platform-dependent number, and the one that
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
   and the number of a connect in progress, but not clock_gettime; OpenBSD with clang 19.1.7 shows
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
   tcflush, isatty, ioctl, struct termios, struct winsize, and the flags
   of echo, the flushes and the request of the window size, whose values
   differ between the systems (the request of the window size is 21523
   on Linux and 1074295912 on OpenBSD, the flush of the input 0 and 1)
   and are therefore taken from the headers.  All of it
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
   it; with Apple clang 17 under cc -std=c17 -Wall -Wextra, the end of
   file constant of stdio.h stays undefined after all four. */
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

/* A library.  The C of a library defines HILDE_LIBRARY before this file,
   and HILDE_IN_LIBRARY is 1 there and 0 in a programme, so that the
   runtime can ask it in an if as well as in an #if. */
#if defined(HILDE_LIBRARY)
#define HILDE_IN_LIBRARY 1
#else
#define HILDE_IN_LIBRARY 0
#endif

/* The name a C function has in the assembler, for an asm label or a call
   from asm: Mach-O puts an underscore before every C name, the object
   files of Linux and the BSDs do not. */
#if defined(__APPLE__)
#define HILDE_ASM_NAME(name) "_" name
#else
#define HILDE_ASM_NAME(name) name
#endif

/* Under -std=c17 glibc's <netdb.h> declares neither getaddrinfo nor struct
   addrinfo: gcc 14.2.0 reports the size of hints as unknown and
   getaddrinfo as implicitly declared.  A feature macro before every include
   would change what the rest of the prelude sees (see O_CLOEXEC in
   file.c).  So the struct is declared here under a name of its own, with
   the layout both systems' headers give it: 48 bytes, the same eight
   offsets on Linux arm64 and OpenBSD amd64.  The two functions are reached
   through asm labels, as the stream variables are in core.c.
   scripts/resolver/check-header.sh checks the layout, the offsets of the
   two socket addresses and the four EAI_ values below against the real
   headers on all four systems.  FreeBSD and macOS have the BSD order of
   the fields, ai_canonname before ai_addr, and the BSD numbers for the
   EAI_ values.  Other systems get -3: their layout is not checked. */
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

/* OpenBSD, FreeBSD and macOS declare sigaction and SA_RESTART under
   -std=c17; glibc does not: with gcc 14.2.0, struct sigaction is
   incomplete and sigset_t, SA_RESTART, sigemptyset and sigaction are
   undeclared, while the signal numbers, alarm and getpid are declared.  So
   on glibc and musl the struct is declared here with their layout and
   sigaction is reached through an asm label, as for getaddrinfo above;
   scripts/signal/check-header.sh checks the layout and SA_RESTART against
   the real header, for the host and for every target whose headers it is
   given.  bionic declares struct sigaction under -std=c17, with sa_flags
   first on LP64, so Android takes the header's own struct.  Used by the
   signals and by the reading of a secret, which catches the signals that
   would end it. */
#define HILDE_SIGNAL_KINDS 5

#if defined(__linux__) && !defined(__ANDROID__)
/* glibc's and musl's layout: the handler, a mask of 1024 bits, the flags,
   the restorer.  The mask is an array of unsigned long, as in the header,
   so it is aligned like a pointer: at offset 8 on LP64 and at offset 4 on
   i386 and 32-bit arm, where a uint64_t would be aligned to 8.  The fields
   have names of their own, since with a feature-test macro glibc makes
   sa_handler a macro. */
typedef struct hilde_sigaction {
  void (*handler)(int);
  unsigned long mask[1024 / (8 * sizeof(unsigned long))];
  int flags;
  void (*restorer)(void);
} hilde_sigaction_t;

_Static_assert(offsetof(hilde_sigaction_t, mask) == sizeof(void*),
               "sigaction: the mask follows the handler");
_Static_assert(offsetof(hilde_sigaction_t, flags) == sizeof(void*) + 128,
               "sigaction: the flags follow a mask of 128 bytes");
_Static_assert(offsetof(hilde_sigaction_t, restorer) == 2 * sizeof(void*) + 128,
               "sigaction: the restorer follows the flags");
_Static_assert(sizeof(hilde_sigaction_t) == 3 * sizeof(void*) + 128,
               "sigaction: size");

extern int hilde_libc_sigaction(int number, const hilde_sigaction_t* act,
                                hilde_sigaction_t* old) __asm__("sigaction");
#define HILDE_SA_RESTART 0x10000000
#define HILDE_SIGACTION_HANDLER(act) ((act).handler)
#define HILDE_SIGACTION_FLAGS(act) ((act).flags)
#elif defined(__ANDROID__) || defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__APPLE__)
typedef struct sigaction hilde_sigaction_t;
#define hilde_libc_sigaction sigaction
#define HILDE_SA_RESTART SA_RESTART
#define HILDE_SIGACTION_HANDLER(act) ((act).sa_handler)
#define HILDE_SIGACTION_FLAGS(act) ((act).sa_flags)
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

/*
 * What one part calls in another.  The parts of a programme are one
 * translation unit, so a function kept static in its part is declared
 * static here as well, with the attribute unused: a programme that has
 * not got the part does not call it, and no warning says it is missing.
 */

/* core.c */
hilde_span_t hilde_make_span(void* data, size_t size);
void* hilde_stderr(void);
_Noreturn __attribute__((noreturn)) hilde_unit_t hilde_abort_internal(const char* message);
void* hilde_calloc(size_t size, size_t count);
hilde_unit_t hilde_free(void* ptr);
void hilde_wipe(void* ptr, size_t size);
int64_t hilde_time_monotonic_nanos(void);
int hilde_pipe_open(int* ends);
void hilde_store_cli_args(int argc, char** argv);
static void hilde_flush_output(void) __attribute__((unused));
static _Noreturn void hilde_stop(const char* message) __attribute__((noreturn, unused));
static _Noreturn void hilde_stop_with(const char* message) __attribute__((noreturn, unused));
static void hilde_stop_join(char* out, size_t size, const char* a, size_t a_length,
                            const char* b, size_t b_length) __attribute__((unused));
static size_t hilde_arena_page_size(void) __attribute__((unused));
static int hilde_packed_holds(const uint8_t* block, size_t length, size_t strings) __attribute__((unused));
static int hilde_file_mark_close_on_exec(int fd) __attribute__((unused));
static _Noreturn void hilde_task_die(const char* message) __attribute__((noreturn, unused));
static int64_t hilde_task_now(void) __attribute__((unused));
static int hilde_task_poll_millis(int64_t deadline) __attribute__((unused));
static void hilde_task_sleep_alone(int64_t nanos) __attribute__((unused));
static int hilde_task_poll_answer(int rc, short revents, int what) __attribute__((unused));
/* The host's handler of a stop, and how many exported functions run now. */
static void (*hilde_library_handler)(const char* message) __attribute__((unused));
static int hilde_library_calls __attribute__((unused));

/* file.c */
int hilde_file_write_all(int fd, const uint8_t* buffer, size_t count);

/* path.c: the runtime's calls on paths, hilde_path_open and the others,
   are not declared here.  The parts that call them, file.c and socket.c,
   come after path.c, so its definitions are their declarations; a
   declaration here would be reported as declared and never defined in
   every programme that has not got path.c.  In capability mode on
   FreeBSD the calls are routed through the grants that sandbox.c opened,
   and sandbox.c, which comes before path.c, reads the state below. */
#if defined(HILDE_SANDBOX_CAPSICUM)
/* One path of the policy in capability mode: absolute, without a slash at
   its end ("/" for the root), and its descriptor. */
struct hilde_capsicum_grant {
  char* path;
  size_t length;
  int fd;
  int directory;
};

static struct hilde_capsicum_grant* hilde_capsicum_grants __attribute__((unused));
static int32_t hilde_capsicum_count __attribute__((unused));
static int hilde_capsicum_entered __attribute__((unused));
static char hilde_capsicum_cwd[PATH_MAX] __attribute__((unused));
static int hilde_capsicum_absolute(const char* path, const char* cwd, char out[PATH_MAX]) __attribute__((unused));
#endif

/* task.c, or task-none.c in a programme without the task runtime.  Each
   of them defines HILDE_PREEMPT_POINT as well, which the generated code
   writes in every loop. */
static void hilde_task_blocking(void (*fn)(void*), void* arg) __attribute__((unused));
static void hilde_task_park(const void* key, pthread_mutex_t* lock) __attribute__((unused));
static void hilde_task_park2(const void* key, pthread_mutex_t* first, pthread_mutex_t* second) __attribute__((unused));
static void hilde_task_park_until(const void* key, pthread_mutex_t* lock, int64_t deadline) __attribute__((unused));
static void hilde_task_wake_key(const void* key) __attribute__((unused));
static void hilde_task_lock(pthread_mutex_t* lock) __attribute__((unused));
static void hilde_task_unlock(pthread_mutex_t* lock) __attribute__((unused));
static void hilde_task_before_read(int fd) __attribute__((unused));
static void hilde_task_library_stop(void) __attribute__((unused));

/* The kinds of lock of the task runtime, for the lock-order checker that
   task.c carries in a build with HILDE_WITNESS.  The first seven are fixed
   locks of the runtime, the others one per object of their kind.  The
   hooks below name a lock's kind when it is made, forget it when it is
   destroyed, and look at the locks a thread holds where it may hold none
   or one; in every other build, and where task.c is not carried, they are
   nothing. */
#define HILDE_WITNESS_SETUP 0
#define HILDE_WITNESS_IDLE 1
#define HILDE_WITNESS_FD 2
#define HILDE_WITNESS_TIMER 3
#define HILDE_WITNESS_CALL 4
#define HILDE_WITNESS_WORKER 5
#define HILDE_WITNESS_BUCKET 6
#define HILDE_WITNESS_FIBER 7
#define HILDE_WITNESS_GUEST 8
#define HILDE_WITNESS_SCOPE 9
#define HILDE_WITNESS_LENDING 10
#define HILDE_WITNESS_CHANNEL 11
#define HILDE_WITNESS_MUTEX 12
#define HILDE_WITNESS_KINDS 13
#define HILDE_WITNESS_NAME(lock, kind) ((void) 0)
#define HILDE_WITNESS_FORGET(lock) ((void) 0)
#define HILDE_WITNESS_SWITCH(where) ((void) 0)
#define HILDE_WITNESS_WAIT(lock) ((void) 0)

#endif
