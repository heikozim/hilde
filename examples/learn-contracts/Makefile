# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

STDLIB := \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/IO/IO.hih,../../standard/src/IO/IO.hiq \
		../../standard/src/Bindings/Terminal.hih,../../standard/src/Bindings/Terminal.hiq \
		../../standard/src/IO/Terminal.hih,../../standard/src/IO/Terminal.hiq \

PROG := LearnContracts

ENTRY := Example.$(PROG):main

SRC := \
	$(PROG).hih,$(PROG).hiq

# The second programme: the same account, and a call that breaks its
# contract.
BROKEN := LearnContractsBroken

.DEFAULT: all
all:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --output=main
	../../hilde compile $(STDLIB) $(SRC) $(BROKEN).hih,$(BROKEN).hiq --entrypoint=Example.$(BROKEN):main --output=broken

# The same programmes as C, for the warning count and the memory runs.
.PHONY: c
c:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --target-type=c --output=main.c
	../../hilde compile $(STDLIB) $(SRC) $(BROKEN).hih,$(BROKEN).hiq --entrypoint=Example.$(BROKEN):main --target-type=c --output=broken.c

.PHONY: clean
clean:
	rm -f main broken main.c broken.c
