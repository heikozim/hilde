/*
    Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
    See LICENSE file for details.

    Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
    SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*/

/*
 * A rank of the benchmark written in C over libsperli, with the modes and
 * the output of examples/sperli-bench, so that it pairs with a Hilde rank
 * or with itself.  It reads its job description as one line on the
 * standard input.
 *
 *     bench_rank ping <count> <bytes>     rank 0: round trips, mean and least time
 *     bench_rank echo <count> <bytes>     rank 1: sends every message back
 *     bench_rank stream <count> <bytes>   rank 0: messages one way, then the rate
 *     bench_rank sink <count> <bytes>     rank 1: takes them, answers the byte count
 *
 * Exit 0 when the run finished, 1 when a call failed, 2 on bad arguments.
 */

#include "sperli.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define LINE_MOST 65536

static char line[LINE_MOST];

static uint64_t now_nanos(void) {
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return 0;
    }
    return (uint64_t) ts.tv_sec * 1000000000u + (uint64_t) ts.tv_nsec;
}

/* The message the last recv holds, into buffer of capacity bytes; its
   length in *length.  SPERLI_OK or the code. */
static int32_t take(sperli_t session, uint8_t *buffer, size_t capacity, size_t *length) {
    return sperli_result(session, buffer, capacity, length);
}

static int ping(sperli_t session, uint64_t count, size_t bytes, uint8_t *message, uint8_t *answer) {
    uint64_t total = 0;
    uint64_t least = UINT64_MAX;

    for (uint64_t done = 0; done < count; done++) {
        size_t held = 0;
        size_t got = 0;
        uint64_t start = now_nanos();
        int32_t code = sperli_send(session, 1, 1, message, bytes);
        if (code != SPERLI_OK) {
            printf("send failed with %d\n", code);
            return 1;
        }
        code = sperli_recv(session, 1, 1, &held);
        if (code == SPERLI_OK) {
            code = take(session, answer, bytes, &got);
        }
        if (code != SPERLI_OK || got != bytes) {
            printf("recv failed with %d\n", code);
            return 1;
        }
        uint64_t spent = now_nanos() - start;
        total += spent;
        if (spent < least) {
            least = spent;
        }
    }
    printf("ping count=%llu bytes=%zu mean_us=%llu min_us=%llu\n", (unsigned long long) count, bytes,
           (unsigned long long) (count > 0 ? total / count / 1000 : 0), (unsigned long long) (least / 1000));
    return 0;
}

static int echo(sperli_t session, uint64_t count, size_t bytes, uint8_t *answer) {
    for (uint64_t done = 0; done < count; done++) {
        size_t held = 0;
        size_t got = 0;
        int32_t code = sperli_recv(session, 0, 1, &held);
        if (code == SPERLI_OK) {
            code = take(session, answer, bytes, &got);
        }
        if (code == SPERLI_OK) {
            code = sperli_send(session, 0, 1, answer, got);
        }
        if (code != SPERLI_OK) {
            printf("echo failed with %d\n", code);
            return 1;
        }
    }
    return 0;
}

static int stream(sperli_t session, uint64_t count, size_t bytes, uint8_t *message) {
    uint64_t start = now_nanos();
    uint8_t answer[8];
    size_t held = 0;
    size_t got = 0;

    for (uint64_t done = 0; done < count; done++) {
        int32_t code = sperli_send(session, 1, 2, message, bytes);
        if (code != SPERLI_OK) {
            printf("send failed with %d\n", code);
            return 1;
        }
    }
    int32_t code = sperli_recv(session, 1, 2, &held);
    if (code == SPERLI_OK) {
        code = take(session, answer, sizeof answer, &got);
    }
    if (code != SPERLI_OK || got != sizeof answer) {
        printf("recv failed with %d\n", code);
        return 1;
    }
    uint64_t spent = now_nanos() - start;
    uint64_t counted = 0;
    for (int i = 7; i >= 0; i--) {
        counted = counted * 256 + answer[i];
    }
    uint64_t sent = count * (uint64_t) bytes;
    if (counted != sent) {
        printf("the sink counted %llu\n", (unsigned long long) counted);
        return 1;
    }
    uint64_t tenths = spent > 0 ? sent * 10000u / spent : 0;
    printf("stream count=%llu bytes=%zu total_bytes=%llu ms=%llu mb_per_s=%llu.%llu\n", (unsigned long long) count,
           bytes, (unsigned long long) sent, (unsigned long long) (spent / 1000000),
           (unsigned long long) (tenths / 10), (unsigned long long) (tenths % 10));
    return 0;
}

static int sink(sperli_t session, uint64_t count, size_t bytes, uint8_t *answer) {
    uint64_t total = 0;
    uint8_t counted[8];

    for (uint64_t done = 0; done < count; done++) {
        size_t held = 0;
        size_t got = 0;
        int32_t code = sperli_recv(session, 0, 2, &held);
        if (code == SPERLI_OK) {
            code = take(session, answer, bytes, &got);
        }
        if (code != SPERLI_OK) {
            printf("sink failed with %d\n", code);
            return 1;
        }
        total += got;
    }
    for (int i = 0; i < 8; i++) {
        counted[i] = (uint8_t) (total >> (8 * i));
    }
    int32_t code = sperli_send(session, 0, 2, counted, sizeof counted);
    if (code != SPERLI_OK) {
        printf("send failed with %d\n", code);
        return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
    sperli_t session;
    char *end = NULL;

    if (argc != 4) {
        fprintf(stderr, "usage: bench_rank ping|echo|stream|sink <count> <bytes>\n");
        return 2;
    }
    unsigned long long count = strtoull(argv[2], &end, 10);
    if (end == argv[2] || *end != '\0') {
        return 2;
    }
    unsigned long long bytes = strtoull(argv[3], &end, 10);
    if (end == argv[3] || *end != '\0' || bytes == 0 || bytes > 16777216u) {
        return 2;
    }
    if (fgets(line, sizeof line, stdin) == NULL) {
        fprintf(stderr, "bench_rank: no job description\n");
        return 2;
    }
    size_t length = strcspn(line, "\r\n");
    int32_t code = sperli_init((const uint8_t *) line, length, &session);
    if (code != SPERLI_OK) {
        printf("init failed with %d (%s)\n", code, sperli_describe(code));
        return 1;
    }
    uint8_t *message = malloc((size_t) bytes);
    uint8_t *answer = malloc((size_t) bytes);
    if (message == NULL || answer == NULL) {
        free(message);
        free(answer);
        sperli_finish(session);
        return 1;
    }
    memset(message, 97, (size_t) bytes);
    int result = 2;
    if (strcmp(argv[1], "ping") == 0) {
        result = ping(session, count, (size_t) bytes, message, answer);
    } else if (strcmp(argv[1], "echo") == 0) {
        result = echo(session, count, (size_t) bytes, answer);
    } else if (strcmp(argv[1], "stream") == 0) {
        result = stream(session, count, (size_t) bytes, message);
    } else if (strcmp(argv[1], "sink") == 0) {
        result = sink(session, count, (size_t) bytes, answer);
    }
    free(message);
    free(answer);
    code = sperli_finish(session);
    if (result == 0 && code != SPERLI_OK) {
        printf("finish failed with %d\n", code);
        result = 1;
    }
    return result;
}
