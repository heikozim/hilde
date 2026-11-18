/*
 * The host of the library Test.hiq is built as: THREADS threads of its own
 * call sum_in_tasks at the same moment, CALLS times each, every call with
 * a first number of its own, and each result is held against the sum
 * worked out here.  The threads wait at a gate until all of them are made,
 * so that the calls overlap.  Prints the number of calls and of wrong
 * results, calls hilde_end, which stops the library's workers, and prints
 * a last line after it.
 */
#define _POSIX_C_SOURCE 200809L

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>

#define THREADS 8
#define CALLS 25

void hilde_start(void);
void hilde_end(void);
int64_t sum_in_tasks(int64_t first);

static pthread_mutex_t gate_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gate_open = PTHREAD_COND_INITIALIZER;
static int gate_waiting = 0;

static int wrong[THREADS];
static int calls[THREADS];

/* The squares of first to first + 3999 and the 4950 of the channel. */
static int64_t expected(int64_t first) {
  int64_t sum = 4950;
  int64_t k;

  for (k = first; k < first + 4000; k++) {
    sum += k * k;
  }
  return sum;
}

/* Blocks until every thread has come here. */
static void pass_gate(void) {
  pthread_mutex_lock(&gate_lock);
  gate_waiting++;
  if (gate_waiting == THREADS) {
    pthread_cond_broadcast(&gate_open);
  }
  while (gate_waiting < THREADS) {
    pthread_cond_wait(&gate_open, &gate_lock);
  }
  pthread_mutex_unlock(&gate_lock);
}

static void* caller(void* raw) {
  int index = (int) (intptr_t) raw;
  int call;

  pass_gate();
  for (call = 0; call < CALLS; call++) {
    int64_t first = ((int64_t) index * 100000) + ((int64_t) call * 4000);
    int64_t got = sum_in_tasks(first);

    calls[index]++;
    if (got != expected(first)) {
      wrong[index]++;
      fprintf(stderr, "host: thread %d call %d: %lld, wanted %lld\n", index, call,
              (long long) got, (long long) expected(first));
    }
  }
  return NULL;
}

int main(void) {
  pthread_t threads[THREADS];
  int made = 0;
  int total = 0;
  int bad = 0;
  int i;

  hilde_start();
  for (i = 0; i < THREADS; i++) {
    if (pthread_create(&threads[i], NULL, caller, (void*) (intptr_t) i) != 0) {
      break;
    }
    made++;
  }
  if (made < THREADS) {
    printf("host: only %d of %d threads made\n", made, THREADS);
    return 1;
  }
  for (i = 0; i < THREADS; i++) {
    pthread_join(threads[i], NULL);
    total += calls[i];
    bad += wrong[i];
  }
  printf("threads=%d calls=%d wrong=%d\n", THREADS, total, bad);
  hilde_end();
  printf("ended\n");
  return bad == 0 ? 0 : 1;
}
