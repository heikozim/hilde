# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/Utf8.hih,../../standard/src/Utf8.hiq \
		../../standard/src/Bindings/File.hih,../../standard/src/Bindings/File.hiq \
		../../standard/src/File.hih,../../standard/src/File.hiq \
		../../standard/src/Bindings/Sandbox.hih,../../standard/src/Bindings/Sandbox.hiq \
		../../standard/src/Sandbox.hih,../../standard/src/Sandbox.hiq \
		../../standard/src/IO/IO.hih,../../standard/src/IO/IO.hiq \
		../../standard/src/Bindings/Terminal.hih,../../standard/src/Bindings/Terminal.hiq \
		../../standard/src/IO/Terminal.hih,../../standard/src/IO/Terminal.hiq \
		../../standard/src/Calendar.hih,../../standard/src/Calendar.hiq \
		../../standard/src/Bindings/Time.hih,../../standard/src/Bindings/Time.hiq \
		../../standard/src/Time.hih,../../standard/src/Time.hiq \
		../../standard/src/Bindings/SystemLog.hih,../../standard/src/Bindings/SystemLog.hiq \
		../../standard/src/Log.hih,../../standard/src/Log.hiq \
		../../standard/src/Bindings/Signal.hih,../../standard/src/Bindings/Signal.hiq \
		../../standard/src/Signal.hih,../../standard/src/Signal.hiq \
		../../standard/src/Bindings/Resource.hih,../../standard/src/Bindings/Resource.hiq \
		../../standard/src/Resource.hih,../../standard/src/Resource.hiq \

PROG := LearnLog

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
