# Modified by Heiko Zimmermann for Hilde, 2026.
STDLIB := \
		../../standard/src/Tuples.hih,../../standard/src/Tuples.hiq \
		../../standard/src/Bounded.hih,../../standard/src/Bounded.hiq \
		../../standard/src/Equality.hih,../../standard/src/Equality.hiq \
		../../standard/src/Order.hih,../../standard/src/Order.hiq \
		../../standard/src/Box.hih,../../standard/src/Box.hiq \
		../../standard/src/Buffer.hih,../../standard/src/Buffer.hiq \
		../../standard/src/String.hih,../../standard/src/String.hiq \
		../../standard/src/StringBuilder.hih,../../standard/src/StringBuilder.hiq \
		../../standard/src/IO/IO.hih,../../standard/src/IO/IO.hiq \
		../../standard/src/Bindings/Terminal.hih,../../standard/src/Bindings/Terminal.hiq \
		../../standard/src/IO/Terminal.hih,../../standard/src/IO/Terminal.hiq \

PROG := FFI

ENTRY := Example.$(PROG):main

SRC := \
	$(PROG).hih,$(PROG).hiq

.DEFAULT: all
all:
	../../hilde compile $(STDLIB) $(SRC) --entrypoint=$(ENTRY) --output=main

.PHONY: clean
clean:
	rm main
