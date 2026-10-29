/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/*
 * libsperli: the C interface of Sperli, a job of ranks that send each other
 * messages over TLS 1.3.
 *
 * Every connection uses TLS 1.3 with a certificate on both sides.  There is
 * no option to turn that off.
 *
 * Every function checks all of its arguments first and answers with a
 * code.  A wrong argument never ends the process and never changes the
 * job.  Only a bug in the library itself ends the process, through
 * abort(3).
 *
 * Codes: 0 is success.  A negative code is a mistake of the caller, found
 * before anything was sent.  A positive code from 1601 to 1625 is a refusal
 * or a loss in the job; it is the number of the H code of the same name.
 * The numbers never change and are never given to another meaning.
 *
 * The checks run in this order, and the first that fails gives the code:
 * another call is running (SPERLI_E_BUSY); the handle (SPERLI_E_BAD_HANDLE);
 * a pointer (SPERLI_E_NULL_POINTER); a length (SPERLI_E_BAD_LENGTH); then
 * the tag, rank, element type, reduction and count.  When several of those
 * last are wrong, which code comes back is not fixed.  A result pointer is
 * set to 0 as soon as it is known to be a pointer.
 *
 * One call runs at a time.  A call made while another runs is refused with
 * SPERLI_E_BUSY; a caller that uses several threads takes a lock of its
 * own.  A process holds one session.
 *
 * A call that answers with data (recv, bcast, reduce, allreduce, gather,
 * scatter, resume) keeps it and tells its length; sperli_result copies it
 * out.  Until then no other call that makes data is accepted
 * (SPERLI_E_RESULT_PENDING).  An empty result is not kept.
 *
 * A programme that links the static library links these as well:
 * -lpthread -ltls -lcrypto.
 */
#ifndef SPERLI_H
#define SPERLI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* A session: the handle of the job this process has joined.  0 is none. */
typedef uint64_t sperli_t;

enum sperli_code {
    SPERLI_OK = 0,

    /* Mistakes of the caller. */
    SPERLI_E_NULL_POINTER = -1,         /* a pointer is NULL where bytes or a result are needed */
    SPERLI_E_BAD_LENGTH = -2,           /* a length is zero where data is needed, or above its limit */
    SPERLI_E_BAD_RANK = -3,             /* a rank is not in the job, or is the own rank where a peer is needed */
    SPERLI_E_BAD_TAG = -4,              /* a tag is above 2147483647 */
    SPERLI_E_BAD_HANDLE = -5,           /* the handle is not the live session */
    SPERLI_E_NOT_READY = -6,            /* the session holds no comm */
    SPERLI_E_BAD_TYPE = -7,             /* an element type is above 6 */
    SPERLI_E_BAD_OPERATION = -8,        /* a reduction is 0 or above 10 */
    SPERLI_E_BUFFER_TOO_SMALL = -9,     /* the buffer is shorter than the result; the result is kept */
    SPERLI_E_NO_RESULT = -10,           /* there is no result to take */
    SPERLI_E_RESULT_PENDING = -11,      /* an earlier result has not been taken */
    SPERLI_E_BUSY = -12,                /* another call is running */
    SPERLI_E_ALREADY_INITIALISED = -13, /* the process holds a session already */
    SPERLI_E_BAD_PATH = -14,            /* a path holds a zero byte */
    SPERLI_E_BAD_COUNT = -15,           /* the data is no whole number of elements or blocks */
    SPERLI_E_INTERNAL = -16,            /* the core answered with a code that is none of these */

    /* Refusals and losses in the job. */
    SPERLI_BAD_CERTIFICATE = 1601,
    SPERLI_SUBJECT_MISMATCH = 1602,
    SPERLI_REFUSED_HOST = 1603,
    SPERLI_TOKEN_EXPIRED = 1604,
    SPERLI_TOKEN_FOREIGN_JOB = 1605,
    SPERLI_TOKEN_WRONG_RANK = 1606,
    SPERLI_TOKEN_BAD_SIGNATURE = 1607,
    SPERLI_OVERSIZED_FRAME = 1608,
    SPERLI_STALE_INCARNATION = 1609,
    SPERLI_BAD_FRAME = 1610,
    SPERLI_PEER_LOST = 1611,
    SPERLI_PEER_ABORTED = 1612,
    SPERLI_BAD_HELLO = 1613,
    SPERLI_BAD_LAUNCH = 1614,
    SPERLI_START_FAILED = 1615,
    SPERLI_BAD_JOB = 1616,
    SPERLI_COLLECTIVE_MISMATCH = 1617,
    SPERLI_BAD_COLLECTIVE = 1618,
    SPERLI_BAD_CHECKPOINT_FILE = 1619,
    SPERLI_DIGEST_MISMATCH = 1620,
    SPERLI_BAD_COMMIT = 1621,
    SPERLI_RESUME_REFUSED = 1622,
    SPERLI_SIZE_MISMATCH = 1623,
    SPERLI_OPEN_HANDLES = 1624,
    SPERLI_CHECKPOINT_FAILED = 1625
};

/* The element types of reduce and allreduce. */
enum sperli_type {
    SPERLI_BYTES = 0,
    SPERLI_INT32 = 1,
    SPERLI_INT64 = 2,
    SPERLI_UINT32 = 3,
    SPERLI_UINT64 = 4,
    SPERLI_FLOAT32 = 5,
    SPERLI_FLOAT64 = 6
};

/* The reductions of reduce and allreduce, applied in the order of the ranks. */
enum sperli_operation {
    SPERLI_SUM = 1,
    SPERLI_MIN = 2,
    SPERLI_MAX = 3,
    SPERLI_PROD = 4,
    SPERLI_LAND = 5,
    SPERLI_LOR = 6,
    SPERLI_LXOR = 7,
    SPERLI_BAND = 8,
    SPERLI_BOR = 9,
    SPERLI_BXOR = 10
};

/* The limits. */
enum {
    SPERLI_MAX_RANKS = 4096,
    SPERLI_MAX_TAG = 2147483647,
    SPERLI_MAX_DESCRIPTION = 4194304,
    SPERLI_MAX_MESSAGE = 16777216,
    SPERLI_MAX_COLLECTIVE = 16777200,
    SPERLI_MAX_STATE = 268435456,
    SPERLI_MAX_PATH = 4096
};

/*
 * Joins the job that description, the text of a job description in
 * hexadecimal digits as the launcher writes it, names.  On success *session
 * is the handle.  On any other answer *session is 0 and nothing is held.
 * description holds secret keys: the caller wipes it after the call.
 * Requires: session is not NULL; description is not NULL; length is 1 to
 * SPERLI_MAX_DESCRIPTION.
 */
int32_t sperli_init(const uint8_t *description, size_t length, sperli_t *session);

/* The own rank, in *rank.  Requires: rank is not NULL. */
int32_t sperli_rank(sperli_t session, uint32_t *rank);

/* The number of ranks, 1 to SPERLI_MAX_RANKS, in *size.  Requires: size is not NULL. */
int32_t sperli_size(sperli_t session, uint32_t *size);

/*
 * Sends data to rank target with tag.  Requires: target is a rank of the job
 * other than the own; tag is at most SPERLI_MAX_TAG; data is not NULL when
 * length is above 0; length is at most SPERLI_MAX_MESSAGE.
 */
int32_t sperli_send(sperli_t session, uint32_t target, uint32_t tag, const uint8_t *data, size_t length);

/*
 * Waits for the next message from rank source with tag and keeps it; *length
 * is its length, 0 when none is kept.  Requires: source is a rank of the
 * job other than the own; tag is at most SPERLI_MAX_TAG; length is not NULL.
 */
int32_t sperli_recv(sperli_t session, uint32_t source, uint32_t tag, size_t *length);

/* Waits until every rank has called it. */
int32_t sperli_barrier(sperli_t session);

/*
 * The data of rank root on every rank, kept; *result_length is its length.
 * The data of the other ranks is not used.  Requires: root is a rank of the
 * job; data is not NULL when length is above 0; length is at most
 * SPERLI_MAX_COLLECTIVE; result_length is not NULL.
 */
int32_t sperli_bcast(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length);

/*
 * Reduces the data of all ranks, as arrays of type, with operation; the
 * result is kept at root and is empty elsewhere.  Requires: root is a rank
 * of the job; type is a sperli_type; operation is a sperli_operation; data
 * is not NULL when length is above 0; length is a whole number of
 * elements and at most SPERLI_MAX_COLLECTIVE; result_length is not NULL.
 * A pair of type and operation that does not go together is answered with
 * SPERLI_BAD_COLLECTIVE.
 */
int32_t sperli_reduce(sperli_t session, uint32_t root, uint8_t type, uint8_t operation,
                      const uint8_t *data, size_t length, size_t *result_length);

/* As sperli_reduce, with the result on every rank and no root. */
int32_t sperli_allreduce(sperli_t session, uint8_t type, uint8_t operation,
                         const uint8_t *data, size_t length, size_t *result_length);

/*
 * The blocks of all ranks, joined in the order of the ranks, kept at root;
 * empty elsewhere.  All blocks have one length.  Requires: root is a rank of
 * the job; data is not NULL when length is above 0; length is at most
 * SPERLI_MAX_COLLECTIVE; result_length is not NULL.
 */
int32_t sperli_gather(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length);

/*
 * Cuts the data of root into one block for each rank and gives rank i block
 * i; the block is kept.  The data of the other ranks is not used.  Requires:
 * root is a rank of the job; data is not NULL when length is above 0; at
 * root, length is a whole number of blocks of at most SPERLI_MAX_COLLECTIVE
 * bytes; result_length is not NULL.
 */
int32_t sperli_scatter(sperli_t session, uint32_t root, const uint8_t *data, size_t length, size_t *result_length);

/*
 * Copies the kept result into buffer and forgets it; *length is its length.
 * When capacity is shorter, nothing is copied, *length is the length that is
 * needed and the result is kept.  Requires: length is not NULL; buffer is
 * not NULL when capacity is above 0.
 */
int32_t sperli_result(sperli_t session, uint8_t *buffer, size_t capacity, size_t *length);

/*
 * Names the directory the checkpoint files go to; it is made when missing.
 * Every rank names one that only it and the launcher can write.  Requires:
 * path is not NULL; length is 1 to SPERLI_MAX_PATH; path holds no zero byte.
 */
int32_t sperli_checkpoint_directory(sperli_t session, const uint8_t *path, size_t length);

/*
 * The collective checkpoint of state: every rank calls it, in the same order
 * as the collectives.  Requires: state is not NULL when length is above 0;
 * length is at most SPERLI_MAX_STATE.
 */
int32_t sperli_checkpoint(sperli_t session, const uint8_t *state, size_t length);

/*
 * The collective resume: the state of this rank from the last committed
 * checkpoint, kept; *length is its length.  Requires: length is not NULL.
 */
int32_t sperli_resume(sperli_t session, size_t *length);

/* Leaves the job and gives the handle back.  The handle is dead afterwards. */
int32_t sperli_finish(sperli_t session);

/* A short English sentence for code; "unknown code" for any other number.  Never NULL. */
const char *sperli_describe(int32_t code);

#ifdef __cplusplus
}
#endif

#endif
