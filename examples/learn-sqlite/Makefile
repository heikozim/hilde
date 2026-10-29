# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \

SQLITE := \
		../../bindings/generated/Sqlite3.hih,../../bindings/generated/Sqlite3.hiq \
		../../standard/src/Bindings/Sqlite.hih,../../standard/src/Bindings/Sqlite.hiq \
		../../standard/src/Sqlite.hih,../../standard/src/Sqlite.hiq \

# SQLCipher is a changed SQLite with the same C names, so the two are built
# into two programmes and never linked into one.
SQLCIPHER := \
		../../standard/src/Bindings/File.hih,../../standard/src/Bindings/File.hiq \
		../../standard/src/File.hih,../../standard/src/File.hiq \
		../../bindings/generated/SqlCipher.hih,../../bindings/generated/SqlCipher.hiq \
		../../standard/src/Bindings/SqlCipher.hih,../../standard/src/Bindings/SqlCipher.hiq \
		../../standard/src/SqlCipher.hih,../../standard/src/SqlCipher.hiq \

PROG := LearnSqlite

ENTRY := Example.$(PROG):main

SRC := \
	$(PROG).hih,$(PROG).hiq

CIPHER := LearnSqlCipher

.DEFAULT: all
all:
	../../hilde compile $(STDLIB) $(SQLITE) $(SRC) --entrypoint=$(ENTRY) --output=main
	../../hilde compile $(STDLIB) $(SQLCIPHER) $(CIPHER).hih,$(CIPHER).hiq --entrypoint=Example.$(CIPHER):main --output=cipher

# The same programmes as C, for the warning count and the memory runs.
.PHONY: c
c:
	../../hilde compile $(STDLIB) $(SQLITE) $(SRC) --entrypoint=$(ENTRY) --target-type=c --output=main.c
	../../hilde compile $(STDLIB) $(SQLCIPHER) $(CIPHER).hih,$(CIPHER).hiq --entrypoint=Example.$(CIPHER):main --target-type=c --output=cipher.c

.PHONY: clean
clean:
	rm -f main cipher main.c cipher.c
