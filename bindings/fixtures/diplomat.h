/*
 * A Diplomat-style fixture header for scripts/gen-bindings.py.  One
 * opaque handle the caller owns, one result copied into a buffer of the
 * caller, and the one function that frees the object.  A handle leaves a
 * function only as the value it came in as: diag_write gives it back, and
 * diag_destroy ends it.
 *
 * The rest of the Diplomat patterns stand beside it: a slice the caller's
 * bytes travel in, passed by value; a result struct with the value, the
 * error code and the flag that says which one is live, written flat so a
 * caller of any language reads it without a union; and the write object
 * Diplomat fills, which the caller makes, lends to the functions that
 * fill it, and frees with the name Diplomat writes it, diplomat_free_ in
 * front of the type in small letters.
 */
#ifndef HILDE_DIPLOMAT_H
#define HILDE_DIPLOMAT_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct Diag Diag;

/* Makes one.  The caller owns it and frees it with diag_destroy. */
Diag *diag_new(void);

/* Writes the message into out, at most out_len bytes, and gives the
   handle back, so it can be used again.  out_len is at least 1; the C
   side trusts the caller with that, as a binding precondition. */
Diag *diag_write(Diag *diag, char *out, size_t out_len);

/* Frees the object.  The handle is gone with it. */
void diag_destroy(Diag *diag);

/* The slice of a message: the bytes and their length, passed by value.
   The bytes stay the caller's; the call reads them and no more. */
typedef struct {
    const char *data;
    size_t len;
} DiplomatStringView;

/* What a call that can fail gives back.  ok holds the value when is_ok
   is true, err the error code when it is false. */
typedef struct {
    size_t ok;
    int32_t err;
    bool is_ok;
} DiagWriteResult;

/* The write Diplomat fills.  The caller makes it, lends it to the
   functions that fill it, and frees it with diplomat_free_write. */
typedef struct DiplomatWrite DiplomatWrite;

/* The length in bytes of the message. */
size_t diag_measure(DiplomatStringView message);

/* Reads the message: ok holds the number of bytes read, err the error
   code when the message is not well formed. */
DiagWriteResult diag_parse(DiplomatStringView message);

/* Appends the message to the write and gives the write back. */
DiplomatWrite *diplomat_write_str(DiplomatWrite *write,
                                  DiplomatStringView message);

/* Makes one.  The caller owns it and frees it with diplomat_free_write. */
DiplomatWrite *diplomat_make_write(void);

/* Frees it.  The handle is gone with it. */
void diplomat_free_write(DiplomatWrite *write);

#endif
