# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/UnicodeProperties.hih,../../standard/src/UnicodeProperties.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Regex.hih,../../standard/src/Regex.hiq \
		../../standard/src/Text.hih,../../standard/src/Text.hiq \
		../../bindings/generated/Pcre2.hih,../../bindings/generated/Pcre2.hiq \
		../../standard/src/Bindings/Pcre.hih,../../standard/src/Bindings/Pcre.hiq \
		../../standard/src/Pcre.hih,../../standard/src/Pcre.hiq \

PROG := LearnRegex

ENTRY := Example.$(PROG):main

SRC := \
	$(PROG).hih,$(PROG).hiq

.DEFAULT: all
all:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --output=main

# The same programmes as C, for the warning count and the memory runs.
.PHONY: c
c:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --target-type=c --output=main.c

.PHONY: clean
clean:
	rm -f main main.c
