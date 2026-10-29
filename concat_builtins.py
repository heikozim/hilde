#!/usr/bin/env python3
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Hilde is derived from the Austral project and extends it substantially.
# Modified by Heiko Zimmermann, 2026.
"""
Take the sources from lib/builtins/ and embed them into an OCaml file.
"""

def read_file_to_string(path: str) -> str:
    with open(path, "r") as stream:
        return stream.read()

pervasive_int: str = read_file_to_string("lib/builtin/Pervasive.hih")
pervasive_body: str = read_file_to_string("lib/builtin/Pervasive.hiq")
memory_int: str = read_file_to_string("lib/builtin/Memory.hih")
memory_body: str = read_file_to_string("lib/builtin/Memory.hiq")
array_int: str = read_file_to_string("lib/builtin/Array.hih")
array_body: str = read_file_to_string("lib/builtin/Array.hiq")
prelude_h: str = read_file_to_string("lib/prelude.h")
prelude_c: str = read_file_to_string("lib/prelude.c")

# The C of ML-DSA: lib/mldsa.c with the text of libcrux in the place of its
# one include line, so that the compiler writes it into a programme as one
# piece and the programme needs no file beside it.  The text is a header
# and opens with a pragma once, which in a programme's own C file gcc warns
# about with no switch to turn the warning off; that one line is left out.
MLDSA_INCLUDE: str = '#include "libcrux_internal.h"\n'
PRAGMA_ONCE: str = "#pragma once\n"
mldsa_glue: str = read_file_to_string("lib/mldsa.c")
if mldsa_glue.count(MLDSA_INCLUDE) != 1:
    raise SystemExit("lib/mldsa.c must include libcrux_internal.h exactly once")
libcrux: str = read_file_to_string("vendor/libcrux/libcrux_internal.h")
if libcrux.count(PRAGMA_ONCE) != 1:
    raise SystemExit("libcrux_internal.h must hold one line #pragma once")
mldsa_c: str = mldsa_glue.replace(MLDSA_INCLUDE, libcrux.replace(PRAGMA_ONCE, ""))
if "|code}" in mldsa_c:
    raise SystemExit("the C of ML-DSA holds the end of an OCaml quoted string")

contents: str = f"""
let pervasive_interface_source: string = {{code|
{pervasive_int}
|code}}

let pervasive_body_source: string = {{code|
{pervasive_body}
|code}}

let memory_interface_source: string = {{code|
{memory_int}
|code}}

let memory_body_source: string = {{code|
{memory_body}
|code}}

let array_interface_source: string = {{code|
{array_int}
|code}}

let array_body_source: string = {{code|
{array_body}
|code}}

let prelude_h: string = {{code|
{prelude_h}
|code}}

let prelude_c: string = {{code|
{prelude_c}
|code}}

let mldsa_c: string = {{code|
{mldsa_c}
|code}}
"""

# The version of zig the gates pin, from the one place it is written: the
# compiler takes zig for WebAssembly only at this version.
with open("scripts/zig-version.txt", "r") as stream:
    zig_version = stream.readline().strip()
contents += "\nlet zig_version: string = \"" + zig_version + "\"\n"

with open("lib/BuiltInModules.ml", "w") as stream:
    stream.write(contents)
