/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/*
 * A job of three ranks through libsperli, each rank a process of its own.
 *
 *     test_ranks description-file
 *
 * The description file holds the three lines that
 * libsperli/test/mixed/MixedDescribe.hiq prints for 3 ranks, rank 0 first.
 * The parent forks one child for each rank.  Rank i waits i seconds before
 * it joins, so that rank 0 comes first and finds no rank above it listening
 * yet: sperli_init then waits and tries again from the tasks of the
 * library, which is the path this test is for.  Each child joins the job
 * with sperli_init, checks its rank and the size, passes a barrier,
 * and calls sperli_allreduce with SPERLI_INT64 and SPERLI_SUM over the
 * value (rank + 1) * 10; every rank must get 60.  Before the barrier,
 * rank 0 waits in sperli_recv on a second thread for one byte that rank 1
 * sends two seconds after it joined; a call of the main thread made while
 * that receive waits must answer SPERLI_E_BUSY and change nothing, so the
 * barrier after it still meets the others.  Each child prints one line
 * (rank 0 one more for the busy call) and ends with 0 when every check
 * held.  The parent prints a line for
 * each child and a last line, and ends with 0 when all three held, 1 when
 * one did not, 2 on a wrong command line or file.  Each child has 90
 * seconds; alarm(2) ends it after that.
 */
#include "sperli.h"

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define RANKS 3
#define LINE_MOST 65536
#define LATE_TAG 9
#define LATE_BYTE 7

/* The lines of the description file, without their line ends. */
static char lines[RANKS][LINE_MOST];
static size_t lengths[RANKS];

static int read_lines(const char *path) {
    FILE *file = fopen(path, "r");
    int count = 0;

    if (file == NULL) {
        return 0;
    }
    while (count < RANKS && fgets(lines[count], LINE_MOST, file) != NULL) {
        size_t n = strlen(lines[count]);

        while (n > 0 && (lines[count][n - 1] == '\n' || lines[count][n - 1] == '\r')) {
            n--;
        }
        lengths[count] = n;
        count++;
    }
    fclose(file);
    return count == RANKS;
}

/* One rank, in its own process.  0 when every check held. */
struct waiting {
    sperli_t session;
    int32_t code;
    size_t length;
};

static void *wait_for_rank_1(void *argument) {
    struct waiting *waiting = argument;

    waiting->code = sperli_recv(waiting->session, 1, LATE_TAG, &waiting->length);
    return NULL;
}

/* Rank 0: a call while sperli_recv waits on another thread answers
 * SPERLI_E_BUSY; the receive then gets the late byte of rank 1. */
static int check_busy(sperli_t session) {
    struct waiting waiting = { session, -1, 0 };
    struct timespec pause = { 0, 500000000L };
    pthread_t thread;
    uint32_t rank = 99;
    uint8_t byte = 0;
    size_t length = 0;
    int32_t busy_rank;
    int32_t busy_barrier;

    if (pthread_create(&thread, NULL, wait_for_rank_1, &waiting) != 0) {
        printf("rank 0: no second thread\n");
        return 1;
    }
    nanosleep(&pause, NULL);
    busy_rank = sperli_rank(session, &rank);
    busy_barrier = sperli_barrier(session);
    pthread_join(thread, NULL);
    if (busy_rank != SPERLI_E_BUSY || busy_barrier != SPERLI_E_BUSY) {
        printf("rank 0: sperli_rank answered %d and sperli_barrier %d while sperli_recv waited, wanted %d\n",
               (int) busy_rank, (int) busy_barrier, (int) SPERLI_E_BUSY);
        return 1;
    }
    if (waiting.code != SPERLI_OK || waiting.length != 1 ||
        sperli_result(session, &byte, sizeof byte, &length) != SPERLI_OK || byte != LATE_BYTE) {
        printf("rank 0: the waiting sperli_recv answered %d with %zu bytes and the byte %d\n", (int) waiting.code,
               waiting.length, (int) byte);
        return 1;
    }
    printf("rank 0: a call while sperli_recv waited answered %d (%s)\n", (int) busy_rank,
           sperli_describe(busy_rank));
    return 0;
}

static int run_rank(int index) {
    sperli_t session = 0;
    uint32_t rank = 99;
    uint32_t size = 0;
    int64_t value = ((int64_t) index + 1) * 10;
    int64_t total = 0;
    size_t length = 0;
    int32_t code;

    alarm(90);
    sleep((unsigned) index);
    code = sperli_init((const uint8_t *) lines[index], lengths[index], &session);
    if (code != SPERLI_OK) {
        printf("rank %d: sperli_init answered %d (%s)\n", index, (int) code, sperli_describe(code));
        return 1;
    }
    if (sperli_rank(session, &rank) != SPERLI_OK || sperli_size(session, &size) != SPERLI_OK ||
        rank != (uint32_t) index || size != RANKS) {
        printf("rank %d: rank %u and size %u, wanted %d and %d\n", index, (unsigned) rank, (unsigned) size, index,
               RANKS);
        return 1;
    }
    if (index == 0 && check_busy(session) != 0) {
        return 1;
    }
    if (index == 1) {
        uint8_t late = LATE_BYTE;

        sleep(2);
        code = sperli_send(session, 0, LATE_TAG, &late, sizeof late);
        if (code != SPERLI_OK) {
            printf("rank 1: sperli_send answered %d (%s)\n", (int) code, sperli_describe(code));
            return 1;
        }
    }
    code = sperli_barrier(session);
    if (code != SPERLI_OK) {
        printf("rank %d: sperli_barrier answered %d (%s)\n", index, (int) code, sperli_describe(code));
        return 1;
    }
    code = sperli_allreduce(session, SPERLI_INT64, SPERLI_SUM, (const uint8_t *) &value, sizeof value, &length);
    if (code != SPERLI_OK || length != sizeof total) {
        printf("rank %d: sperli_allreduce answered %d (%s) with %zu bytes\n", index, (int) code,
               sperli_describe(code), length);
        return 1;
    }
    code = sperli_result(session, (uint8_t *) &total, sizeof total, &length);
    if (code != SPERLI_OK || total != 60) {
        printf("rank %d: sperli_result answered %d with the total %lld, wanted 60\n", index, (int) code,
               (long long) total);
        return 1;
    }
    code = sperli_finish(session);
    if (code != SPERLI_OK) {
        printf("rank %d: sperli_finish answered %d (%s)\n", index, (int) code, sperli_describe(code));
        return 1;
    }
    printf("rank %d: size %u, gave %lld, allreduce sum %lld\n", index, (unsigned) size, (long long) value,
           (long long) total);
    return 0;
}

int main(int argc, char **argv) {
    pid_t children[RANKS];
    int held = 0;
    int i;

    if (argc != 2 || !read_lines(argv[1])) {
        fprintf(stderr, "test_ranks: give the file with the %d lines of a job of %d ranks\n", RANKS, RANKS);
        return 2;
    }
    fflush(stdout);
    for (i = 0; i < RANKS; i++) {
        children[i] = fork();
        if (children[i] < 0) {
            perror("test_ranks: fork");
            return 1;
        }
        if (children[i] == 0) {
            int status = run_rank(i);

            fflush(stdout);
            _exit(status);
        }
    }
    for (i = 0; i < RANKS; i++) {
        int status = 0;

        if (waitpid(children[i], &status, 0) != children[i]) {
            printf("test_ranks: rank %d could not be waited for\n", i);
            continue;
        }
        if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            held++;
            printf("test_ranks: rank %d ended with 0\n", i);
        } else if (WIFSIGNALED(status)) {
            printf("test_ranks: rank %d ended by signal %d\n", i, WTERMSIG(status));
        } else {
            printf("test_ranks: rank %d ended with %d\n", i, WEXITSTATUS(status));
        }
    }
    printf("test_ranks: %d of %d ranks held\n", held, RANKS);
    return held == RANKS ? 0 : 1;
}
