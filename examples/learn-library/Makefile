# The library mode: Gauge.hiq
# becomes a static library and its header, and a C programme calls it.  The
# header names the libraries a static archive needs as well; here that is
# pthread.
.DEFAULT: all
all:
	../../hilde compile Gauge.hiq --target-type=static --output=libgauge.a
	cc -std=c17 -Wall -Wextra -I. caller.c libgauge.a -lpthread -o main

# The same programme as one C file, for the warning count and the memory
# runs: the library's C with
# HILDE_LIBRARY defined in front, then the caller.
.PHONY: c
c:
	../../hilde compile Gauge.hiq --target-type=c --no-entrypoint --output=gauge.c
	printf '#define HILDE_LIBRARY 1\n' > main.c
	cat gauge.c caller.c >> main.c
	rm gauge.c

.PHONY: clean
clean:
	rm -f main main.c gauge.c libgauge.a libgauge.h
