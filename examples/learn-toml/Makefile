# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Text.hih,../../standard/src/Text.hiq \
		../../standard/src/Utf8.hih,../../standard/src/Utf8.hiq \
		../../standard/src/Tuples.hih,../../standard/src/Tuples.hiq \
		../../standard/src/Order.hih,../../standard/src/Order.hiq \
		../../standard/src/Hash.hih,../../standard/src/Hash.hiq \
		../../standard/src/Bindings/Entropy.hih,../../standard/src/Bindings/Entropy.hiq \
		../../standard/src/Bindings/Serial.hih,../../standard/src/Bindings/Serial.hiq \
		../../standard/src/HashMap.hih,../../standard/src/HashMap.hiq \
		../../standard/src/Toml.hih,../../standard/src/Toml.hiq \

PROG := LearnToml

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
