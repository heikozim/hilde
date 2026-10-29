# Modified by Heiko Zimmermann for Hilde, 2026.
# The standard library's tests are test files beside the modules they test,
# run by hilde test; the tests of Hilde.Pervasive stand beside it in
# lib/builtin.

.DEFAULT: all
all: test

.PHONY: test
test:
	cd .. && ./hilde test --modules=bindings/generated standard/src lib/builtin

.PHONY: clean
clean:
