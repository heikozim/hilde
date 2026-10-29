#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""docs/standard-library.md is made from the heads of the library's modules.

    python3 scripts/check-standard-library-doc.py [--self-test | --write]

The head of a module is the docstring before the module line of its .hih
file under standard/src: one sentence on what the module is for, lines
starting with "- " that each name a guarantee or a limit, and an example
indented by four blanks.  The reference lists every module in the order of
its name, with its head as it stands; a module without a head is listed
with the words "No description.".

--write writes the file.  Without it the file is held to what --write would
write, and a difference is a fault.  --self-test holds the reading of a head
to a module of known form and to one without a head.

Prints standard-library-doc modules=N heads=M faults=F; exit 0 when the
file is current, 1 when it is not, 9 when the self-test of a normal run
failed or a file could not be read.
"""
import os
import re
import sys
import tempfile

HEAD = re.compile(r'"""\n(.*?)\n"""', re.S)
MODULE = re.compile(r"^module\s+([A-Za-z0-9_.]+)\s+is\b", re.M)


def read_module(path):
    with open(path, encoding="ascii") as stream:
        text = stream.read()
    m = MODULE.search(text)
    if not m:
        return None
    before = text[:m.start()]
    heads = HEAD.findall(before)
    return m.group(1), (heads[0] if heads else None)


def render_head(head):
    out = []
    lines = head.split("\n")
    i = 0
    while i < len(lines):
        if lines[i].startswith("    "):
            block = []
            while i < len(lines) and (lines[i].startswith("    ") or lines[i] == ""):
                block.append(lines[i][4:] if lines[i] else "")
                i += 1
            while block and block[-1] == "":
                block.pop()
            out.append("```")
            out.extend(block)
            out.append("```")
            out.append("")
        else:
            out.append(lines[i])
            i += 1
    while out and out[-1] == "":
        out.pop()
    return out


def render(root):
    base = os.path.join(root, "standard", "src")
    modules = []
    for d, dirs, names in os.walk(base):
        dirs.sort()
        for n in names:
            if n.endswith(".hih"):
                r = read_module(os.path.join(d, n))
                if r:
                    modules.append(r)
    modules.sort(key=lambda m: m[0])
    out = ["# The standard library", "",
           "Every module of the standard library, in the order of its name, with the",
           "head of its interface: what it is for, what it guarantees, and an example.",
           "The modules named Bindings bind a C library and are unsafe; which",
           "safe module stands on each is in `docs/unsafe.md`.  This file is made by",
           "`python3 scripts/check-standard-library-doc.py --write`, and the checks hold",
           "it to the heads.", ""]
    heads = 0
    for name, head in modules:
        out.append("## " + name)
        out.append("")
        if head is None:
            out.append("No description.")
        else:
            heads += 1
            out.extend(render_head(head))
        out.append("")
    return "\n".join(out).rstrip("\n") + "\n", len(modules), heads


def self_test():
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "standard", "src", "Sub"))
        with open(os.path.join(d, "standard", "src", "A.hih"), "w") as s:
            s.write('--\n-- head\n--\n"""\nWhat A is for.\n\n- one limit\n\n    let x: Int32 := 1;\n"""\nmodule Test.A is\nend module.\n')
        with open(os.path.join(d, "standard", "src", "Sub", "B.hih"), "w") as s:
            s.write("module Test.B is\nend module.\n")
        text, n, h = render(d)
        want = ["## Test.A", "", "What A is for.", "", "- one limit", "", "```", "let x: Int32 := 1;", "```", "", "## Test.B", "", "No description."]
        held = n == 2 and h == 1 and "\n".join(want) in text
        print("standard-library-doc self-test: modules %d (want 2), heads %d (want 1), rendering %s"
              % (n, h, "held" if held else "FAILED"))
        return held


def main():
    if "--self-test" in sys.argv:
        sys.exit(0 if self_test() else 1)
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    target = os.path.join(root, "docs", "standard-library.md")
    try:
        text, n, h = render(root)
    except (OSError, UnicodeDecodeError) as e:
        print("standard-library-doc: ABORT %s -- nothing checked" % e)
        sys.exit(9)
    if "--write" in sys.argv:
        with open(target, "w", encoding="ascii") as s:
            s.write(text)
        print("standard-library-doc written modules=%d heads=%d" % (n, h))
        sys.exit(0)
    if not self_test():
        print("standard-library-doc: the self-test failed, nothing is checked")
        sys.exit(9)
    try:
        with open(target, encoding="ascii") as s:
            have = s.read()
    except OSError:
        have = None
    faults = 0 if have == text else 1
    if faults:
        print("FAULT docs/standard-library.md is not what the heads give; run with --write")
    print("standard-library-doc modules=%d heads=%d faults=%d" % (n, h, faults))
    sys.exit(0 if faults == 0 else 1)


if __name__ == "__main__":
    main()
