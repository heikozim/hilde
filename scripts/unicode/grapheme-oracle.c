/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

/* What ICU says about grapheme clusters, for the generator and the test of
   Standard.Grapheme.

       grapheme-oracle version
       grapheme-oracle props
       grapheme-oracle breaks < texts

   version prints the versions of ICU and of its Unicode data.  props prints
   one line per run of code points with the same Grapheme_Cluster_Break,
   Indic_Conjunct_Break and Extended_Pictographic: first and last code point
   in hexadecimal and the three values by their long names.  breaks reads
   texts, one per line as code points in hexadecimal separated by spaces,
   and prints for each the boundaries ICU's character break iterator finds,
   as code point offsets, 0 and the length included.

   Built against ICU's C interface, for instance with MacPorts' ICU:
   cc -I/opt/local/include grapheme-oracle.c -L/opt/local/lib -licuuc */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unicode/uchar.h>
#include <unicode/ubrk.h>
#include <unicode/uversion.h>
#include <unicode/utf16.h>

static void props(void) {
  UChar32 first = 0;
  int32_t gcb = u_getIntPropertyValue(0, UCHAR_GRAPHEME_CLUSTER_BREAK);
  int32_t incb = u_getIntPropertyValue(0, UCHAR_INDIC_CONJUNCT_BREAK);
  UBool ep = u_hasBinaryProperty(0, UCHAR_EXTENDED_PICTOGRAPHIC);
  UChar32 c;

  for (c = 1; c <= 0x110000; c++) {
    int32_t g = -1, i = -1;
    UBool e = 0;

    if (c <= 0x10FFFF) {
      g = u_getIntPropertyValue(c, UCHAR_GRAPHEME_CLUSTER_BREAK);
      i = u_getIntPropertyValue(c, UCHAR_INDIC_CONJUNCT_BREAK);
      e = u_hasBinaryProperty(c, UCHAR_EXTENDED_PICTOGRAPHIC);
    }
    if ((g != gcb) || (i != incb) || (e != ep)) {
      printf("%04X %04X %s %s %d\n", (unsigned) first, (unsigned) (c - 1),
             u_getPropertyValueName(UCHAR_GRAPHEME_CLUSTER_BREAK, gcb, U_LONG_PROPERTY_NAME),
             u_getPropertyValueName(UCHAR_INDIC_CONJUNCT_BREAK, incb, U_LONG_PROPERTY_NAME),
             ep ? 1 : 0);
      first = c;
      gcb = g;
      incb = i;
      ep = e;
    }
  }
}

/* One text per line: code points in hexadecimal, at most 64 of them. */
static int breaks(void) {
  char line[1024];

  while (fgets(line, sizeof line, stdin) != NULL) {
    UChar units[160];
    int32_t offsets[65];
    int32_t length = 0;
    int32_t points = 0;
    char* at = line;
    char* end;
    UErrorCode status = U_ZERO_ERROR;
    UBreakIterator* it;
    int32_t b;
    int32_t k;

    for (;;) {
      unsigned long value = strtoul(at, &end, 16);

      if (end == at) {
        break;
      }
      if ((value > 0x10FFFF) || (points >= 64)) {
        return 2;
      }
      offsets[points] = length;
      points++;
      U16_APPEND_UNSAFE(units, length, (UChar32) value);
      at = end;
    }
    offsets[points] = length;
    it = ubrk_open(UBRK_CHARACTER, "", units, length, &status);
    if (U_FAILURE(status)) {
      return 3;
    }
    for (b = ubrk_first(it); b != UBRK_DONE; b = ubrk_next(it)) {
      /* The unit offset as a code point offset. */
      for (k = 0; k <= points; k++) {
        if (offsets[k] == b) {
          printf("%s%d", (b == 0) ? "" : " ", (int) k);
          break;
        }
      }
    }
    printf("\n");
    ubrk_close(it);
  }
  return 0;
}

int main(int argc, char** argv) {
  if ((argc == 2) && (strcmp(argv[1], "version") == 0)) {
    UVersionInfo icu;
    UVersionInfo unicode;
    char a[U_MAX_VERSION_STRING_LENGTH];
    char b[U_MAX_VERSION_STRING_LENGTH];

    u_getVersion(icu);
    u_getUnicodeVersion(unicode);
    u_versionToString(icu, a);
    u_versionToString(unicode, b);
    printf("icu %s unicode %s\n", a, b);
    return 0;
  }
  if ((argc == 2) && (strcmp(argv[1], "props") == 0)) {
    props();
    return 0;
  }
  if ((argc == 2) && (strcmp(argv[1], "breaks") == 0)) {
    return breaks();
  }
  fprintf(stderr, "usage: grapheme-oracle version | props | breaks < texts\n");
  return 9;
}
