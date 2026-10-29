#!/usr/bin/env bash
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Hilde is derived from the Austral project and extends it substantially.
# Modified by Heiko Zimmermann, 2026.

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
