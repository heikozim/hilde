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
		../../standard/src/Bindings/File.hih,../../standard/src/Bindings/File.hiq \
		../../standard/src/File.hih,../../standard/src/File.hiq \
		../../bindings/generated/Libcrypto.hih,../../bindings/generated/Libcrypto.hiq \
		../../standard/src/Bindings/Libcrypto.hih,../../standard/src/Bindings/Libcrypto.hiq \
		../../standard/src/Libcrypto.hih,../../standard/src/Libcrypto.hiq \
		../../bindings/generated/SqlCipher.hih,../../bindings/generated/SqlCipher.hiq \
		../../standard/src/Bindings/SqlCipher.hih,../../standard/src/Bindings/SqlCipher.hiq \
		../../standard/src/SqlCipher.hih,../../standard/src/SqlCipher.hiq \
		../../standard/src/Calendar.hih,../../standard/src/Calendar.hiq \
		../../standard/src/Tuples.hih,../../standard/src/Tuples.hiq \
		../../standard/src/Order.hih,../../standard/src/Order.hiq \
		../../standard/src/Hash.hih,../../standard/src/Hash.hiq \
		../../standard/src/Bindings/Entropy.hih,../../standard/src/Bindings/Entropy.hiq \
		../../standard/src/Bindings/Serial.hih,../../standard/src/Bindings/Serial.hiq \
		../../standard/src/HashMap.hih,../../standard/src/HashMap.hiq \
		../../standard/src/Graph.hih,../../standard/src/Graph.hiq \
		../../standard/src/Bindings/Database.hih,../../standard/src/Bindings/Database.hiq \
		../../standard/src/Database.hih,../../standard/src/Database.hiq \
		../../standard/src/Database/Sqlite.hih,../../standard/src/Database/Sqlite.hiq \
		../../standard/src/Cookie.hih,../../standard/src/Cookie.hiq \
		../../standard/src/Session.hih,../../standard/src/Session.hiq \
		../../standard/src/Csrf.hih,../../standard/src/Csrf.hiq \

PROG := LearnSession

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
