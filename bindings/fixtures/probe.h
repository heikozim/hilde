/*
 * A fixture header for scripts/gen-bindings.py.  It is not a real system
 * header and is not meant to be: a real one is thousands of declarations
 * that change between systems, and a generator measured against one is
 * measured against the machine it ran on.  This file is small, it is in the
 * repository, and every shape the generator has to read is in it once.
 */
#ifndef HILDE_PROBE_H
#define HILDE_PROBE_H

#include <stddef.h>

/* Flags, which the flags line of bindings/probe.spec makes a type of their
   own. */
#define PROBE_NONE      0
#define PROBE_READ      1
#define PROBE_WRITE     2
#define PROBE_EXEC      0x4
#define PROBE_ALL       7
/* Not an integer, so the generator leaves it alone. */
#define PROBE_NAME      "probe"

/* A prototype on one line. */
int probe_add(int left, int right);

/* One with no parameters, written the way C means it. */
int probe_zero(void);

/* One over several lines, with a pointer and a size_t. */
size_t probe_length(
    void *block,
    size_t bound);

/* One whose parameters have no names. */
double probe_scale(double, double);

#endif
