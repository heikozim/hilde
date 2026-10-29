/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/*
 * Calls every function of libsperli with wrong input and holds the code it
 * answers with against the one the header promises.  The process must live
 * through all of it: a wrong argument is a code, never an exit.  Then it
 * joins a job of one rank and calls the functions in the right way.
 *
 *     test_sperli description-file checkpoint-directory
 *
 * The description file holds the line that libsperli/test/Describe.hiq prints.
 * Exit 0 when every check held, 1 when one failed, 2 on a wrong command line.
 */
#include "sperli.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int checks;
static int failures;

#define EXPECT(call, want) expect(#call, (call), (want), __LINE__)

static void expect(const char *what, int32_t got, int32_t want, int line) {
    checks++;
    if (got != want) {
        failures++;
        printf("FAIL line %d: %s answered %d (%s), wanted %d (%s)\n", line, what, (int) got, sperli_describe(got),
               (int) want, sperli_describe(want));
    }
}

#define EXPECT_TRUE(condition) expect_true(#condition, (condition), __LINE__)

static void expect_true(const char *what, int condition, int line) {
    checks++;
    if (!condition) {
        failures++;
        printf("FAIL line %d: %s\n", line, what);
    }
}

/* The calls with a handle that is none: every one answers SPERLI_E_BAD_HANDLE. */
static void with_dead_handle(sperli_t dead) {
    uint8_t byte = 1;
    uint32_t number = 0;
    size_t length = 7;
    uint8_t buffer[4];

    EXPECT(sperli_rank(dead, &number), SPERLI_E_BAD_HANDLE);
    EXPECT_TRUE(number == 0);
    EXPECT(sperli_size(dead, &number), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_send(dead, 0, 0, &byte, 1), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_recv(dead, 0, 0, &length), SPERLI_E_BAD_HANDLE);
    EXPECT_TRUE(length == 0);
    EXPECT(sperli_barrier(dead), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_bcast(dead, 0, &byte, 1, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_reduce(dead, 0, SPERLI_BYTES, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_allreduce(dead, SPERLI_BYTES, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_gather(dead, 0, &byte, 1, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_scatter(dead, 0, &byte, 1, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_result(dead, buffer, sizeof buffer, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_checkpoint_directory(dead, (const uint8_t *) "dir", 3), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_checkpoint(dead, &byte, 1), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_resume(dead, &length), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_finish(dead), SPERLI_E_BAD_HANDLE);
}

/* sperli_init with wrong arguments: the code, and *session stays 0. */
static void init_refusals(void) {
    sperli_t session = 99;
    const uint8_t text[] = "zz";
    const uint8_t hex[] = "00ff00ff";

    EXPECT(sperli_init(text, sizeof text - 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_init(NULL, 5, &session), SPERLI_E_NULL_POINTER);
    EXPECT_TRUE(session == 0);
    session = 99;
    EXPECT(sperli_init(NULL, 0, &session), SPERLI_E_NULL_POINTER);
    session = 99;
    EXPECT(sperli_init(text, 0, &session), SPERLI_E_BAD_LENGTH);
    EXPECT_TRUE(session == 0);
    session = 99;
    EXPECT(sperli_init(text, (size_t) SPERLI_MAX_DESCRIPTION + 1, &session), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_init(text, (size_t) -1, &session), SPERLI_E_BAD_LENGTH);
    session = 99;
    EXPECT(sperli_init(text, sizeof text - 1, &session), SPERLI_BAD_JOB);
    EXPECT_TRUE(session == 0);
    session = 99;
    EXPECT(sperli_init(hex, sizeof hex - 1, &session), SPERLI_BAD_JOB);
    EXPECT_TRUE(session == 0);
}

/* Wrong arguments with the live session: the code, and the session goes on. */
static void live_refusals(sperli_t live) {
    uint8_t byte = 1;
    uint8_t big[1];
    uint32_t number = 5;
    size_t length = 9;
    uint8_t buffer[8];
    const uint8_t zero_path[] = { 'a', 0, 'b' };

    /* Null pointers. */
    EXPECT(sperli_rank(live, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_size(live, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_send(live, 0, 0, NULL, 1), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_recv(live, 0, 0, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_bcast(live, 0, NULL, 1, &length), SPERLI_E_NULL_POINTER);
    EXPECT_TRUE(length == 0);
    length = 9;
    EXPECT(sperli_bcast(live, 0, &byte, 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_reduce(live, 0, SPERLI_BYTES, SPERLI_SUM, NULL, 1, &length), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_reduce(live, 0, SPERLI_BYTES, SPERLI_SUM, &byte, 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_allreduce(live, SPERLI_BYTES, SPERLI_SUM, NULL, 1, &length), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_allreduce(live, SPERLI_BYTES, SPERLI_SUM, &byte, 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_gather(live, 0, NULL, 1, &length), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_gather(live, 0, &byte, 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_scatter(live, 0, NULL, 1, &length), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_scatter(live, 0, &byte, 1, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_result(live, NULL, 4, &length), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_result(live, buffer, sizeof buffer, NULL), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_checkpoint_directory(live, NULL, 3), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_checkpoint(live, NULL, 1), SPERLI_E_NULL_POINTER);
    EXPECT(sperli_resume(live, NULL), SPERLI_E_NULL_POINTER);

    /* Lengths. */
    EXPECT(sperli_send(live, 0, 0, big, (size_t) SPERLI_MAX_MESSAGE + 1), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_send(live, 0, 0, big, (size_t) -1), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_bcast(live, 0, big, (size_t) SPERLI_MAX_COLLECTIVE + 1, &length), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_reduce(live, 0, SPERLI_BYTES, SPERLI_SUM, big, (size_t) SPERLI_MAX_COLLECTIVE + 1, &length),
           SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_allreduce(live, SPERLI_BYTES, SPERLI_SUM, big, (size_t) SPERLI_MAX_COLLECTIVE + 1, &length),
           SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_gather(live, 0, big, (size_t) SPERLI_MAX_COLLECTIVE + 1, &length), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_checkpoint_directory(live, (const uint8_t *) "d", 0), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_checkpoint_directory(live, (const uint8_t *) "d", (size_t) SPERLI_MAX_PATH + 1), SPERLI_E_BAD_LENGTH);
    EXPECT(sperli_checkpoint(live, big, (size_t) SPERLI_MAX_STATE + 1), SPERLI_E_BAD_LENGTH);

    /* Ranks: the job has one rank, so every peer is wrong. */
    EXPECT(sperli_send(live, 0, 0, &byte, 1), SPERLI_E_BAD_RANK);
    EXPECT(sperli_send(live, 1, 0, &byte, 1), SPERLI_E_BAD_RANK);
    EXPECT(sperli_send(live, 4095, 0, &byte, 1), SPERLI_E_BAD_RANK);
    EXPECT(sperli_send(live, 0xffffffffu, 0, &byte, 1), SPERLI_E_BAD_RANK);
    EXPECT(sperli_recv(live, 0, 0, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_recv(live, 1, 0, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_bcast(live, 1, &byte, 1, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_reduce(live, 1, SPERLI_BYTES, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_reduce(live, 0xffffffffu, SPERLI_BYTES, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_gather(live, 1, &byte, 1, &length), SPERLI_E_BAD_RANK);
    EXPECT(sperli_scatter(live, 1, &byte, 1, &length), SPERLI_E_BAD_RANK);

    /* Tags. */
    EXPECT(sperli_send(live, 0, 2147483648u, &byte, 1), SPERLI_E_BAD_TAG);
    EXPECT(sperli_recv(live, 0, 0xffffffffu, &length), SPERLI_E_BAD_TAG);

    /* Element types, reductions, counts. */
    EXPECT(sperli_reduce(live, 0, 7, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_TYPE);
    EXPECT(sperli_reduce(live, 0, 255, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_TYPE);
    EXPECT(sperli_reduce(live, 0, SPERLI_BYTES, 0, &byte, 1, &length), SPERLI_E_BAD_OPERATION);
    EXPECT(sperli_reduce(live, 0, SPERLI_BYTES, 11, &byte, 1, &length), SPERLI_E_BAD_OPERATION);
    EXPECT(sperli_reduce(live, 0, SPERLI_INT32, SPERLI_SUM, big, 3, &length), SPERLI_E_BAD_COUNT);
    EXPECT(sperli_reduce(live, 0, SPERLI_FLOAT64, SPERLI_SUM, big, 4, &length), SPERLI_E_BAD_COUNT);
    EXPECT(sperli_allreduce(live, 7, SPERLI_SUM, &byte, 1, &length), SPERLI_E_BAD_TYPE);
    EXPECT(sperli_allreduce(live, SPERLI_BYTES, 0, &byte, 1, &length), SPERLI_E_BAD_OPERATION);
    EXPECT(sperli_allreduce(live, SPERLI_UINT64, SPERLI_SUM, big, 5, &length), SPERLI_E_BAD_COUNT);

    /* Results and paths. */
    EXPECT(sperli_result(live, buffer, sizeof buffer, &length), SPERLI_E_NO_RESULT);
    EXPECT_TRUE(length == 0);
    EXPECT(sperli_checkpoint_directory(live, zero_path, sizeof zero_path), SPERLI_E_BAD_PATH);

    /* Two sessions in one process. */
    {
        sperli_t second = 99;
        const uint8_t text[] = "zz";
        EXPECT(sperli_init(text, sizeof text - 1, &second), SPERLI_E_ALREADY_INITIALISED);
        EXPECT_TRUE(second == 0);
    }

    /* A handle that is not the live one. */
    EXPECT(sperli_rank(live + 1, &number), SPERLI_E_BAD_HANDLE);
    EXPECT(sperli_barrier(live ^ 0x8000000000000000ull), SPERLI_E_BAD_HANDLE);

    /* A refused call changes nothing: the session still answers. */
    EXPECT(sperli_rank(live, &number), SPERLI_OK);
    EXPECT_TRUE(number == 0);
}

/* The right calls on a job of one rank, and the results they keep. */
static void live_calls(sperli_t live, const char *directory) {
    const uint8_t words[] = "hello";
    uint8_t numbers[8] = { 1, 0, 0, 0, 2, 0, 0, 0 };
    uint8_t buffer[16];
    size_t length = 0;
    size_t again = 0;
    uint32_t number = 7;

    EXPECT(sperli_size(live, &number), SPERLI_OK);
    EXPECT_TRUE(number == 1);
    EXPECT(sperli_barrier(live), SPERLI_OK);

    EXPECT(sperli_bcast(live, 0, words, 5, &length), SPERLI_OK);
    EXPECT_TRUE(length == 5);
    EXPECT(sperli_bcast(live, 0, words, 5, &again), SPERLI_E_RESULT_PENDING);
    EXPECT_TRUE(again == 0);
    EXPECT(sperli_gather(live, 0, words, 5, &again), SPERLI_E_RESULT_PENDING);
    EXPECT(sperli_resume(live, &again), SPERLI_E_RESULT_PENDING);
    EXPECT(sperli_result(live, buffer, 4, &again), SPERLI_E_BUFFER_TOO_SMALL);
    EXPECT_TRUE(again == 5);
    EXPECT(sperli_result(live, NULL, 0, &again), SPERLI_E_BUFFER_TOO_SMALL);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_OK);
    EXPECT_TRUE(again == 5);
    EXPECT_TRUE(memcmp(buffer, words, 5) == 0);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_E_NO_RESULT);

    EXPECT(sperli_allreduce(live, SPERLI_INT32, SPERLI_SUM, numbers, 8, &length), SPERLI_OK);
    EXPECT_TRUE(length == 8);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_OK);
    EXPECT_TRUE(memcmp(buffer, numbers, 8) == 0);

    EXPECT(sperli_reduce(live, 0, SPERLI_INT32, SPERLI_MAX, numbers, 8, &length), SPERLI_OK);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_OK);
    EXPECT(sperli_scatter(live, 0, words, 5, &length), SPERLI_OK);
    EXPECT_TRUE(length == 5);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_OK);
    EXPECT(sperli_gather(live, 0, NULL, 0, &length), SPERLI_OK);
    EXPECT_TRUE(length == 0);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_E_NO_RESULT);

    /* A checkpoint before a directory is named is refused with its code. */
    EXPECT(sperli_checkpoint(live, words, 5), SPERLI_CHECKPOINT_FAILED);
    EXPECT(sperli_checkpoint_directory(live, (const uint8_t *) directory, strlen(directory)), SPERLI_OK);
    EXPECT(sperli_checkpoint(live, words, 5), SPERLI_OK);
    EXPECT(sperli_resume(live, &length), SPERLI_OK);
    EXPECT_TRUE(length == 5);
    EXPECT(sperli_result(live, buffer, sizeof buffer, &again), SPERLI_OK);
    EXPECT_TRUE(memcmp(buffer, words, 5) == 0);
}

int main(int argc, char **argv) {
    FILE *file;
    static uint8_t description[SPERLI_MAX_DESCRIPTION];
    size_t used;
    sperli_t live = 0;

    if (argc != 3) {
        fprintf(stderr, "usage: test_sperli DESCRIPTION-FILE CHECKPOINT-DIRECTORY\n");
        return 2;
    }
    file = fopen(argv[1], "rb");
    if (file == NULL) {
        fprintf(stderr, "test_sperli: cannot open %s\n", argv[1]);
        return 2;
    }
    used = fread(description, 1, sizeof description, file);
    fclose(file);
    while (used > 0 && (description[used - 1] == '\n' || description[used - 1] == '\r')) {
        used--;
    }

    with_dead_handle(0);
    with_dead_handle(1);
    with_dead_handle(0xffffffffffffffffull);
    init_refusals();

    EXPECT(sperli_init(description, used, &live), SPERLI_OK);
    EXPECT_TRUE(live != 0);
    if (live == 0) {
        printf("test_sperli: no session, %d checks, %d failed\n", checks, failures);
        return 1;
    }
    live_refusals(live);
    live_calls(live, argv[2]);
    EXPECT(sperli_finish(live), SPERLI_OK);
    EXPECT(sperli_finish(live), SPERLI_E_BAD_HANDLE);
    with_dead_handle(live);

    /* The codes have words, and a number that is none has the word for it. */
    EXPECT_TRUE(strcmp(sperli_describe(SPERLI_OK), "success") == 0);
    EXPECT_TRUE(strcmp(sperli_describe(SPERLI_PEER_LOST), "the peer was lost") == 0);
    EXPECT_TRUE(strcmp(sperli_describe(424242), "unknown code") == 0);
    EXPECT_TRUE(strcmp(sperli_describe(-424242), "unknown code") == 0);

    printf("test_sperli: %d checks, %d failed\n", checks, failures);
    return failures == 0 ? 0 : 1;
}
