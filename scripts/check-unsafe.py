#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Unsafe code in the standard library stands only in the modules
docs/unsafe.md lists, and a module a program imports stays safe.

    python3 scripts/check-unsafe.py --self-test
    python3 scripts/check-unsafe.py [<root>]

Every module under standard/src and bindings/generated is read, with its
comments, docstrings and string literals left out of the code.  A module is
unsafe when its code says pragma Unsafe_Module, pragma Foreign_Import or
@embed.  Five faults, one line each:

  unlisted   an unsafe module docs/unsafe.md does not list
  listed     a module docs/unsafe.md lists that is not there, not at the
             files its row names, not unsafe, or not named Bindings.
  head       a binding (the first table of docs/unsafe.md) whose interface
             does not begin with its explanation: a docstring that begins
             with "Binds", says it is an unsafe module, and names the safe
             module of its row as the safe module built on it
  memory     a module docs/unsafe.md does not list that imports Hilde.Memory
  pointer    a module docs/unsafe.md does not list whose interface names
             Address[ or Pointer[, the raw types of Hilde.Memory

Then a count line.  Exit 0 with no fault, 1 with one, 9 when nothing could
be read.  --self-test holds the check against trees with a known answer and
exits 1 when one goes the wrong way.
"""
import os
import re
import sys

UNSAFE = re.compile(r"\bpragma\s+Unsafe_Module\b|\bpragma\s+Foreign_Import\b|@embed\b")
MEMORY = re.compile(r"\bimport\s+Hilde\.Memory\b")
POINTER = re.compile(r"\b(Address|Pointer)\s*\[")
NAME = re.compile(r"\bmodule\s+(?:body\s+)?([A-Z][A-Za-z0-9_.]*)\s+is\b")
ROW = re.compile(r"^\|\s*`([A-Z][A-Za-z0-9_.]*)`\s*\|\s*`([^`]+\.hih)`\s*,\s*`\.hiq`\s*\|(.*)\|\s*$")
SAFE = re.compile(r"`((?:Standard)\.[A-Za-z0-9_.]+)`\s*$")


def code_of(text):
    """The text without comments, docstrings and the insides of string
    literals, so that a word in prose never counts as code."""
    out = []
    i, n = 0, len(text)
    while i < n:
        if text.startswith('"""', i):
            j = text.find('"""', i + 3)
            i = n if j < 0 else j + 3
            out.append(" ")
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"' and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append('""')
            i = j + 1
        elif text.startswith("--", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def head_of(text):
    """The first docstring of an interface, with its line breaks and runs
    of blanks made one blank, or None when code comes before it."""
    i = text.find('"""')
    if i < 0:
        return None
    before = code_of(text[:i])
    if before.strip():
        return None
    j = text.find('"""', i + 3)
    if j < 0:
        return None
    return " ".join(text[i + 3:j].split())


def listing_of(md):
    """The rows of docs/unsafe.md: module -> (interface path, table, safe
    module).  The table is 'bindings' under the heading "The bindings" and
    'declarations' under "The declarations of C"."""
    rows = {}
    table = None
    for line in md.splitlines():
        if line.startswith("## "):
            h = line[3:].strip()
            table = "bindings" if h == "The bindings" else "declarations" if h == "The declarations of C" else None
            continue
        m = ROW.match(line)
        if m and table:
            safe = None
            if table == "bindings":
                s = SAFE.search(m.group(3).strip())
                safe = s.group(1) if s else None
            rows[m.group(1)] = (m.group(2), table, safe)
    return rows


def faults(files, md):
    """files: path -> text for every .hih and .hiq of the library; md: the
    text of docs/unsafe.md.  Returns (modules, listed, faults)."""
    listed = listing_of(md)
    modules = {}
    for path in sorted(files):
        if not path.endswith(".hiq"):
            continue
        hih = path[:-4] + ".hih"
        body = files[path]
        iface = files.get(hih, "")
        m = NAME.search(code_of(body))
        name = m.group(1) if m else path
        code = code_of(body) + "\n" + code_of(iface)
        modules[name] = {
            "hih": hih,
            "unsafe": bool(UNSAFE.search(code)),
            "memory": bool(MEMORY.search(code)),
            "pointer": bool(POINTER.search(code_of(iface))),
            "head": head_of(iface),
        }
    out = []
    for name, mod in sorted(modules.items()):
        row = listed.get(name)
        if mod["unsafe"] and row is None:
            out.append(("unlisted", name, "unsafe, and docs/unsafe.md does not list it"))
        if row is None:
            if mod["memory"]:
                out.append(("memory", name, "imports Hilde.Memory and is not a listed binding"))
            if mod["pointer"]:
                out.append(("pointer", name, "its interface names a raw type of Hilde.Memory"))
    for name, (hih, table, safe) in sorted(listed.items()):
        if not name.startswith("Bindings."):
            out.append(("listed", name, "listed, and its name does not begin with Bindings."))
        mod = modules.get(name)
        if mod is None:
            out.append(("listed", name, "listed, and no module of that name is there"))
            continue
        if mod["hih"] != hih:
            out.append(("listed", name, "listed at %s, found at %s" % (hih, mod["hih"])))
        if not mod["unsafe"]:
            out.append(("listed", name, "listed, and not unsafe"))
        if table != "bindings":
            continue
        head = mod["head"] or ""
        want = "%s is the safe module built on it" % safe if safe else None
        if not head.startswith("Binds ") or "unsafe module" not in head or want is None or want not in head:
            out.append(("head", name, "its interface does not begin with the explanation of a binding"))
    return modules, listed, out


def read_tree(root):
    files = {}
    for top in ("standard/src", "bindings/generated"):
        for d, _, names in os.walk(os.path.join(root, top)):
            for fn in names:
                if fn.endswith((".hih", ".hiq")):
                    full = os.path.join(d, fn)
                    with open(full, encoding="utf-8") as f:
                        files[os.path.relpath(full, root)] = f.read()
    with open(os.path.join(root, "docs", "unsafe.md"), encoding="utf-8") as f:
        md = f.read()
    return files, md


HEAD = '"""\nBinds libx, the C library of X, through\nthe runtime.\n\nIt hands addresses to C, so it is an unsafe\nmodule.  Standard.X is the safe module built\non it, and the one a program imports.\n"""\n'
MD = (
    "# The unsafe modules\n\n## The bindings\n\n"
    "| module | files | binds | why | safe |\n| --- | --- | --- | --- | --- |\n"
    "| `Bindings.X` | `standard/src/Bindings/X.hih`, `.hiq` | libx | addresses | `Standard.X` |\n\n"
    "## The declarations of C\n\n| module | files | from | used by |\n| --- | --- | --- | --- |\n"
    "| `Bindings.C.X` | `bindings/generated/X.hih`, `.hiq` | spec | `Bindings.X` |\n"
)


def base():
    return {
        "standard/src/Bindings/X.hih": "-- licence\n" + HEAD + "module Bindings.X is\n    function f(): Unit;\nend module.\n",
        "standard/src/Bindings/X.hiq": "module body Bindings.X is\n    pragma Unsafe_Module;\n    function f(): Unit is\n        @embed(Unit, \"g()\");\n    end;\nend module body.\n",
        "bindings/generated/X.hih": "import Hilde.Memory (\n    Address\n);\nmodule Bindings.C.X is\n    function g(p: Address[Unit]): Unit;\nend module.\n",
        "bindings/generated/X.hiq": "module body Bindings.C.X is\n    pragma Unsafe_Module;\n    function g(p: Address[Unit]): Unit is\n        pragma Foreign_Import(External_Name => \"g\");\n    end;\nend module body.\n",
        "standard/src/X.hih": '"""\nSafe.  Speaks of an Address[T] in prose.\n"""\nmodule Standard.X is\n    -- not a Pointer[T] either\n    function f(): Unit;\nend module.\n',
        "standard/src/X.hiq": 'module body Standard.X is\n    function f(): Unit is\n        printLn("@embed in a string");\n    end;\nend module body.\n',
    }


def self_test():
    def with_(changes, md=MD):
        files = base()
        for path, (old, new) in changes.items():
            if old is None:
                files[path] = new
            elif new is None:
                del files[path]
            else:
                assert files[path].count(old) == 1, (path, old)
                files[path] = files[path].replace(old, new)
        return files, md

    cases = [
        ("a clean tree", with_({}), []),
        ("an unsafe module not listed", with_({}, MD.replace("| `Bindings.X` |", "| `Bindings.Y` |")),
         ["unlisted", "listed"]),
        ("an @embed in a safe module", with_({"standard/src/X.hiq": ('printLn("@embed in a string");', '@embed(Unit, "h()");')}),
         ["unlisted"]),
        ("a listed module that is safe", with_({"standard/src/Bindings/X.hiq": (None, "module body Bindings.X is\n    function f(): Unit is\n        skip;\n    end;\nend module body.\n")}),
         ["listed"]),
        ("a listed module not named Bindings.", with_(
            {"standard/src/X.hiq": ('printLn("@embed in a string");', "pragma Unsafe_Module;")},
            MD + "| `Standard.X` | `standard/src/X.hih`, `.hiq` | spec | `Bindings.X` |\n"),
         ["listed"]),
        ("a listed module missing",with_({"bindings/generated/X.hiq": ("x", None), "bindings/generated/X.hih": ("x", None)}),
         ["listed"]),
        ("a binding without its explanation", with_({"standard/src/Bindings/X.hih": ("so it is an unsafe\nmodule", "so it is\nspecial")}),
         ["head"]),
        ("an explanation naming another module", with_({"standard/src/Bindings/X.hih": ("Standard.X is the safe", "Standard.Z is the safe")}),
         ["head"]),
        ("code before the explanation", with_({"standard/src/Bindings/X.hih": ("-- licence\n", "import A (b);\n")}),
         ["head"]),
        ("a safe module importing memory", with_({"standard/src/X.hih": ("module Standard.X is", "import Hilde.Memory (\n    Address\n);\nmodule Standard.X is")}),
         ["memory"]),
        ("a pointer in a safe interface", with_({"standard/src/X.hih": ("function f(): Unit;", "function f(p: Pointer[Nat8]): Unit;")}),
         ["pointer"]),
        ("a pointer in a safe body only", with_({"standard/src/X.hiq": ("function f(): Unit is", "function f(): Unit is\n        let p: Pointer [Nat8] := q;")}),
         []),
    ]
    wrong = 0
    for label, (files, md), want in cases:
        got = sorted(k for k, _, _ in faults(files, md)[2])
        ok = got == sorted(want)
        wrong += 0 if ok else 1
        print("self-test %-38s faults=%s want=%s %s" % (label, ",".join(got) or "-", ",".join(sorted(want)) or "-", "ok" if ok else "WRONG"))
    print("self-test-cases=%d self-test-wrong=%d" % (len(cases), wrong))
    return 1 if wrong else 0


def main():
    args = sys.argv[1:]
    if args == ["--self-test"]:
        return self_test()
    if len(args) > 1:
        print("usage: check-unsafe.py [--self-test | <root>]", file=sys.stderr)
        return 9
    root = args[0] if args else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        files, md = read_tree(root)
    except OSError as e:
        print("ABORT: %s" % e)
        return 9
    modules, listed, found = faults(files, md)
    if not modules or not listed:
        print("ABORT: no module or no row of docs/unsafe.md in %s -- nothing was checked" % root)
        return 9
    for kind, name, why in found:
        print("%s %s: %s" % (kind, name, why))
    unsafe = sum(1 for m in modules.values() if m["unsafe"])
    print("unsafe modules=%d unsafe=%d listed=%d faults=%d" % (len(modules), unsafe, len(listed), len(found)))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
