/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * The task runtime: fibers on N threads, the scheduler, timers and
 * channels.
 */

#include "internal.h"

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

#if defined(HILDE_TASKS)

void hilde_task_switch(void** save, void* next);
/* Only the trampoline below calls it, by name from assembly the optimiser
   does not read.  used keeps it, and its name, in a build with -flto,
   which otherwise drops it and fails to link. */
__attribute__((used)) void hilde_task_start(void* fiber);

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
  int guest;                       /* a thread of a library's host */
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

/* Set once, before any worker thread exists; read-only afterwards.  In a
   programme on the thread the process started on, in a library under
   hilde_task_setup_lock.  hilde_task_wanted is how many workers the system
   reports (or HILDE_TASK_THREADS says), hilde_task_started how many run: in
   a programme 1, the thread the process started on, until the first spawn,
   which starts the others; in a library 0 until the first use of a task
   function starts worker 0. */
static int hilde_task_initialised = 0;
static int hilde_task_wanted = 1;
static int hilde_task_started = HILDE_IN_LIBRARY ? 0 : 1;

/* A library.  A host calls an exported function from a thread of its own
   and cannot give that thread to the scheduler, whose workers return to
   their own stacks between fibers.  So a library's workers, worker 0 among
   them, are threads the library starts, and a host's thread is a guest: it
   runs its call on its own stack, its tasks run on the workers, and where
   it must wait for one of them it parks as a fiber does, but blocks on the
   condition of its record below instead of switching away.  Its record is
   the thread's own, made at its first wait.  hilde_task_guests_parked
   counts the guests blocked so; hilde_task_stopping is set once, when the
   library stops its workers. */
typedef struct hilde_task_guest {
  hilde_task_fiber_t fiber;        /* first: a guest is handed on as its fiber */
  pthread_mutex_t lock;            /* guards the wait on wake */
  pthread_cond_t wake;
  int made;                        /* lock and wake are made */
} hilde_task_guest_t;

static _Thread_local hilde_task_guest_t hilde_task_guest_of_thread;
static pthread_mutex_t hilde_task_setup_lock = PTHREAD_MUTEX_INITIALIZER;
static int hilde_task_guests_parked = 0;
static int hilde_task_stopping = 0;

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

#if defined(HILDE_WITNESS)
/*
 * The lock-order checker, in the manner of witness(4).  Only a build with
 * HILDE_WITNESS has it; in every other build none of this is compiled and
 * the hooks of internal.h are nothing.
 *
 * Every lock of the runtime has a kind (internal.h): a fixed lock is known
 * by its address, a lock of an object by the kind named when it was made.
 * Each thread keeps the locks it holds, in the order it took them, with
 * the place in the C where it took each.  A lock taken while others are
 * held adds the edge "held kind before taken kind" to one order of the
 * kinds for the whole process, before the lock is taken.  The first edge
 * that closes a cycle in that order ends the programme with both kinds and
 * both places, as a deadlock does, even when this run never waited on it.
 *
 * So do: a lock taken by the thread that holds it, a lock let go by a
 * thread that does not hold it, two locks of one kind held at once, a
 * lock of no known kind, a task that gives up its worker or a worker that
 * goes to a task with any lock held, a wait on a condition with any lock
 * held but the condition's own, and a thread that ends with a lock held.
 *
 * Which locks may be held where.  At a switch between stacks: none, so the
 * locks a thread holds are always the running task's.  At a wait on a
 * condition: the condition's own lock alone -- the idle lock where a
 * worker sleeps, the call lock where a helper waits for a call, a guest's
 * own lock where a library's guest waits.  Two locks of one kind: only two
 * channels, taken in the order of their addresses, as a wait on two
 * channels takes them.
 *
 * The checker sees the order in which locks are taken, not the memory
 * they guard: it finds no data race.
 */

/* Defined further down, with the blocking calls. */
static pthread_mutex_t hilde_task_call_lock;

static const char* const hilde_witness_kind_names[HILDE_WITNESS_KINDS] = {
  "setup", "idle", "fd", "timer", "call", "worker", "bucket",
  "fiber", "guest", "scope", "lending", "channel", "mutex"
};

/* Where a lock was taken: the C function, file and line. */
typedef struct hilde_witness_site {
  const char* function;
  const char* file;
  int line;
} hilde_witness_site_t;

typedef struct hilde_witness_hold {
  const pthread_mutex_t* lock;
  int kind;
  hilde_witness_site_t site;
} hilde_witness_hold_t;

/* The most locks one thread holds at once.  The runtime holds at most
   four; more is a fault of its own. */
#define HILDE_WITNESS_DEPTH 16

typedef struct hilde_witness_thread {
  int depth;
  hilde_witness_hold_t held[HILDE_WITNESS_DEPTH];
} hilde_witness_thread_t;

/* The calling thread's held locks.  Made at its first lock and never given
   back: the end of the thread looks at it from a destructor, which may run
   after the thread's own thread-local storage has gone. */
static _Thread_local hilde_witness_thread_t* hilde_witness_mine = NULL;
static pthread_once_t hilde_witness_once = PTHREAD_ONCE_INIT;
static pthread_key_t hilde_witness_key;

/* A message of the checker, cut to its size. */
typedef struct hilde_witness_text {
  char text[768];
  size_t used;
} hilde_witness_text_t;

static void hilde_witness_add(hilde_witness_text_t* t, const char* s) {
  while (*s != '\0' && t->used + 1 < sizeof(t->text)) {
    t->text[t->used++] = *s++;
  }
  t->text[t->used] = '\0';
}

static void hilde_witness_add_number(hilde_witness_text_t* t, int n) {
  char digits[12];
  char one[2] = { 0, 0 };
  unsigned value = (n < 0) ? 0u : (unsigned) n;
  int k = 0;

  do {
    digits[k++] = (char) ('0' + (value % 10u));
    value /= 10u;
  } while (value != 0u && k < 11);
  while (k > 0) {
    one[0] = digits[--k];
    hilde_witness_add(t, one);
  }
}

static void hilde_witness_add_site(hilde_witness_text_t* t, const hilde_witness_site_t* site) {
  hilde_witness_add(t, site->function);
  hilde_witness_add(t, " (");
  hilde_witness_add(t, site->file);
  hilde_witness_add(t, ":");
  hilde_witness_add_number(t, site->line);
  hilde_witness_add(t, ")");
}

/* "a channel lock", or "a lock of no known kind". */
static void hilde_witness_add_kind(hilde_witness_text_t* t, int kind) {
  if (kind < 0 || kind >= HILDE_WITNESS_KINDS) {
    hilde_witness_add(t, "a lock of no known kind");
    return;
  }
  hilde_witness_add(t, "a ");
  hilde_witness_add(t, hilde_witness_kind_names[kind]);
  hilde_witness_add(t, " lock");
}

static void hilde_witness_begin(hilde_witness_text_t* t) {
  t->used = 0;
  t->text[0] = '\0';
  hilde_witness_add(t, "Hilde: witness -- ");
}

/* The kinds of the locks made by objects, by address: a table of open
   addressing in each of a number of shards, each shard under a lock of its
   own that the checker takes directly. */
#define HILDE_WITNESS_SHARDS 64

typedef struct hilde_witness_entry {
  const void* lock;                /* NULL free, HILDE_WITNESS_GONE forgotten */
  int kind;
} hilde_witness_entry_t;

typedef struct hilde_witness_shard {
  pthread_mutex_t lock;
  hilde_witness_entry_t* slots;
  size_t size;                     /* slots, a power of two, or 0 */
  size_t used;                     /* slots not free */
  size_t live;                     /* slots that name a lock */
} hilde_witness_shard_t;

static hilde_witness_shard_t hilde_witness_shards[HILDE_WITNESS_SHARDS];
#define HILDE_WITNESS_GONE ((const void*) &hilde_witness_shards)

static void hilde_witness_thread_ended(void* raw);

static void hilde_witness_setup(void) {
  int i;

  for (i = 0; i < HILDE_WITNESS_SHARDS; i++) {
    if (pthread_mutex_init(&hilde_witness_shards[i].lock, NULL) != 0) {
      hilde_task_die("Hilde: witness -- the checker could not be set up");
    }
  }
  if (pthread_key_create(&hilde_witness_key, hilde_witness_thread_ended) != 0) {
    hilde_task_die("Hilde: witness -- the checker could not be set up");
  }
}

static size_t hilde_witness_hash(const void* lock) {
  uint64_t value = (uint64_t) (uintptr_t) lock;

  value ^= value >> 17;
  value *= UINT64_C(0x9E3779B97F4A7C15);
  value ^= value >> 29;
  return (size_t) value;
}

/* The slot of lock in shard: the one that names it, else the first free
   one.  The shard has a free slot: it is never more than half used. */
static hilde_witness_entry_t* hilde_witness_probe(hilde_witness_shard_t* shard,
                                                  const void* lock) {
  size_t mask = shard->size - 1;
  size_t at = (hilde_witness_hash(lock) / HILDE_WITNESS_SHARDS) & mask;

  while (shard->slots[at].lock != NULL && shard->slots[at].lock != lock) {
    at = (at + 1) & mask;
  }
  return &shard->slots[at];
}

/* With the shard's lock held: room for one more, by a new table of four
   times the live entries when the forgotten ones fill it. */
static void hilde_witness_room(hilde_witness_shard_t* shard) {
  extern void* calloc(size_t count, size_t size);
  extern void free(void* ptr);
  hilde_witness_entry_t* old = shard->slots;
  size_t old_size = shard->size;
  size_t size = 16;
  size_t i;

  if ((shard->used + 1) * 2 <= shard->size) {
    return;
  }
  while (size < (shard->live + 1) * 4) {
    size *= 2;
  }
  shard->slots = (hilde_witness_entry_t*) calloc(size, sizeof(hilde_witness_entry_t));
  if (shard->slots == NULL) {
    hilde_task_die("Hilde: witness -- out of memory");
  }
  shard->size = size;
  shard->used = 0;
  shard->live = 0;
  for (i = 0; i < old_size; i++) {
    if (old[i].lock != NULL && old[i].lock != HILDE_WITNESS_GONE) {
      hilde_witness_entry_t* slot = hilde_witness_probe(shard, old[i].lock);

      *slot = old[i];
      shard->used++;
      shard->live++;
    }
  }
  free(old);
}

static hilde_witness_shard_t* hilde_witness_shard_of(const void* lock) {
  (void) pthread_once(&hilde_witness_once, hilde_witness_setup);
  return &hilde_witness_shards[hilde_witness_hash(lock) % HILDE_WITNESS_SHARDS];
}

/* lock, just made, is of kind from now on. */
static void hilde_witness_name(const void* lock, int kind) {
  hilde_witness_shard_t* shard = hilde_witness_shard_of(lock);
  hilde_witness_entry_t* slot;

  if (pthread_mutex_lock(&shard->lock) != 0) {
    hilde_task_die("Hilde: witness -- a lock of the checker failed");
  }
  hilde_witness_room(shard);
  slot = hilde_witness_probe(shard, lock);
  if (slot->lock == NULL) {
    slot->lock = lock;
    shard->used++;
    shard->live++;
  }
  slot->kind = kind;
  (void) pthread_mutex_unlock(&shard->lock);
}

/* lock is about to be destroyed. */
static void hilde_witness_forget(const void* lock) {
  hilde_witness_shard_t* shard = hilde_witness_shard_of(lock);

  if (pthread_mutex_lock(&shard->lock) != 0) {
    hilde_task_die("Hilde: witness -- a lock of the checker failed");
  }
  if (shard->size > 0) {
    hilde_witness_entry_t* slot = hilde_witness_probe(shard, lock);

    if (slot->lock == lock) {
      slot->lock = HILDE_WITNESS_GONE;
      slot->kind = -1;
      shard->live--;
    }
  }
  (void) pthread_mutex_unlock(&shard->lock);
}

/* The kind of lock, or -1 when it has none. */
static int hilde_witness_kind_of(const pthread_mutex_t* lock) {
  const char* at = (const char*) lock;
  hilde_witness_shard_t* shard;
  int kind = -1;

  if (lock == &hilde_task_setup_lock) {
    return HILDE_WITNESS_SETUP;
  }
  if (lock == &hilde_task_idle_lock) {
    return HILDE_WITNESS_IDLE;
  }
  if (lock == &hilde_task_fd_lock) {
    return HILDE_WITNESS_FD;
  }
  if (lock == &hilde_task_timer_lock) {
    return HILDE_WITNESS_TIMER;
  }
  if (lock == &hilde_task_call_lock) {
    return HILDE_WITNESS_CALL;
  }
  if (at >= (const char*) &hilde_task_workers[0] &&
      at < (const char*) &hilde_task_workers[HILDE_TASK_MAX_WORKERS]) {
    return HILDE_WITNESS_WORKER;
  }
  if (at >= (const char*) &hilde_task_buckets[0] &&
      at < (const char*) &hilde_task_buckets[HILDE_TASK_BUCKETS]) {
    return HILDE_WITNESS_BUCKET;
  }
  if (lock == &hilde_task_main.lock) {
    return HILDE_WITNESS_FIBER;
  }
  shard = hilde_witness_shard_of(lock);
  if (pthread_mutex_lock(&shard->lock) != 0) {
    hilde_task_die("Hilde: witness -- a lock of the checker failed");
  }
  if (shard->size > 0) {
    hilde_witness_entry_t* slot = hilde_witness_probe(shard, lock);

    if (slot->lock == lock) {
      kind = slot->kind;
    }
  }
  (void) pthread_mutex_unlock(&shard->lock);
  return kind;
}

/* The order of the kinds: order[a][b] is seen once a lock of kind b was
   taken while one of kind a was held, with the two places of the first
   time.  seen is written last, under the order's lock, and read without
   it. */
typedef struct hilde_witness_edge {
  int seen;
  hilde_witness_site_t held;
  hilde_witness_site_t taken;
} hilde_witness_edge_t;

static hilde_witness_edge_t hilde_witness_order[HILDE_WITNESS_KINDS][HILDE_WITNESS_KINDS];
static pthread_mutex_t hilde_witness_order_lock = PTHREAD_MUTEX_INITIALIZER;

/* With the order's lock held: 1 when the order leads from kind from to
   kind to, and then *step is the kind its first edge leads to. */
static int hilde_witness_leads(int from, int to, int* step) {
  int before[HILDE_WITNESS_KINDS];
  int queue[HILDE_WITNESS_KINDS];
  int head = 0;
  int tail = 0;
  int k;

  for (k = 0; k < HILDE_WITNESS_KINDS; k++) {
    before[k] = -2;
  }
  before[from] = -1;
  queue[tail++] = from;
  while (head < tail) {
    int at = queue[head++];

    for (k = 0; k < HILDE_WITNESS_KINDS; k++) {
      if (before[k] == -2 && hilde_witness_order[at][k].seen) {
        before[k] = at;
        if (k == to) {
          int back = k;

          while (before[back] != from) {
            back = before[back];
          }
          *step = back;
          return 1;
        }
        queue[tail++] = k;
      }
    }
  }
  return 0;
}

/* A new edge of the order, one line in the file HILDE_WITNESS_ORDER names
   when it is set: how a run tells what order it found. */
static void hilde_witness_note(int held, int taken, const hilde_witness_edge_t* edge) {
  extern char* getenv(const char* name);
  const char* path = getenv("HILDE_WITNESS_ORDER");
  hilde_witness_text_t t;
  int fd;

  if (path == NULL || path[0] == '\0') {
    return;
  }
  t.used = 0;
  t.text[0] = '\0';
  hilde_witness_add(&t, hilde_witness_kind_names[held]);
  hilde_witness_add(&t, " before ");
  hilde_witness_add(&t, hilde_witness_kind_names[taken]);
  hilde_witness_add(&t, ": ");
  hilde_witness_add_site(&t, &edge->held);
  hilde_witness_add(&t, " then ");
  hilde_witness_add_site(&t, &edge->taken);
  hilde_witness_add(&t, "\n");
  fd = open(path, O_WRONLY | O_APPEND | O_CREAT, 0644);
  if (fd >= 0) {
    ssize_t written = write(fd, t.text, t.used);

    (void) written;
    close(fd);
  }
}

/* A lock of kind taken at site while the lock of hold is held: the edge,
   unless it closes a cycle, which ends the programme. */
static void hilde_witness_edge(const hilde_witness_hold_t* hold, int kind,
                               const hilde_witness_site_t* site) {
  hilde_witness_edge_t* edge = &hilde_witness_order[hold->kind][kind];
  int step = -1;

  if (__atomic_load_n(&edge->seen, __ATOMIC_ACQUIRE)) {
    return;
  }
  if (pthread_mutex_lock(&hilde_witness_order_lock) != 0) {
    hilde_task_die("Hilde: witness -- a lock of the checker failed");
  }
  if (!edge->seen) {
    if (hilde_witness_leads(kind, hold->kind, &step)) {
      const hilde_witness_edge_t* first = &hilde_witness_order[kind][step];
      hilde_witness_text_t t;

      hilde_witness_begin(&t);
      hilde_witness_add(&t, "lock order reversed: ");
      hilde_witness_add_kind(&t, kind);
      hilde_witness_add(&t, " taken at ");
      hilde_witness_add_site(&t, site);
      hilde_witness_add(&t, " while ");
      hilde_witness_add_kind(&t, hold->kind);
      hilde_witness_add(&t, " is held, taken at ");
      hilde_witness_add_site(&t, &hold->site);
      hilde_witness_add(&t, "; before, ");
      hilde_witness_add_kind(&t, step);
      hilde_witness_add(&t, " was taken at ");
      hilde_witness_add_site(&t, &first->taken);
      hilde_witness_add(&t, " while ");
      hilde_witness_add_kind(&t, kind);
      hilde_witness_add(&t, " was held, taken at ");
      hilde_witness_add_site(&t, &first->held);
      if (step != hold->kind) {
        hilde_witness_add(&t, ", and the order went on from there to ");
        hilde_witness_add_kind(&t, hold->kind);
      }
      hilde_task_die(t.text);
    }
    edge->held = hold->site;
    edge->taken = *site;
    __atomic_store_n(&edge->seen, 1, __ATOMIC_RELEASE);
    hilde_witness_note(hold->kind, kind, edge);
  }
  (void) pthread_mutex_unlock(&hilde_witness_order_lock);
}

/* The calling thread's record, made at its first use.  Not inlined, and
   read after a barrier, for the reason hilde_task_here gives: a task that
   waited may go on on another thread. */
static __attribute__((noinline)) hilde_witness_thread_t* hilde_witness_self(void) {
  extern void* calloc(size_t count, size_t size);
  hilde_witness_thread_t* mine;

  __asm__ volatile ("" ::: "memory");
  mine = hilde_witness_mine;
  if (mine == NULL) {
    mine = (hilde_witness_thread_t*) calloc(1, sizeof(hilde_witness_thread_t));
    if (mine == NULL) {
      hilde_task_die("Hilde: witness -- out of memory");
    }
    (void) pthread_once(&hilde_witness_once, hilde_witness_setup);
    if (pthread_setspecific(hilde_witness_key, mine) != 0) {
      hilde_task_die("Hilde: witness -- the checker could not be set up");
    }
    hilde_witness_mine = mine;
  }
  return mine;
}

/* "<what> with a channel lock held, taken at <site>": the first lock the
   thread holds, which is the oldest. */
static _Noreturn void hilde_witness_held_stop(const char* what, const hilde_witness_hold_t* hold) {
  hilde_witness_text_t t;

  hilde_witness_begin(&t);
  hilde_witness_add(&t, what);
  hilde_witness_add(&t, " with ");
  hilde_witness_add_kind(&t, hold->kind);
  hilde_witness_add(&t, " held, taken at ");
  hilde_witness_add_site(&t, &hold->site);
  hilde_task_die(t.text);
}

static void hilde_witness_thread_ended(void* raw) {
  hilde_witness_thread_t* mine = (hilde_witness_thread_t*) raw;

  if (mine != NULL && mine->depth > 0) {
    hilde_witness_held_stop("a thread ended", &mine->held[0]);
  }
}

static __attribute__((noinline)) void hilde_witness_lock(pthread_mutex_t* lock, const char* function,
                                                         const char* file, int line) {
  hilde_witness_thread_t* mine = hilde_witness_self();
  hilde_witness_site_t site = { function, file, line };
  int kind = hilde_witness_kind_of(lock);
  hilde_witness_text_t t;
  int i;

  if (kind < 0) {
    hilde_witness_begin(&t);
    hilde_witness_add(&t, "a lock of no known kind taken at ");
    hilde_witness_add_site(&t, &site);
    hilde_task_die(t.text);
  }
  for (i = 0; i < mine->depth; i++) {
    if (mine->held[i].lock == lock) {
      hilde_witness_begin(&t);
      hilde_witness_add_kind(&t, kind);
      hilde_witness_add(&t, " taken at ");
      hilde_witness_add_site(&t, &site);
      hilde_witness_add(&t, " by the thread that holds it, taken at ");
      hilde_witness_add_site(&t, &mine->held[i].site);
      hilde_task_die(t.text);
    }
  }
  for (i = 0; i < mine->depth; i++) {
    const hilde_witness_hold_t* hold = &mine->held[i];

    if (hold->kind == kind) {
      if (kind == HILDE_WITNESS_CHANNEL && (uintptr_t) hold->lock < (uintptr_t) lock) {
        continue;
      }
      hilde_witness_begin(&t);
      hilde_witness_add(&t, "two ");
      hilde_witness_add(&t, hilde_witness_kind_names[kind]);
      hilde_witness_add(&t, " locks held at once");
      if (kind == HILDE_WITNESS_CHANNEL) {
        hilde_witness_add(&t, " against the order of their addresses");
      }
      hilde_witness_add(&t, ": one taken at ");
      hilde_witness_add_site(&t, &hold->site);
      hilde_witness_add(&t, ", the other at ");
      hilde_witness_add_site(&t, &site);
      hilde_task_die(t.text);
    }
    hilde_witness_edge(hold, kind, &site);
  }
  if (mine->depth == HILDE_WITNESS_DEPTH) {
    hilde_witness_begin(&t);
    hilde_witness_add(&t, "more than 16 locks held at once, the last taken at ");
    hilde_witness_add_site(&t, &site);
    hilde_task_die(t.text);
  }
  hilde_task_lock(lock);
  mine->held[mine->depth].lock = lock;
  mine->held[mine->depth].kind = kind;
  mine->held[mine->depth].site = site;
  mine->depth++;
}

static __attribute__((noinline)) void hilde_witness_unlock(pthread_mutex_t* lock, const char* function,
                                                           const char* file, int line) {
  hilde_witness_thread_t* mine = hilde_witness_self();
  int i;

  for (i = mine->depth - 1; i >= 0; i--) {
    if (mine->held[i].lock == lock) {
      break;
    }
  }
  if (i < 0) {
    hilde_witness_site_t site = { function, file, line };
    hilde_witness_text_t t;

    hilde_witness_begin(&t);
    hilde_witness_add_kind(&t, hilde_witness_kind_of(lock));
    hilde_witness_add(&t, " let go at ");
    hilde_witness_add_site(&t, &site);
    hilde_witness_add(&t, " by a thread that does not hold it");
    hilde_task_die(t.text);
  }
  for (; i + 1 < mine->depth; i++) {
    mine->held[i] = mine->held[i + 1];
  }
  mine->depth--;
  hilde_task_unlock(lock);
}

/* A switch between stacks: no lock may be held across it. */
static __attribute__((noinline)) void hilde_witness_switch(const char* what) {
  hilde_witness_thread_t* mine = hilde_witness_self();

  if (mine->depth > 0) {
    hilde_witness_held_stop(what, &mine->held[0]);
  }
}

/* A wait on the condition of lock: lock is held, and nothing else. */
static __attribute__((noinline)) void hilde_witness_wait(const pthread_mutex_t* lock, const char* function,
                                                         const char* file, int line) {
  hilde_witness_thread_t* mine = hilde_witness_self();
  hilde_witness_site_t site = { function, file, line };
  hilde_witness_text_t t;
  int i;

  for (i = 0; i < mine->depth; i++) {
    if (mine->held[i].lock != lock) {
      hilde_witness_begin(&t);
      hilde_witness_add(&t, "a wait on a condition at ");
      hilde_witness_add_site(&t, &site);
      hilde_witness_add(&t, " with ");
      hilde_witness_add_kind(&t, mine->held[i].kind);
      hilde_witness_add(&t, " held, taken at ");
      hilde_witness_add_site(&t, &mine->held[i].site);
      hilde_task_die(t.text);
    }
  }
  if (mine->depth != 1) {
    hilde_witness_begin(&t);
    hilde_witness_add(&t, "a wait on a condition at ");
    hilde_witness_add_site(&t, &site);
    hilde_witness_add(&t, " without ");
    hilde_witness_add_kind(&t, hilde_witness_kind_of(lock));
    hilde_witness_add(&t, " held");
    hilde_task_die(t.text);
  }
}

#undef HILDE_WITNESS_NAME
#undef HILDE_WITNESS_FORGET
#undef HILDE_WITNESS_SWITCH
#undef HILDE_WITNESS_WAIT
#define HILDE_WITNESS_NAME(lock, kind) hilde_witness_name((lock), (kind))
#define HILDE_WITNESS_FORGET(lock) hilde_witness_forget(lock)
#define HILDE_WITNESS_SWITCH(what) hilde_witness_switch(what)
#define HILDE_WITNESS_WAIT(lock) hilde_witness_wait((lock), __func__, __FILE__, __LINE__)
/* Every lock and unlock below goes through the checker, with its place. */
#define hilde_task_lock(lock) hilde_witness_lock((lock), __func__, __FILE__, __LINE__)
#define hilde_task_unlock(lock) hilde_witness_unlock((lock), __func__, __FILE__, __LINE__)
#endif

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

/* Once, at the first use of any task function: the interrupt pipe, the key
   table, and in a programme worker 0 and its stack.  In a programme this
   runs on the thread the process started on, where no other thread exists
   yet; in a library under hilde_task_setup_lock.  So nothing here races.
   1 when the runtime is ready.  0 when the interrupt pipe cannot be made,
   which happens when the process has used up its descriptors: that is a
   state its input can bring about, so it is an answer and not a stop.  The
   pipe comes first and nothing else is changed before it, so a later call
   tries again from the start. */
static int hilde_task_initialise(void) {
  hilde_task_worker_t* zero = &hilde_task_workers[0];
  size_t mapped = 0;
  unsigned char* mapping;
  int i;

  if (__atomic_load_n(&hilde_task_initialised, __ATOMIC_ACQUIRE)) {
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
  hilde_task_wanted = hilde_task_count_workers();
  if (HILDE_IN_LIBRARY) {
    /* No main and no stack for worker 0: its thread is started next, by
       hilde_task_ready, and schedules from its own stack. */
    __atomic_store_n(&hilde_task_initialised, 1, __ATOMIC_RELEASE);
    return 1;
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
  hilde_task_worker_of_thread = zero;
  __atomic_store_n(&hilde_task_initialised, 1, __ATOMIC_RELEASE);
  return 1;
}

static void* hilde_task_thread_main(void* raw);

static int hilde_task_started_count(void) {
  return __atomic_load_n(&hilde_task_started, __ATOMIC_ACQUIRE);
}

/* In a library: start the thread of worker 0, once.  1 when it runs, 0
   when the thread could not be made; a later call tries again.  The count
   goes up before the thread runs, as in hilde_task_start_workers. */
static int hilde_task_start_first(void) {
  hilde_task_worker_t* zero = &hilde_task_workers[0];

  if (hilde_task_started_count() > 0) {
    return 1;
  }
  hilde_task_lock(&hilde_task_idle_lock);
  __atomic_store_n(&hilde_task_started, 1, __ATOMIC_RELEASE);
  hilde_task_unlock(&hilde_task_idle_lock);
  if (pthread_create(&zero->thread, NULL, hilde_task_thread_main, (void*) zero) != 0) {
    hilde_task_lock(&hilde_task_idle_lock);
    __atomic_store_n(&hilde_task_started, 0, __ATOMIC_RELEASE);
    hilde_task_unlock(&hilde_task_idle_lock);
    return 0;
  }
  return 1;
}

/* Whether the runtime can be used by the calling thread, setting it up at
   the first call.  In a programme the thread that first uses a task becomes
   worker 0 and main runs on its stack.  A library is called from its
   host's threads, which it cannot take over, so it starts a thread of its
   own as worker 0, and every host's thread that calls it is a guest (see
   hilde_task_guest_t).  Several host threads may come here at once, so a
   library sets up under a lock.  0 also after the library stopped its
   workers. */
static int hilde_task_ready(void) {
  int ready;

  if (!HILDE_IN_LIBRARY) {
    return hilde_task_initialise();
  }
  if (__atomic_load_n(&hilde_task_stopping, __ATOMIC_ACQUIRE)) {
    return 0;
  }
  if (__atomic_load_n(&hilde_task_initialised, __ATOMIC_ACQUIRE) &&
      hilde_task_started_count() > 0) {
    return 1;
  }
  hilde_task_lock(&hilde_task_setup_lock);
  ready = !__atomic_load_n(&hilde_task_stopping, __ATOMIC_ACQUIRE) &&
          hilde_task_initialise() && hilde_task_start_first();
  hilde_task_unlock(&hilde_task_setup_lock);
  return ready;
}

/* 1 when the calling thread is a guest: a thread of a library's host,
   which is no worker. */
static int hilde_task_on_guest(void) {
  return HILDE_IN_LIBRARY && hilde_task_here() == NULL;
}

/* The fiber record of the calling guest, made at its first use. */
static hilde_task_fiber_t* hilde_task_guest_self(void) {
  hilde_task_guest_t* guest = &hilde_task_guest_of_thread;

  if (!guest->made) {
    if (pthread_mutex_init(&guest->lock, NULL) != 0 ||
        pthread_cond_init(&guest->wake, NULL) != 0 ||
        pthread_mutex_init(&guest->fiber.lock, NULL) != 0) {
      hilde_task_die("Hilde: the task runtime could not be set up");
    }
    HILDE_WITNESS_NAME(&guest->lock, HILDE_WITNESS_GUEST);
    HILDE_WITNESS_NAME(&guest->fiber.lock, HILDE_WITNESS_FIBER);
    guest->fiber.state = HILDE_TASK_RUNNING;
    guest->fiber.guest = 1;
    guest->fiber.wait_fd = -1;
    guest->made = 1;
  }
  return &guest->fiber;
}

/* The fiber running on the calling thread, or the guest's own record.
   Only called once the runtime is set up: every path that can come first
   -- opening a scope, yielding, waiting for a descriptor -- asks
   hilde_task_ready and answers without the runtime when it is not. */
static hilde_task_fiber_t* hilde_task_self(void) {
  if (!hilde_task_ready()) {
    hilde_task_die(HILDE_IN_LIBRARY
                   ? "Hilde: the task runtime could not make its interrupt pipe or its first worker"
                   : "Hilde: the task runtime could not make its interrupt pipe");
  }
  if (hilde_task_on_guest()) {
    return hilde_task_guest_self();
  }
  return hilde_task_here()->current;
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
    /* Made runnable by a helper thread or a library's guest, neither of
       which is a worker. */
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

/* A guest's half of a park, on its own thread: it blocks until a waker has
   marked it running again, unless a wake came while it was still leaving.
   The mark and the count of blocked guests change only under the guest's
   lock, so a worker that counts the guests never sees one blocked whose
   wake has already come.  An idle worker is told, so that one of them
   looks again at whether every task and every guest now waits. */
static void hilde_task_guest_wait(hilde_task_fiber_t* self) {
  hilde_task_guest_t* guest = (hilde_task_guest_t*) self;
  int expected = HILDE_TASK_PARK_LEAVING;

  hilde_task_lock(&guest->lock);
  if (__atomic_compare_exchange_n(&self->park, &expected,
                                  HILDE_TASK_PARK_PARKED, 0,
                                  __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
    __atomic_add_fetch(&hilde_task_guests_parked, 1, __ATOMIC_SEQ_CST);
    hilde_task_notify(HILDE_TASK_NOTIFY_RUNNABLE);
    while (__atomic_load_n(&self->park, __ATOMIC_ACQUIRE) != HILDE_TASK_PARK_NONE) {
      HILDE_WITNESS_WAIT(&guest->lock);
      if (pthread_cond_wait(&guest->wake, &guest->lock) != 0) {
        hilde_task_die("Hilde: a lock of the task runtime failed");
      }
    }
  } else {
    /* Woken while it was still leaving. */
    __atomic_store_n(&self->park, HILDE_TASK_PARK_NONE, __ATOMIC_RELEASE);
  }
  hilde_task_unlock(&guest->lock);
}

/* The waker's half for a blocked guest.  Nothing of the guest is read once
   its lock is let go: it may return from its call at once and its thread
   end. */
static void hilde_task_guest_wake(hilde_task_fiber_t* fiber) {
  hilde_task_guest_t* guest = (hilde_task_guest_t*) fiber;

  hilde_task_lock(&guest->lock);
  __atomic_sub_fetch(&hilde_task_guests_parked, 1, __ATOMIC_SEQ_CST);
  __atomic_store_n(&fiber->park, HILDE_TASK_PARK_NONE, __ATOMIC_RELEASE);
  if (pthread_cond_signal(&guest->wake) != 0) {
    hilde_task_die("Hilde: a lock of the task runtime failed");
  }
  hilde_task_unlock(&guest->lock);
}

/* The waker's half of the meeting on the park field.  The fiber has been
   taken out of whatever list it waited in.  If it has not finished leaving
   yet, the worker it is leaving will queue it, or a guest sees the wake
   itself; otherwise it is queued here, or the guest is woken. */
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
  if (fiber->guest) {
    hilde_task_guest_wake(fiber);
    return;
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

  if (!__atomic_load_n(&hilde_task_initialised, __ATOMIC_ACQUIRE)) {
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
   before the switch is used after it.  A guest has no worker to go back
   to: it waits on its own thread when it parks, and a yield has nothing
   to let run there. */
static void hilde_task_leave(int after) {
  hilde_task_worker_t* worker = hilde_task_here();
  hilde_task_fiber_t* self;
  const void* came_bottom = NULL;
  size_t came_size = 0;

  HILDE_WITNESS_SWITCH("a task gave up its worker");
  if (worker == NULL) {
    if (after == HILDE_TASK_AFTER_PARK) {
      hilde_task_guest_wait(hilde_task_guest_self());
    }
    return;
  }
  self = worker->current;
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
      /* who[at] is not NULL here.  The walk above filled who[1] to
         who[count] under the same hold of hilde_task_fd_lock that read
         count, and the list and the count change together under that lock,
         so the list held count fibers.  The static analyzer does not see
         this and reports a null dereference on the next line. */
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

/* Whether the guests leave nothing that could wake a task.  A programme
   has none, so 1.  A library's workers are all idle whenever no call of its
   host uses them, which is no deadlock; it is one only when some guest
   waits and every exported function that runs now belongs to a guest that
   waits. */
static int hilde_task_guests_all_wait(void) {
  int parked;

  if (!HILDE_IN_LIBRARY) {
    return 1;
  }
  parked = __atomic_load_n(&hilde_task_guests_parked, __ATOMIC_SEQ_CST);
  return parked > 0 && parked == __atomic_load_n(&hilde_library_calls, __ATOMIC_SEQ_CST);
}

/* A runnable fiber for worker, waiting for one when there is none; NULL
   once a library stops its workers.  This is also where a deadlock is
   recognised: the last worker to run out of work, with no fiber waiting
   for a descriptor, knows that nothing is left that could ever make a
   fiber runnable. */
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
    if (__atomic_load_n(&hilde_task_stopping, __ATOMIC_SEQ_CST)) {
      hilde_task_unlock(&hilde_task_idle_lock);
      return NULL;
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
        !hilde_task_main_is_runnable() &&
        hilde_task_guests_all_wait()) {
      hilde_task_die("Hilde: deadlock -- every task is waiting, and nothing is left that could wake one");
    }
    while (__atomic_load_n(&hilde_task_generation, __ATOMIC_SEQ_CST) == seen &&
           !__atomic_load_n(&hilde_task_stopping, __ATOMIC_SEQ_CST) &&
           !(!hilde_task_polling &&
             __atomic_load_n(&hilde_task_fd_count, __ATOMIC_SEQ_CST) > 0)) {
      int64_t deadline = hilde_task_next_deadline();

      /* Marked again on every round: a waker clears the mark when it
         signals, and a worker woken with nothing changed sleeps on. */
      worker->asleep = 1;
      HILDE_WITNESS_WAIT(&hilde_task_idle_lock);
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
static __attribute__((unused)) void hilde_task_preempt_check(void) {
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
   the workers do: in a programme as long as the process, in a library
   until it stops its workers. */
static void* hilde_task_monitor(void* unused) {
  unsigned long seen[HILDE_TASK_MAX_WORKERS];
  int i;

  (void) unused;
  for (i = 0; i < HILDE_TASK_MAX_WORKERS; i++) {
    seen[i] = 0;
  }
  while (!__atomic_load_n(&hilde_task_stopping, __ATOMIC_ACQUIRE)) {
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

/* The monitor's thread, which a library joins when it stops its workers;
   hilde_task_monitor_joinable is 1 once there is one to join. */
static pthread_t hilde_task_monitor_thread;
static int hilde_task_monitor_joinable = 0;    /* atomic */

/* Start the monitor, once, at the first spawn.  A monitor that cannot be
   started is not there: tasks then run until they wait, as before.  A
   programme never joins it; a library keeps it to join. */
static void hilde_task_start_monitor(void) {
  int expected = 0;

  if (!__atomic_compare_exchange_n(&hilde_task_monitor_started, &expected, 1, 0,
                                   __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
    return;
  }
  if (pthread_create(&hilde_task_monitor_thread, NULL, hilde_task_monitor, NULL) == 0) {
    if (HILDE_IN_LIBRARY) {
      __atomic_store_n(&hilde_task_monitor_joinable, 1, __ATOMIC_RELEASE);
    } else {
      (void) pthread_detach(hilde_task_monitor_thread);
    }
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
      HILDE_WITNESS_WAIT(&hilde_task_call_lock);
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

/* What every worker runs on its own stack, forever in a programme and in
   a library until it stops its workers: do what the last fiber left for,
   take a fiber, run it until it leaves.  The first step comes first
   because a programme's worker 0's stack is first entered when main
   leaves, through the trampoline and not through the switch below, and
   what main left for has to be done all the same. */
static void hilde_task_run_worker(hilde_task_worker_t* worker) {
  for (;;) {
    hilde_task_fiber_t* fiber;
    const void* came_bottom = NULL;
    size_t came_size = 0;

    hilde_task_after_leaving(worker);
    fiber = hilde_task_find(worker);
    if (fiber == NULL) {
      return;
    }
    worker->current = fiber;
    __atomic_add_fetch(&worker->runs, 1, __ATOMIC_ACQ_REL);
    __atomic_store_n(&worker->busy, 1, __ATOMIC_RELEASE);
    HILDE_WITNESS_SWITCH("a worker went to a task");
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
   worker 0.  In a programme the first spawn comes from main before any
   other worker runs; in a library several host threads may spawn first at
   once, so it starts them under hilde_task_setup_lock and looks again. */
static void hilde_task_start_workers_once(void) {
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

static void hilde_task_start_workers(void) {
  if (!HILDE_IN_LIBRARY) {
    hilde_task_start_workers_once();
    return;
  }
  if (hilde_task_started_count() > 1 || hilde_task_wanted <= 1) {
    return;
  }
  hilde_task_lock(&hilde_task_setup_lock);
  hilde_task_start_workers_once();
  hilde_task_unlock(&hilde_task_setup_lock);
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
  HILDE_WITNESS_NAME(&fiber->lock, HILDE_WITNESS_FIBER);
  mapping = (unsigned char*) hilde_task_map_stack(into->stack, &mapped);
  if (mapping == NULL) {
    HILDE_WITNESS_FORGET(&fiber->lock);
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
  HILDE_WITNESS_FORGET(&fiber->lock);
  pthread_mutex_destroy(&fiber->lock);
  hilde_task_deregister_stack(fiber);
  munmap(fiber->mapping, fiber->mapped);
#if defined(HILDE_TSAN)
  __tsan_destroy_fiber(fiber->tsan);
#endif
  free(fiber);
  return nil;
}

/* Without the runtime there is no other task to let run, and on a guest
   none runs on its thread. */
hilde_unit_t hilde_task_yield(void) {
  if (hilde_task_on_guest() || !hilde_task_ready()) {
    return nil;
  }
  (void) hilde_task_self();
  hilde_task_leave(HILDE_TASK_AFTER_READY);
  return nil;
}

/* The running task waits nanos nanoseconds while others run: it parks on
   a key of its own, which nothing but its timer wakes.  0 or less lets the
   others run once, as a yield does.  Without the runtime, and on a guest,
   whose thread runs nothing else, the calling thread waits itself. */
hilde_unit_t hilde_task_sleep_ns(int64_t nanos) {
  hilde_task_fiber_t* self;
  int64_t deadline;

  if (nanos <= 0) {
    return hilde_task_yield();
  }
  if (hilde_task_on_guest() || !hilde_task_ready()) {
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
   1 when it is, 0 when it failed or hung up without being ready.  A guest
   waits in poll(2) itself: its thread runs nothing else. */
int hilde_task_wait_fd(int fd, int what) {
  hilde_task_fiber_t* self;
  short want = (what == 2) ? POLLOUT : POLLIN;

  if (hilde_task_on_guest() || !hilde_task_ready()) {
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

  if (!__atomic_load_n(&hilde_task_initialised, __ATOMIC_ACQUIRE) || hilde_task_here() == NULL) {
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
  HILDE_WITNESS_NAME(&scope->lock, HILDE_WITNESS_SCOPE);
  scope->stack = stack;
  return (void*) scope;
}

void* hilde_task_scope_open(void) {
  return hilde_task_scope_open_sized(HILDE_TASK_STACK);
}

/* A lending scope is a scope; only the checker of lock order tells its
   lock from a plain scope's. */
static __attribute__((unused)) void* hilde_task_lending_open_sized(size_t stack) {
  void* scope = hilde_task_scope_open_sized(stack);

  if (scope != NULL) {
    HILDE_WITNESS_NAME(&((hilde_task_scope_t*) scope)->lock, HILDE_WITNESS_LENDING);
  }
  return scope;
}

static __attribute__((unused)) void* hilde_task_lending_open(void) {
  return hilde_task_lending_open_sized(HILDE_TASK_STACK);
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
   so that it does not step over the guard pages.  The place is the
   address of this function's frame, not of a local: AddressSanitizer may
   move locals to a stack of its own to find a use after return, and the
   address of such a local says nothing about the task's stack. */
size_t hilde_task_stack_left(void) {
  hilde_task_worker_t* worker = hilde_task_worker_of_thread;
  hilde_task_fiber_t* fiber;
  uintptr_t low;
  uintptr_t at;

  if (worker == NULL || worker->current == NULL || worker->current->mapping == NULL) {
    return SIZE_MAX;
  }
  fiber = worker->current;
  low = (uintptr_t) fiber->mapping + (uintptr_t) HILDE_TASK_GUARD_PAGES * (uintptr_t) hilde_arena_page_size();
  at = (uintptr_t) __builtin_frame_address(0);
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
  HILDE_WITNESS_FORGET(&scope->lock);
  pthread_mutex_destroy(&scope->lock);
  free(scope);
  return nil;
}

int hilde_task_available(void) {
  return 1;
}

/* A library stops its workers: by hilde_end, or when it is unloaded.  No
   exported function runs then, so no task runs, and every worker is idle
   or about to be; each is woken, sees the mark, leaves its loop and ends,
   and is joined, the monitor too.  Nothing when the runtime was never set
   up, when it is stopped already, and on a worker's own thread, which
   cannot join itself: a task that ends the process. */
static void hilde_task_library_stop(void) {
  int n;
  int i;

  if (!HILDE_IN_LIBRARY || hilde_task_here() != NULL) {
    return;
  }
  hilde_task_lock(&hilde_task_setup_lock);
  if (!__atomic_load_n(&hilde_task_initialised, __ATOMIC_ACQUIRE) ||
      __atomic_load_n(&hilde_task_stopping, __ATOMIC_ACQUIRE)) {
    hilde_task_unlock(&hilde_task_setup_lock);
    return;
  }
  hilde_task_lock(&hilde_task_idle_lock);
  __atomic_store_n(&hilde_task_stopping, 1, __ATOMIC_SEQ_CST);
  __atomic_add_fetch(&hilde_task_generation, 1, __ATOMIC_SEQ_CST);
  n = hilde_task_started_count();
  for (i = 0; i < n; i++) {
    hilde_task_workers[i].asleep = 0;
    pthread_cond_signal(&hilde_task_workers[i].wake);
  }
  if (hilde_task_polling) {
    hilde_task_interrupt_poller();
  }
  hilde_task_unlock(&hilde_task_idle_lock);
  for (i = 0; i < n; i++) {
    if (pthread_join(hilde_task_workers[i].thread, NULL) != 0) {
      hilde_task_die("Hilde: a worker of the task runtime could not be joined");
    }
  }
  if (__atomic_load_n(&hilde_task_monitor_joinable, __ATOMIC_ACQUIRE) &&
      pthread_join(hilde_task_monitor_thread, NULL) != 0) {
    hilde_task_die("Hilde: the monitor of the task runtime could not be joined");
  }
  hilde_task_unlock(&hilde_task_setup_lock);
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
  if (hilde_task_here() == NULL) {
    return 0;
  }
  return (int64_t) __atomic_load_n(&hilde_task_here()->runs, __ATOMIC_ACQUIRE);
}

/* How many workers this programme runs on, starting them if a spawn has not
   yet, and which one the calling task runs on at this moment.  No module
   calls them: they are for tests, which have to show that more than one
   worker ran their tasks, or a test that passes on one thread would say
   nothing about several.  A library's guest is on none of them: -1. */
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
  if (hilde_task_on_guest()) {
    return -1;
  }
  return (int32_t) hilde_task_here()->index;
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
  HILDE_WITNESS_NAME(&channel->lock, HILDE_WITNESS_CHANNEL);
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

  HILDE_WITNESS_FORGET(&channel->lock);
  pthread_mutex_destroy(&channel->lock);
  free(raw);
  return nil;
}
