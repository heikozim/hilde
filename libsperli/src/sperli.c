/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/*
 * The public functions of libsperli.  Each checks all of its arguments and
 * answers with a code before it calls the core, the functions that
 * Standard.SperliExport exports.  The core would stop the process on an
 * argument its contracts refuse, and the runtime stops it on a null handle
 * or on two calls at once, so none of that may reach it.
 */
#include "sperli.h"
#include "libsperli_core.h"

#include <stdatomic.h>
#include <string.h>

typedef hilde_handle_Standard_SperliExport_Session core_session;

/* The codes of the core that are not codes of the job. */
enum {
    CORE_NOT_READY = -6,
    CORE_NO_RESULT = -10,
    CORE_RESULT_PENDING = -11
};

/*
 * The state of the process.  busy is 1 while a call runs.  live is the
 * handle of the session, 0 for none; session, rank and size describe it.
 */
static struct {
    atomic_int busy;
    int started;
    uint64_t generation;
    uint64_t live;
    core_session *session;
    uint32_t rank;
    uint32_t size;
} state;

/* A byte for the core to read when the caller gave none. */
static const uint8_t no_bytes[1] = { 0 };

static int enter(void) {
    int expected = 0;
    return atomic_compare_exchange_strong(&state.busy, &expected, 1);
}

static void leave(void) {
    atomic_store(&state.busy, 0);
}

/* The code the caller sees for a code of the core. */
static int32_t outward(int32_t code) {
    if (code == 0 || (code >= SPERLI_BAD_CERTIFICATE && code <= SPERLI_CHECKPOINT_FAILED)) {
        return code;
    }
    switch (code) {
    case CORE_NOT_READY: return SPERLI_E_NOT_READY;
    case CORE_NO_RESULT: return SPERLI_E_NO_RESULT;
    case CORE_RESULT_PENDING: return SPERLI_E_RESULT_PENDING;
    default: return SPERLI_E_INTERNAL;
    }
}

/* Whether handle is the live session. */
static int is_live(sperli_t handle) {
    return handle != 0 && handle == state.live && state.session != NULL;
}

/* The bytes to hand to the core: the caller's, or one byte when length is 0. */
static const uint8_t *bytes_of(const uint8_t *data, size_t length) {
    return length == 0 ? no_bytes : data;
}

/* The code of a call that makes a result; *length is the kept length, 0 on failure. */
static int32_t made_result(int32_t code, size_t *length) {
    int32_t out = outward(code);
    *length = out == SPERLI_OK ? sperli_core_result_length(state.session) : 0;
    return out;
}

/* The width in bytes of one element of type, 0 for a type that is none. */
static size_t width_of(uint8_t type) {
    switch (type) {
    case SPERLI_BYTES: return 1;
    case SPERLI_INT32: case SPERLI_UINT32: case SPERLI_FLOAT32: return 4;
    case SPERLI_INT64: case SPERLI_UINT64: case SPERLI_FLOAT64: return 8;
    default: return 0;
    }
}

/* Takes the lock and checks the handle; leaves the function with the code when either fails. */
#define BEGIN(handle) \
    if (!enter()) { \
        return SPERLI_E_BUSY; \
    } \
    if (!is_live(handle)) { \
        leave(); \
        return SPERLI_E_BAD_HANDLE; \
    }

/* Gives the lock back and leaves the function with code. */
#define DONE(code) \
    do { \
        int32_t done_code = (code); \
        leave(); \
        return done_code; \
    } while (0)

int32_t sperli_init(const uint8_t *description, size_t length, sperli_t *session) {
    if (session == NULL) {
        return SPERLI_E_NULL_POINTER;
    }
    *session = 0;
    if (!enter()) {
        return SPERLI_E_BUSY;
    }
    if (state.live != 0) {
        DONE(SPERLI_E_ALREADY_INITIALISED);
    }
    if (description == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length == 0 || length > SPERLI_MAX_DESCRIPTION) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    if (!state.started) {
        hilde_start();
        state.started = 1;
    }
    core_session *opened = sperli_core_open(description, length);
    int32_t code = outward(sperli_core_code(opened));
    if (code != SPERLI_OK) {
        sperli_core_close(opened);
        DONE(code);
    }
    state.generation++;
    state.live = state.generation;
    state.session = opened;
    state.rank = sperli_core_rank(opened);
    state.size = sperli_core_size(opened);
    *session = state.live;
    DONE(SPERLI_OK);
}

int32_t sperli_rank(sperli_t session, uint32_t *rank) {
    if (rank != NULL) {
        *rank = 0;
    }
    BEGIN(session)
    if (rank == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    *rank = state.rank;
    DONE(SPERLI_OK);
}

int32_t sperli_size(sperli_t session, uint32_t *size) {
    if (size != NULL) {
        *size = 0;
    }
    BEGIN(session)
    if (size == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    *size = state.size;
    DONE(SPERLI_OK);
}

int32_t sperli_send(sperli_t session, uint32_t target, uint32_t tag, const uint8_t *data, size_t length) {
    BEGIN(session)
    if (data == NULL && length > 0) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length > SPERLI_MAX_MESSAGE) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    if (tag > SPERLI_MAX_TAG) {
        DONE(SPERLI_E_BAD_TAG);
    }
    if (target >= state.size || target == state.rank) {
        DONE(SPERLI_E_BAD_RANK);
    }
    DONE(outward(sperli_core_send(state.session, target, tag, bytes_of(data, length), length)));
}

int32_t sperli_recv(sperli_t session, uint32_t source, uint32_t tag, size_t *length) {
    if (length != NULL) {
        *length = 0;
    }
    BEGIN(session)
    if (length == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (tag > SPERLI_MAX_TAG) {
        DONE(SPERLI_E_BAD_TAG);
    }
    if (source >= state.size || source == state.rank) {
        DONE(SPERLI_E_BAD_RANK);
    }
    DONE(made_result(sperli_core_recv(state.session, source, tag), length));
}

int32_t sperli_barrier(sperli_t session) {
    BEGIN(session)
    DONE(outward(sperli_core_barrier(state.session)));
}

int32_t sperli_bcast(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length) {
    if (result_length != NULL) {
        *result_length = 0;
    }
    BEGIN(session)
    if (result_length == NULL || (data == NULL && length > 0)) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length > SPERLI_MAX_COLLECTIVE) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    if (root >= state.size) {
        DONE(SPERLI_E_BAD_RANK);
    }
    size_t used = root == state.rank ? length : 0;
    DONE(made_result(sperli_core_bcast(state.session, root, bytes_of(data, used), used), result_length));
}

/* The checks reduce and allreduce share, after the handle; SPERLI_OK when they hold. */
static int32_t check_reduction(uint8_t type, uint8_t operation, const uint8_t *data, size_t length,
                               size_t *result_length) {
    if (result_length == NULL || (data == NULL && length > 0)) {
        return SPERLI_E_NULL_POINTER;
    }
    if (length > SPERLI_MAX_COLLECTIVE) {
        return SPERLI_E_BAD_LENGTH;
    }
    if (width_of(type) == 0) {
        return SPERLI_E_BAD_TYPE;
    }
    if (operation < SPERLI_SUM || operation > SPERLI_BXOR) {
        return SPERLI_E_BAD_OPERATION;
    }
    if (length % width_of(type) != 0) {
        return SPERLI_E_BAD_COUNT;
    }
    return SPERLI_OK;
}

int32_t sperli_reduce(sperli_t session, uint32_t root, uint8_t type, uint8_t operation,
                      const uint8_t *data, size_t length, size_t *result_length) {
    if (result_length != NULL) {
        *result_length = 0;
    }
    BEGIN(session)
    int32_t bad = check_reduction(type, operation, data, length, result_length);
    if (bad != SPERLI_OK) {
        DONE(bad);
    }
    if (root >= state.size) {
        DONE(SPERLI_E_BAD_RANK);
    }
    DONE(made_result(sperli_core_reduce(state.session, root, type, operation, bytes_of(data, length), length),
                     result_length));
}

int32_t sperli_allreduce(sperli_t session, uint8_t type, uint8_t operation,
                         const uint8_t *data, size_t length, size_t *result_length) {
    if (result_length != NULL) {
        *result_length = 0;
    }
    BEGIN(session)
    int32_t bad = check_reduction(type, operation, data, length, result_length);
    if (bad != SPERLI_OK) {
        DONE(bad);
    }
    DONE(made_result(sperli_core_allreduce(state.session, type, operation, bytes_of(data, length), length),
                     result_length));
}

int32_t sperli_gather(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length) {
    if (result_length != NULL) {
        *result_length = 0;
    }
    BEGIN(session)
    if (result_length == NULL || (data == NULL && length > 0)) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length > SPERLI_MAX_COLLECTIVE) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    if (root >= state.size) {
        DONE(SPERLI_E_BAD_RANK);
    }
    DONE(made_result(sperli_core_gather(state.session, root, bytes_of(data, length), length), result_length));
}

int32_t sperli_scatter(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length) {
    if (result_length != NULL) {
        *result_length = 0;
    }
    BEGIN(session)
    if (result_length == NULL || (data == NULL && length > 0)) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (root >= state.size) {
        DONE(SPERLI_E_BAD_RANK);
    }
    size_t used = 0;
    if (root == state.rank) {
        if (length / state.size > SPERLI_MAX_COLLECTIVE) {
            DONE(SPERLI_E_BAD_LENGTH);
        }
        if (length % state.size != 0) {
            DONE(SPERLI_E_BAD_COUNT);
        }
        used = length;
    }
    DONE(made_result(sperli_core_scatter(state.session, root, bytes_of(data, used), used), result_length));
}

int32_t sperli_result(sperli_t session, uint8_t *buffer, size_t capacity, size_t *length) {
    if (length != NULL) {
        *length = 0;
    }
    BEGIN(session)
    if (length == NULL || (buffer == NULL && capacity > 0)) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    size_t held = sperli_core_result_length(state.session);
    if (held == 0) {
        DONE(SPERLI_E_NO_RESULT);
    }
    *length = held;
    if (capacity < held) {
        DONE(SPERLI_E_BUFFER_TOO_SMALL);
    }
    DONE(outward(sperli_core_take_result(state.session, buffer, held)));
}

int32_t sperli_checkpoint_directory(sperli_t session, const uint8_t *path, size_t length) {
    BEGIN(session)
    if (path == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length == 0 || length > SPERLI_MAX_PATH) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    if (memchr(path, 0, length) != NULL) {
        DONE(SPERLI_E_BAD_PATH);
    }
    DONE(outward(sperli_core_use_checkpoints(state.session, path, length)));
}

int32_t sperli_checkpoint(sperli_t session, const uint8_t *data, size_t length) {
    BEGIN(session)
    if (data == NULL && length > 0) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    if (length > SPERLI_MAX_STATE) {
        DONE(SPERLI_E_BAD_LENGTH);
    }
    DONE(outward(sperli_core_checkpoint(state.session, bytes_of(data, length), length)));
}

int32_t sperli_resume(sperli_t session, size_t *length) {
    if (length != NULL) {
        *length = 0;
    }
    BEGIN(session)
    if (length == NULL) {
        DONE(SPERLI_E_NULL_POINTER);
    }
    DONE(made_result(sperli_core_resume(state.session), length));
}

int32_t sperli_finish(sperli_t session) {
    BEGIN(session)
    core_session *closing = state.session;
    state.session = NULL;
    state.live = 0;
    state.rank = 0;
    state.size = 0;
    sperli_core_close(closing);
    DONE(SPERLI_OK);
}

const char *sperli_describe(int32_t code) {
    switch (code) {
    case SPERLI_OK: return "success";
    case SPERLI_E_NULL_POINTER: return "a pointer is NULL";
    case SPERLI_E_BAD_LENGTH: return "a length is zero or above its limit";
    case SPERLI_E_BAD_RANK: return "a rank is not a peer in the job";
    case SPERLI_E_BAD_TAG: return "a tag is above 2147483647";
    case SPERLI_E_BAD_HANDLE: return "the handle is not the live session";
    case SPERLI_E_NOT_READY: return "the session holds no comm";
    case SPERLI_E_BAD_TYPE: return "the element type is not known";
    case SPERLI_E_BAD_OPERATION: return "the reduction is not known";
    case SPERLI_E_BUFFER_TOO_SMALL: return "the buffer is shorter than the result";
    case SPERLI_E_NO_RESULT: return "there is no result to take";
    case SPERLI_E_RESULT_PENDING: return "an earlier result has not been taken";
    case SPERLI_E_BUSY: return "another call is running";
    case SPERLI_E_ALREADY_INITIALISED: return "the process holds a session already";
    case SPERLI_E_BAD_PATH: return "the path holds a zero byte";
    case SPERLI_E_BAD_COUNT: return "the data is no whole number of elements or blocks";
    case SPERLI_E_INTERNAL: return "the core answered with an unknown code";
    case SPERLI_BAD_CERTIFICATE: return "the peer showed no certificate or one the job CA does not vouch for";
    case SPERLI_SUBJECT_MISMATCH: return "the certificate subject is not the job and rank of the peer";
    case SPERLI_REFUSED_HOST: return "the host is refused";
    case SPERLI_TOKEN_EXPIRED: return "the join token has expired";
    case SPERLI_TOKEN_FOREIGN_JOB: return "the join token is for another job";
    case SPERLI_TOKEN_WRONG_RANK: return "the join token is for another rank, size, incarnation or host";
    case SPERLI_TOKEN_BAD_SIGNATURE: return "the join token is malformed or its signature does not hold";
    case SPERLI_OVERSIZED_FRAME: return "a frame claims more payload than the limit";
    case SPERLI_STALE_INCARNATION: return "a frame is of an older incarnation";
    case SPERLI_BAD_FRAME: return "a frame header breaks the protocol";
    case SPERLI_PEER_LOST: return "the peer was lost";
    case SPERLI_PEER_ABORTED: return "the peer aborted the job";
    case SPERLI_BAD_HELLO: return "the hello of the peer is missing, repeated or not acceptable";
    case SPERLI_BAD_LAUNCH: return "the launch is wrong";
    case SPERLI_START_FAILED: return "a rank or the job could not be set up";
    case SPERLI_BAD_JOB: return "the job description is malformed";
    case SPERLI_COLLECTIVE_MISMATCH: return "a collective frame does not match the call";
    case SPERLI_BAD_COLLECTIVE: return "the arguments of a collective call are wrong";
    case SPERLI_BAD_CHECKPOINT_FILE: return "a checkpoint file is not the one expected";
    case SPERLI_DIGEST_MISMATCH: return "the digest of a checkpoint file does not hold";
    case SPERLI_BAD_COMMIT: return "the COMMIT file is malformed or its signature does not hold";
    case SPERLI_RESUME_REFUSED: return "no epoch can be resumed";
    case SPERLI_SIZE_MISMATCH: return "the job has another size than the checkpoint";
    case SPERLI_OPEN_HANDLES: return "a send or receive is still open";
    case SPERLI_CHECKPOINT_FAILED: return "the checkpoint could not be written or sent";
    default: return "unknown code";
    }
}
