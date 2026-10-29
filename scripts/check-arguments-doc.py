#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""docs/arguments-from-clap.md holds to the tests it shows and to the interface
it names.

    python3 scripts/check-arguments-doc.py --self-test
    python3 scripts/check-arguments-doc.py [<root>]

With no root the tree this script lies in is checked.  The document is for
those who know clap, and three things in it are held to what exists:

- Every fence of Hilde source carries the test it is, in its info string,
  "hilde <suite>/<test>" with the suite of SUITE, and holds the Test.hiq of
  that test of test-programs/suites byte for byte.  A fence "text <suite>/<test>"
  holds the program-stdout.txt of the test byte for byte.  A fence of Hilde
  with no test named is a fault: nothing would run it.
- Every test of the suite SUITE whose name has clap in it is shown,
  with both fences, once.
- Every function the tables name, a lower case word followed by a bracket in
  a code span of a table row and not after a dot, is declared in
  standard/src/Arguments.hih.  The clap column is not read: it names clap's
  methods, which are not ours.
- Every fence of Rust carries the programme it is, "rust greet", and holds
  scripts/clap-compare/src/bin/greet.rs byte for byte; every programme there
  is shown once.  Those are the programmes cargo builds and
  scripts/clap-compare/compare.py runs.  The document names the version of
  clap that Cargo.lock locks, as "clap 4.6.7".

The last line says how many fences, tests and functions were checked and how
many faults were found.  Exit 0 with no fault, 1 with a fault, 9 when the check
could not run.  --self-test holds the checks against texts with a known answer,
and ends 1 when a check does not see the fault it is given.
"""
import os
import re
import sys
import tempfile

DOC = "docs/arguments-from-clap.md"
INTERFACE = "standard/src/Arguments.hih"
SUITE = "test-programs/suites/055-arguments"
CLAP = "scripts/clap-compare"

FENCE = re.compile(r"^```(\S*)(?: (\S+))?\s*$")
CALL = re.compile(r"(?<![.\w:])([a-z][A-Za-z0-9]*)\(")


def read(path):
    with open(path, encoding="utf-8") as stream:
        return stream.read()


def interface_functions(text):
    return set(re.findall(r"^\s+function (\w+)\(", text, re.M))


def fences(lines):
    """(language, info, body, first line) of every fence; a fence not closed is None."""
    found = []
    i = 0
    while i < len(lines):
        m = FENCE.match(lines[i])
        if m and lines[i].startswith("```") and m.group(1):
            language, info, start = m.group(1), m.group(2), i
            i += 1
            body = []
            while i < len(lines) and lines[i].rstrip() != "```":
                body.append(lines[i])
                i += 1
            if i >= len(lines):
                found.append((language, info, None, start + 1))
            else:
                found.append((language, info, "\n".join(body) + "\n", start + 1))
        i += 1
    return found


def table_cells(lines):
    """Every code span in a row of a table, from the second column on, with its line."""
    spans = []
    in_fence = False
    for number, line in enumerate(lines, 1):
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        for cell in cells[1:]:
            for span in re.findall(r"`([^`]*)`", cell):
                spans.append((span, number))
    return spans


def check(root):
    doc_path = os.path.join(root, DOC)
    iface_path = os.path.join(root, INTERFACE)
    suite_path = os.path.join(root, SUITE)
    for path in (doc_path, iface_path):
        if not os.path.isfile(path):
            print("arguments-doc: NOT RUN -- %s is missing" % path)
            return 9, ""
    if not os.path.isdir(suite_path):
        print("arguments-doc: NOT RUN -- %s is missing" % suite_path)
        return 9, ""
    lines = read(doc_path).split("\n")
    functions = interface_functions(read(iface_path))
    if len(functions) < 40:
        print("arguments-doc: NOT RUN -- the interface names only %d functions, it was not read" % len(functions))
        return 9, ""
    bin_path = os.path.join(root, CLAP, "src", "bin")
    lock_path = os.path.join(root, CLAP, "Cargo.lock")
    if not os.path.isdir(bin_path) or not os.path.isfile(lock_path):
        print("arguments-doc: NOT RUN -- %s has no src/bin or no Cargo.lock" % CLAP)
        return 9, ""
    programmes = sorted(n[:-3] for n in os.listdir(bin_path) if n.endswith(".rs"))
    if not programmes:
        print("arguments-doc: NOT RUN -- %s/src/bin has no programme" % CLAP)
        return 9, ""
    faults = 0
    shown = {}
    rust_shown = []
    checked = 0
    for language, info, body, line in fences(lines):
        if language == "rust":
            if info not in programmes:
                print("arguments-doc: line %d: a fence of rust names no programme of %s" % (line, CLAP))
                faults += 1
                continue
            if body is None:
                print("arguments-doc: line %d: the fence is not closed" % line)
                faults += 1
                continue
            checked += 1
            rust_shown.append(info)
            if read(os.path.join(bin_path, info + ".rs")) != body:
                print("arguments-doc: line %d: the fence differs from %s/src/bin/%s.rs" % (line, CLAP, info))
                faults += 1
            continue
        if language == "hilde" or (language == "text" and info):
            if not info or "/" not in info:
                print("arguments-doc: line %d: a fence of %s names no test" % (line, language))
                faults += 1
                continue
            suite, test = info.split("/", 1)
            if suite != "055-arguments":
                print("arguments-doc: line %d: %s is not a test of 055-arguments" % (line, info))
                faults += 1
                continue
            name = "Test.hiq" if language == "hilde" else "program-stdout.txt"
            path = os.path.join(suite_path, test, name)
            if body is None:
                print("arguments-doc: line %d: the fence is not closed" % line)
                faults += 1
                continue
            if not os.path.isfile(path):
                print("arguments-doc: line %d: %s has no %s" % (line, test, name))
                faults += 1
                continue
            checked += 1
            if read(path) != body:
                print("arguments-doc: line %d: the fence differs from %s/%s" % (line, test, name))
                faults += 1
            shown.setdefault(test, []).append(language)
    tests = sorted(d for d in os.listdir(suite_path) if "clap" in d and os.path.isdir(os.path.join(suite_path, d)))
    for test in tests:
        if sorted(shown.get(test, [])) != ["hilde", "text"]:
            print("arguments-doc: the test %s is shown %s, want one hilde and one text" % (test, shown.get(test, [])))
            faults += 1
    for test in shown:
        if test not in tests:
            print("arguments-doc: %s is shown and is no test with clap in its name" % test)
            faults += 1
    for programme in programmes:
        if rust_shown.count(programme) != 1:
            print("arguments-doc: the programme %s is shown %d times, want once" % (programme, rust_shown.count(programme)))
            faults += 1
    found = re.search(r'name = "clap"\nversion = "([0-9][0-9.]*)"', read(lock_path))
    if not found:
        print("arguments-doc: NOT RUN -- Cargo.lock locks no clap")
        return 9, ""
    if "clap %s" % found.group(1) not in read(doc_path):
        print("arguments-doc: the document does not name clap %s, the version Cargo.lock locks" % found.group(1))
        faults += 1
    named = 0
    for span, line in table_cells(lines):
        for name in CALL.findall(span):
            named += 1
            if name not in functions:
                print("arguments-doc: line %d: %s( is not declared in %s" % (line, name, INTERFACE))
                faults += 1
    summary = "arguments-doc fences=%d tests=%d functions-named=%d interface-functions=%d programmes=%d faults=%d" % (
        checked, len(tests), named, len(functions), len(programmes), faults)
    print(summary)
    return (1 if faults else 0), summary


def make_tree(directory, doc, hiq="module body Test is\nend module body.\n", out="a\n", names=("007-clap-x",),
              rust="fn main() {}\n", programmes=("x",), locked="4.6.7"):
    os.makedirs(os.path.join(directory, "docs"))
    os.makedirs(os.path.join(directory, "standard/src"))
    os.makedirs(os.path.join(directory, CLAP, "src", "bin"))
    for programme in programmes:
        with open(os.path.join(directory, CLAP, "src", "bin", programme + ".rs"), "w") as stream:
            stream.write(rust)
    with open(os.path.join(directory, CLAP, "Cargo.lock"), "w") as stream:
        stream.write('[[package]]\nname = "clap"\nversion = "%s"\n' % locked)
    names_list = "\n".join("    function f%d(): Unit;" % i for i in range(60))
    with open(os.path.join(directory, INTERFACE), "w") as stream:
        stream.write("module Standard.Arguments is\n    function makeCommand(): Unit;\n    function textOf(): Unit;\n" + names_list + "\nend module.\n")
    for name in names:
        d = os.path.join(directory, SUITE, name)
        os.makedirs(d)
        with open(os.path.join(d, "Test.hiq"), "w") as stream:
            stream.write(hiq)
        with open(os.path.join(d, "program-stdout.txt"), "w") as stream:
            stream.write(out)
    with open(os.path.join(directory, DOC), "w") as stream:
        stream.write(doc)


GOOD = ("# t\n\n| clap | hilde | note |\n|---|---|---|\n| `Command::new(\"x\")` | `makeCommand(\"x\", \"y\")` | n |\n\n"
        "```hilde 055-arguments/007-clap-x\nmodule body Test is\nend module body.\n```\n\n"
        "```text 055-arguments/007-clap-x\na\n```\n\n"
        "```rust x\nfn main() {}\n```\n\nMeasured with clap 4.6.7.\n")


def self_test():
    cases = [
        ("a document that holds", GOOD, {}, 0),
        ("a fence that differs by a byte", GOOD.replace("module body Test", "module  body Test"), {}, 1),
        ("an output that differs", GOOD.replace("```text 055-arguments/007-clap-x\na\n", "```text 055-arguments/007-clap-x\nb\n"), {}, 1),
        ("a function the interface does not declare", GOOD.replace("`makeCommand(\"x\", \"y\")`", "`makeComand(\"x\", \"y\")`"), {}, 1),
        ("a fence of hilde with no test named", GOOD.replace("```hilde 055-arguments/007-clap-x", "```hilde"), {}, 1),
        ("a test of the suite that the document does not show", GOOD, {"names": ("007-clap-x", "008-clap-y")}, 1),
        ("a function named in the clap column is not read", GOOD.replace("| `Command::new(\"x\")` |", "| `get_nothing(1)` |"), {}, 0),
        ("a fence of rust that differs by a byte", GOOD.replace("fn main() {}", "fn main() { }"), {}, 1),
        ("a fence of rust that names no programme", GOOD.replace("```rust x", "```rust"), {}, 1),
        ("a fence of rust that names a programme there is not", GOOD.replace("```rust x", "```rust y"), {}, 1),
        ("a programme that the document does not show", GOOD, {"programmes": ("x", "z")}, 1),
        ("a version of clap that Cargo.lock does not lock", GOOD, {"locked": "4.7.0"}, 1),
    ]
    wrong = 0
    for name, doc, extra, want in cases:
        with tempfile.TemporaryDirectory() as directory:
            make_tree(directory, doc, **extra)
            import io
            import contextlib
            buffer = io.StringIO()
            with contextlib.redirect_stdout(buffer):
                code, _ = check(directory)
            if code != want:
                wrong += 1
                print("self-test: %s -- exit %d, want %d: %s" % (name, code, want, buffer.getvalue().strip()))
    print("arguments-doc self-test cases=%d wrong=%d" % (len(cases), wrong))
    return 1 if wrong else 0


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        return self_test()
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    code, _ = check(root)
    return code


if __name__ == "__main__":
    sys.exit(main())
