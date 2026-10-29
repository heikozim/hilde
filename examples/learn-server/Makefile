# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Bindings/File.hih,../../standard/src/Bindings/File.hiq \
		../../standard/src/File.hih,../../standard/src/File.hiq \
		../../standard/src/Text.hih,../../standard/src/Text.hiq \
		../../standard/src/Fcgi.hih,../../standard/src/Fcgi.hiq \
		../../standard/src/Bindings/Task.hih,../../standard/src/Bindings/Task.hiq \
		../../standard/src/Task.hih,../../standard/src/Task.hiq \
		../../standard/src/Bindings/Signal.hih,../../standard/src/Bindings/Signal.hiq \
		../../standard/src/Signal.hih,../../standard/src/Signal.hiq \
		../../standard/src/Bindings/Time.hih,../../standard/src/Bindings/Time.hiq \
		../../standard/src/Time.hih,../../standard/src/Time.hiq \
		../../standard/src/Bindings/Context.hih,../../standard/src/Bindings/Context.hiq \
		../../standard/src/Context.hih,../../standard/src/Context.hiq \
		../../standard/src/FcgiServer.hih,../../standard/src/FcgiServer.hiq \

PROG := LearnServer

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
