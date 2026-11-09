#!/usr/bin/env python3
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Derived from the Austral project, https://github.com/austral/austral.
# Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
"""
Take the sources from lib/builtins/ and embed them into an OCaml file.
"""

import re


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

# The runtime prelude: lib/prelude/internal.h and the parts beside it, in
# the order a programme carries them.  task.c comes before task-none.c,
# which stands in for it where it is missing.  The compiler writes
# internal.h and the parts a programme needs (Compiler.prelude_parts_of);
# each part's line that includes internal.h is left out, since the header
# is written once in front of them all.
PRELUDE_PARTS: list = [
    "core", "library", "crypto", "resolve", "sandbox", "path", "file", "system",
    "signal", "socket", "process", "task", "task-none", "shared", "poller",
]
INTERNAL_INCLUDE: str = '#include "internal.h"\n'
prelude_internal: str = read_file_to_string("lib/prelude/internal.h")
part_texts: dict = {}
for part in PRELUDE_PARTS:
    text = read_file_to_string(f"lib/prelude/{part}.c")
    if text.count(INTERNAL_INCLUDE) != 1:
        raise SystemExit(f"lib/prelude/{part}.c must include internal.h exactly once")
    part_texts[part] = text.replace(INTERNAL_INCLUDE, "")


def without_comments(text: str) -> str:
    """The text with its C comments replaced by a blank."""
    return re.sub(r"/\*.*?\*/|//[^\n]*", " ", text, flags=re.S)


# A name a part defines: an identifier that begins with hilde_ and stands
# at the start of a line, after the words of a declaration, as a function
# or a variable at file scope.  A line ending in a semicolon after a
# parenthesis is a declaration of a function, not its definition.
DEFINITION = re.compile(
    r"^(?:(?:[A-Za-z_]\w*|__attribute__\(\([^()]*(?:\([^()]*\))?[^()]*\)\))[\s*]+)*"
    r"(hilde_\w+)\s*(\(|\[|=|;)", re.M)
PARAMETERS_THEN_SEMICOLON = re.compile(r"\)[^)]*;\s*$")


def defined_names(text: str) -> list:
    names = []
    for line in without_comments(text).split("\n"):
        if not line or line[0] in " \t#}":
            continue
        m = DEFINITION.match(line)
        if m is None:
            continue
        if m.group(2) == "(" and PARAMETERS_THEN_SEMICOLON.search(line):
            continue
        if line.startswith("extern "):
            continue
        if m.group(1) not in names:
            names.append(m.group(1))
    return names


def used_names(text: str) -> set:
    return set(re.findall(r"\bhilde_\w+", without_comments(text)))


# The parts every programme carries; a name they define pulls in nothing.
ALWAYS: list = ["core", "task-none"]
defines: dict = {part: defined_names(part_texts[part]) for part in PRELUDE_PARTS}
stand_in: set = set(defines["task-none"])
owner: dict = {}
for part in PRELUDE_PARTS:
    for name in defines[part]:
        if part == "task" and name in stand_in:
            continue
        if name in owner and owner[name] != part:
            raise SystemExit(f"{name} is defined in lib/prelude/{owner[name]}.c and {part}.c")
        owner[name] = part
# A part's triggers: the names it defines that no other part answers for.
triggers: dict = {part: [n for n in defines[part] if owner.get(n) == part] for part in PRELUDE_PARTS}
# A part's needs: the other parts that define a name it uses, unless the
# part is carried anyway.
needs: dict = {}
for part in PRELUDE_PARTS:
    wanted = set()
    for name in used_names(part_texts[part]):
        other = owner.get(name)
        if other is not None and other != part and other not in ALWAYS:
            wanted.add(other)
    needs[part] = [p for p in PRELUDE_PARTS if p in wanted]
for part in PRELUDE_PARTS:
    if part not in ALWAYS and not triggers[part]:
        raise SystemExit(f"lib/prelude/{part}.c defines no name of its own")


def ocaml_strings(items: list) -> str:
    return "[" + "; ".join('"' + i + '"' for i in items) + "]"


for part in PRELUDE_PARTS:
    if "|code}" in part_texts[part]:
        raise SystemExit(f"lib/prelude/{part}.c holds the end of an OCaml quoted string")

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

def skip_literal(text: str, i: int) -> int:
    """The index after the string or character literal that starts at i."""
    quote = text[i]
    j = i + 1
    while text[j] != quote:
        j += 2 if text[j] == "\\" else 1
    return j + 1


def skip_comment(text: str, i: int) -> int:
    """The index after the comment that starts at i, or i when none does."""
    if text.startswith("/*", i):
        return text.index("*/", i + 2) + 2
    if text.startswith("//", i):
        end = text.find("\n", i)
        return len(text) if end < 0 else end
    return i


def directive_end(text: str, i: int) -> int:
    """The index after the preprocessor line that starts at i, with every
    line it continues with a backslash."""
    while True:
        end = text.find("\n", i)
        if end < 0:
            return len(text)
        if end > 0 and text[end - 1] == "\\":
            i = end + 1
            continue
        return end + 1


def is_function_head(code: str) -> bool:
    """Whether the code before a brace at file scope is the head of a
    function: it ends with the parenthesis of the parameters and is no type
    and no initialised variable."""
    code = code.strip()
    if not code.endswith(")"):
        return False
    if re.match(r"(typedef|struct|union|enum)\b", code):
        return False
    return "=" not in code.split("(")[0]


def is_static_variable(code: str) -> bool:
    """Whether a declaration at file scope defines a static variable whose
    value can change: static, not const, and no prototype of a function."""
    code = code.strip()
    if not re.match(r"static\b", code) or re.match(r"static\s+const\b", code):
        return False
    # A prototype: the first parenthesis follows the function's name and
    # opens its parameters; a pointer to a function opens with (*.
    head = re.sub(r"__attribute__\s*\(\(.*?\)\)", "", code.split("=")[0])
    return not re.match(r"[^(]*\b[A-Za-z_]\w*\s*\((?!\s*\*)", head)


def variable_name(head: str) -> str:
    """The name a declaration of a variable at file scope declares: the
    identifier after the opening of a pointer to a function, else the last
    one before an array's bound, attributes left out."""
    head = re.sub(r"__attribute__\s*\(\(.*?\)\)", "", head)
    pointer = re.search(r"\(\s*\*\s*([A-Za-z_]\w*)", head)
    if pointer is not None:
        return pointer.group(1)
    return re.findall(r"[A-Za-z_]\w*", head.split("[")[0])[-1]


def prelude_parts(text: str) -> tuple[str, str, list]:
    """The prelude as the translation units of a programme built in parts
    see it: the text the prelude's own unit compiles, and its declarations
    for the other units.

    In the declarations every function at file scope that is not static
    loses its body and keeps its head as a declaration, and a statement
    __asm__ at file scope is left out, since both define symbols that the
    object of the whole prelude defines once.  A static variable that can
    change becomes an extern declaration, and in the prelude's own text it
    loses its static, so that every unit reads and writes the one variable;
    a copy in each unit would split the state of the runtime, a flag set by
    a signal handler for one.  Types, macros, declarations, constants and
    static functions stay: they are what a module's C reads, and a static
    one that nothing reads is dropped by the C compiler.  The third value
    is the name of every variable made shared."""
    out: list[str] = []
    pending: list[str] = []
    code: list[str] = []
    code_start = 0
    shared_at: list[int] = []
    shared_names: list[str] = []
    depth = 0
    line_start = True
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if line_start and depth == 0 and c == "#":
            end = directive_end(text, i)
            (pending if "".join(code).strip() else out).append(text[i:end])
            i = end
            continue
        after = skip_comment(text, i)
        if after != i:
            pending.append(text[i:after])
            i = after
            continue
        if c in "\"'":
            after = skip_literal(text, i)
            pending.append(text[i:after])
            code.append(text[i:after])
            i = after
            line_start = False
            continue
        if depth == 0 and c == "{" and is_function_head("".join(code)) \
           and not re.match(r"static\b", "".join(code).strip()):
            inner = 1
            j = i + 1
            while inner > 0:
                after = skip_comment(text, j)
                if after != j:
                    j = after
                elif text[j] in "\"'":
                    j = skip_literal(text, j)
                else:
                    inner += {"{": 1, "}": -1}.get(text[j], 0)
                    j += 1
            out.append("".join(pending).rstrip() + ";")
            pending, code = [], []
            i = j
            line_start = False
            continue
        if not "".join(code).strip():
            code_start = i
        pending.append(c)
        code.append(c)
        i += 1
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0 and is_function_head("".join(code).split("{")[0]):
                out.append("".join(pending))
                pending, code = [], []
        elif c == ";" and depth == 0:
            statement = "".join(code)
            if is_static_variable(statement):
                head = statement.strip().split("=")[0].rstrip().rstrip(";").rstrip()
                out.append(re.sub(r"^static\b", "extern", head) + ";")
                shared_at.append(code_start)
                shared_names.append(variable_name(head))
            elif not re.match(r"__asm__\s*\(", statement.strip()):
                out.append("".join(pending))
            pending, code = [], []
        elif c == "\n" and depth == 0 and not "".join(code).strip():
            out.append("".join(pending))
            pending, code = [], []
        line_start = c == "\n" or (line_start and c in " \t")
    out.append("".join(pending))
    shared = text
    for at in reversed(shared_at):
        if not shared.startswith("static", at):
            raise SystemExit("prelude: no static at offset " + str(at))
        shared = shared[:at] + shared[at + len("static "):]
    return (shared, "".join(out), shared_names)


# Every part of the prelude, and internal.h, as a programme built in parts
# sees it.  internal.h declares some of the static variables the parts
# define; they are made shared there too.  It may define no function that
# is not static, since every unit reads it.  A variable made shared
# is one symbol of the whole programme, so no two parts may name the same
# one, except task.c and task-none.c, of which a programme compiles one
# (task-none.c is inside a guard that task.c switches off).  A function
# kept with its body in the declarations is compiled into every unit, so
# it may hold no static variable that can change: each unit would have a
# copy of its own.
LOCAL_STATIC = re.compile(r"^[ \t]+static\s+(?!const\b)", re.M)
(internal_shared, internal_decls, internal_names) = prelude_parts(prelude_internal)
if internal_decls.count("{") != internal_shared.count("{"):
    raise SystemExit("lib/prelude/internal.h may define no function that is not static")
if LOCAL_STATIC.search(without_comments(internal_decls)):
    raise SystemExit("lib/prelude/internal.h: a static function holds a static variable that can change")
prelude_split: list = []
shared_owner: dict = {}
for part in PRELUDE_PARTS:
    (part_shared, part_decls, names) = prelude_parts(part_texts[part])
    if LOCAL_STATIC.search(without_comments(part_decls)):
        raise SystemExit(f"lib/prelude/{part}.c: a static function holds a static variable that can change")
    for name in names:
        other = shared_owner.get(name)
        if other is not None and other != part and {other, part} != {"task", "task-none"}:
            raise SystemExit(f"{name} is a static variable of lib/prelude/{other}.c and {part}.c")
        shared_owner[name] = part
    if "|code}" in part_shared or "|code}" in part_decls:
        raise SystemExit(f"lib/prelude/{part}.c holds the end of an OCaml quoted string")
    prelude_split.append((part, part_shared, part_decls))

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

let prelude_internal_h: string = {{code|
{prelude_internal}
|code}}

let mldsa_c: string = {{code|
{mldsa_c}
|code}}
"""

contents += "\nlet prelude_parts: (string * string * string list * string list) list = [\n"
for part in PRELUDE_PARTS:
    contents += ("  (\"" + part + "\", {code|\n" + part_texts[part] + "|code},\n   "
                 + ocaml_strings(triggers[part]) + ",\n   " + ocaml_strings(needs[part]) + ");\n")
contents += "]\n"

contents += "\nlet prelude_internal_shared: string = {code|\n" + internal_shared + "|code}\n"
contents += "\nlet prelude_internal_declarations: string = {code|\n" + internal_decls + "|code}\n"
contents += "\nlet prelude_split: (string * string * string) list = [\n"
for (part, part_shared, part_decls) in prelude_split:
    contents += ("  (\"" + part + "\", {code|\n" + part_shared + "|code},\n   {code|\n" + part_decls + "|code});\n")
contents += "]\n"

# The version of zig the gates pin, from the one place it is written: the
# compiler takes zig for WebAssembly only at this version.
with open("scripts/zig-version.txt", "r") as stream:
    zig_version = stream.readline().strip()
contents += "\nlet zig_version: string = \"" + zig_version + "\"\n"

with open("lib/BuiltInModules.ml", "w") as stream:
    stream.write(contents)
