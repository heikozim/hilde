/*
 * A second fixture, for a spec that says preprocess yes.  It hides the real
 * declarations behind an include and behind a macro, which is the shape a
 * real system header has: glibc writes sqrt with __MATHCALL, and a reader
 * that does not expand macros finds nothing.
 *
 * Nothing here comes from the system, on purpose: a check that read
 * /usr/include would be a statement about the machine it ran on.
 */
#ifndef HILDE_PROBE_OUTER_H
#define HILDE_PROBE_OUTER_H

#include "probe.h"

/* The decorations a real header puts on a declaration.  None of them
   changes the binary interface and all of them have to come off again. */
#define OUTER_THROW  __attribute__ ((__nothrow__))
#define OUTER_DECL(rt, name, params)  extern rt name params OUTER_THROW;

OUTER_DECL(int, outer_twice, (int value))
OUTER_DECL(double, outer_half, (double value))

/* A constant that only exists after preprocessing. */
#define OUTER_FLAG_ONE   1
#define OUTER_FLAG_TWO   2
#define OUTER_FLAG_BOTH  (OUTER_FLAG_ONE + OUTER_FLAG_TWO)

#endif
