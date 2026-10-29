# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Base64.hih,../../standard/src/Base64.hiq \
		../../standard/src/Text.hih,../../standard/src/Text.hiq \
		../../standard/src/Utf8.hih,../../standard/src/Utf8.hiq \
		../../standard/src/Unicode.hih,../../standard/src/Unicode.hiq \
		../../standard/src/Normalization.hih,../../standard/src/Normalization.hiq \
		../../standard/src/Grapheme.hih,../../standard/src/Grapheme.hiq \

PROG := LearnEncodings

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
