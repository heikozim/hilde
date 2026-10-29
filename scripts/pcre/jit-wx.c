/*
 * Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
 * See LICENSE file for details.
 *
 * SPDX-FileCopyrightText: 2026 Heiko Zimmermann
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 * The probe of scripts/pcre/check-jit-wx.sh: it asks the PCRE2 it is
 * linked with for machine code of four patterns, searches with each, and
 * while the machine code is alive counts the mappings of the process that
 * are writable and executable at once, from /proc/self/maps.  One line per
 * fact, key=value.  Exit 0 when the JIT is built in, every pattern got
 * machine code and every search found what it must; exit 1 otherwise.
 * The count of mappings is printed and judged by the script, because its
 * negative control must see one.
 */
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <stdio.h>
#include <string.h>

#define COUNT 4

static const char *patterns[COUNT] = {
    "error",
    "(?i)warning|critical|fatal",
    "(\\w+)\\s+\\1",
    "^.*timeout.*$",
};

static const char subject[] =
    "no error at all\nWARNING data data\nrequest timeout here\n";

/* Where the first match of each pattern starts in subject. */
static const size_t expected[COUNT] = {3, 16, 24, 34};

static int wx_mappings(void)
{
#ifdef __linux__
    FILE *f = fopen("/proc/self/maps", "r");
    char line[1024];
    int n = 0;

    if (f == NULL) {
        return -1;
    }
    while (fgets(line, sizeof(line), f) != NULL) {
        char perms[8];
        if (sscanf(line, "%*s %7s", perms) == 1 && perms[1] == 'w' &&
            perms[2] == 'x') {
            n++;
        }
    }
    fclose(f);
    return n;
#else
    return -1;
#endif
}

int main(void)
{
    pcre2_code *codes[COUNT];
    char version[64];
    uint32_t built = 0;
    int compiled = 0;
    int found = 0;
    int i;

    pcre2_config(PCRE2_CONFIG_VERSION, version);
    pcre2_config(PCRE2_CONFIG_JIT, &built);
    printf("version=%s\n", version);
    printf("jit-built-in=%u\n", built);
    for (i = 0; i < COUNT; i++) {
        int err;
        PCRE2_SIZE off;
        pcre2_match_data *md;
        int rc;

        codes[i] = pcre2_compile((PCRE2_SPTR)patterns[i],
                                 PCRE2_ZERO_TERMINATED, PCRE2_MULTILINE,
                                 &err, &off, NULL);
        if (codes[i] == NULL) {
            printf("compile-failed=%d\n", i);
            return 1;
        }
        if (pcre2_jit_compile(codes[i], PCRE2_JIT_COMPLETE) == 0) {
            compiled++;
        }
        md = pcre2_match_data_create_from_pattern(codes[i], NULL);
        if (md == NULL) {
            return 1;
        }
        rc = pcre2_match(codes[i], (PCRE2_SPTR)subject, strlen(subject), 0,
                         0, md, NULL);
        if (rc > 0 && pcre2_get_ovector_pointer(md)[0] == expected[i]) {
            found++;
        }
        pcre2_match_data_free(md);
    }
    printf("jit-compiled=%d of %d\n", compiled, COUNT);
    printf("found=%d of %d\n", found, COUNT);
    printf("wx-mappings=%d\n", wx_mappings());
    for (i = 0; i < COUNT; i++) {
        pcre2_code_free(codes[i]);
    }
    return (built == 1 && compiled == COUNT && found == COUNT) ? 0 : 1;
}
