/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/* A C programme that calls the library built from Gauge.hiq.  It starts
   the library's runtime before the first call and ends it after the last,
   and hands the readings over as a pointer and a length.  When the whole
   programme is written as one C file, the library's C stands in front of
   this one: the header is not needed, and stdio.h is left out because the
   library's C declares some of its functions in its own way, so printf is
   declared here. */
#if defined(HILDE_LIBRARY)
int printf(const char *format, ...);
#else
#include <stdio.h>
#include "libgauge.h"
#endif

int main(void) {
  const uint8_t readings[6] = { 12, 200, 31, 250, 7, 180 };

  hilde_start();
  printf("sum of the readings: %llu\n",
         (unsigned long long) gauge_sum(readings, sizeof readings));
  printf("readings above 100: %zu\n",
         (size_t) gauge_count_above(readings, sizeof readings, 100));
  printf("an empty span sums to: %llu\n",
         (unsigned long long) gauge_sum(NULL, 0));
  printf("300 is a reading: %s\n", gauge_in_range(300) ? "yes" : "no");
  printf("42 is a reading: %s\n", gauge_in_range(42) ? "yes" : "no");
  hilde_end();
  return 0;
}
