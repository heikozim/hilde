#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Contracts are mandatory: every function and method an interface file
declares states one.

    python3 scripts/check-contracts.py --self-test
    python3 scripts/check-contracts.py [<tree>...]

Every .hih file below each tree is read; with no tree, standard/src and
examples of the tree this script lies in, and pkg/src and run/src, the
package tool and the launcher.  Between the line "module X is"
and the line "end module." each declaration that begins with function or
method passes when a requires or an ensures clause stands before the ";"
that ends it, or when its docstring has a line that begins "No contract:".
A declaration after the line "pragma Slot;" takes no docstring; it passes
when the last run of "--" comment lines above it has such a line, so one
comment covers a group of slots.  Each miss is printed as file:line name; the last line gives the counts.
Exit 0 when nothing misses and at least one declaration was read, 1 on a
miss, 9 when a tree is missing or no declaration was found.

The modules of EXEMPT are left out, each with the reason it has.  Other
projects written in Hilde run this script from the Hilde of their image,
over their own trees.
"""
import os
import re
import sys

SKIP_DIRS = {".git", "_build", "_e2e-work", ".count-warnings", "_run"}

# Module name and the reason rule 23 leaves it out.
EXEMPT = {
    "Standard.Arena": "its state lives in the runtime, and the runtime checks it",
    "Standard.Decimal": "each function checks the limit itself",
}

MODULE = re.compile(r"^module\s+(\S+)\s+is\s*$")
END = re.compile(r"^end module\.\s*$")
DECL = re.compile(r"^\s+(?:function|method)\s+(\w+)\s*\(")
OTHER = re.compile(r"^\s+(?:record|type|union|constant|typeclass|instance)\b")
DOC = re.compile(r'^\s*"""\s*$')
CLAUSE = re.compile(r"\b(?:requires|ensures)\b")
REASON = re.compile(r"^\s*No contract:", re.M)
SLOT = re.compile(r"^\s+pragma\s+Slot\s*;\s*$")
COMMENT = re.compile(r"^\s*--\s?(.*)$")


def misses(text):
    """The module name, the number of declarations and the misses of text,
    each a (line, name)."""
    lines = text.split("\n")
    module = None
    in_doc = False
    doc = []
    count = 0
    found = []
    note = []
    in_note = False
    slot = False
    i = 0
    while i < len(lines):
        line = lines[i]
        c = COMMENT.match(line)
        if c and not in_doc:
            if not in_note:
                note = []
            in_note = True
            note.append(c.group(1))
            i += 1
            continue
        in_note = False
        if module is None:
            m = MODULE.match(line)
            if m:
                module = m.group(1)
            i += 1
            continue
        if END.match(line):
            break
        if DOC.match(line):
            if in_doc:
                in_doc = False
            else:
                in_doc = True
                doc = []
            i += 1
            continue
        if in_doc:
            doc.append(line)
            i += 1
            continue
        m = DECL.match(line)
        if m:
            name, at = m.group(1), i + 1
            decl = line
            while not decl.rstrip().endswith(";") and i + 1 < len(lines):
                i += 1
                decl += "\n" + lines[i]
            count += 1
            reason = REASON.search("\n".join(note if slot else doc))
            if not CLAUSE.search(decl) and not reason:
                found.append((at, name))
            if not slot:
                note = []
            doc = []
            slot = False
        elif SLOT.match(line):
            slot = True
        elif OTHER.match(line):
            doc = []
            note = []
        i += 1
    return module, count, found


def files_below(root):
    for top, dirs, names in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        for n in sorted(names):
            if n.endswith(".hih"):
                yield os.path.join(top, n)


def self_test():
    good = (
        "module M is\n"
        '    """\n    Frees x.\n    No contract: it only frees.\n    """\n'
        "    function a(x: T): Unit;\n"
        "    function b(): Int64\n        ensures result = 1;\n"
        "    generic [R: Region]\n    function c(n: Int64,\n        m: Int64): Unit\n        requires n > 0;\n"
        "    typeclass Shown(T: Type) is\n"
        '        """\n        The text.\n        No contract: a text of any length.\n        """\n'
        "        method show(x: T): String;\n"
        "    end;\n"
        "    -- The slots of a driver.\n    -- No contract: each slot is an I/O result.\n\n"
        "    pragma Slot;\n    function s1(): Unit;\n"
        "    pragma Slot;\n    generic [R: Region]\n    function s2(x: &[T, R]): Unit;\n"
        "end module.\n"
    )
    bad = (
        "module M is\n"
        '    """\n    A walk.  No ensures: a walk.\n    """\n'
        "    function a(x: T): Unit;\n"
        '    """\n    No contract: for b only.\n    """\n'
        "    record R: Free is\n        n: Int64;\n    end;\n"
        "    function d(): Int64;\n"
        "    -- No contract: for e only, which is no slot.\n"
        "    function e(): Int64;\n"
        "    pragma Slot;\n    function s3(): Unit;\n"
        "    -- A slot without a reason.\n"
        "    pragma Slot;\n    function s4(): Unit;\n"
        "end module.\n"
        "    function after(): Int64;\n"
    )
    _, gn, gm = misses(good)
    _, bn, bm = misses(bad)
    want_bad = ["a", "d", "e", "s3", "s4"]
    ok_good = gn == 6 and gm == []
    ok_bad = bn == 5 and [n for _, n in bm] == want_bad
    mod, _, _ = misses("module Standard.Arena is\nend module.\n")
    ok_name = mod == "Standard.Arena" and mod in EXEMPT
    print("self-test good  declarations=%d want=6 misses=%d want=0 %s" % (gn, len(gm), "ok" if ok_good else "WRONG"))
    print("self-test bad   declarations=%d want=5 misses=%s want=%s %s" % (bn, [n for _, n in bm], want_bad, "ok" if ok_bad else "WRONG"))
    print("self-test exempt module=%s %s" % (mod, "ok" if ok_name else "WRONG"))
    return 0 if ok_good and ok_bad and ok_name else 1


def main():
    args = sys.argv[1:]
    if args == ["--self-test"]:
        return self_test()
    if not args:
        here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        args = [os.path.join(here, "standard", "src"), os.path.join(here, "examples"), os.path.join(here, "pkg", "src"), os.path.join(here, "run", "src")]
    files = decls = missed = exempt = 0
    for root in args:
        if not os.path.isdir(root):
            print("ABORT: %s is no directory -- nothing was checked" % root, file=sys.stderr)
            return 9
        for path in files_below(root):
            with open(path, encoding="utf-8") as f:
                module, n, found = misses(f.read())
            files += 1
            if module in EXEMPT:
                exempt += 1
                continue
            decls += n
            for at, name in found:
                print("%s:%d %s" % (path, at, name))
                missed += 1
    print("check-contracts: %d files, %d declarations, %d without a contract, %d modules left out by rule 23"
          % (files, decls, missed, exempt))
    if files == 0 or decls == 0:
        return 9
    return 1 if missed else 0


if __name__ == "__main__":
    sys.exit(main())
