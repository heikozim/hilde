#!/usr/bin/env bash
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Derived from the Austral project, https://github.com/austral/austral.
# Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.

set -euxo pipefail

# Ensure the compiler binary is up to date.
make
# Run the OCaml tests.
make test
# Run the end-to-end tests.
python3 test-programs/runner.py
# Run the examples.
./run-examples.sh
# Build and run the stdlib tests.
./hilde test --modules=bindings/generated standard/src lib/builtin
