#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#

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
