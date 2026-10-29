#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""docs/learning-hilde.md holds to the files and the tests it shows.

    python3 scripts/check-learning-doc.py --self-test
    python3 scripts/check-learning-doc.py [<root>]

With no root the tree this script lies in is checked.  The guide's rule is
that nothing in it is unchecked, and a program holds it, from the first
section to the last:

- Every fence is an excerpt of a file under examples/ or test-programs/,
  line for line, in one piece, with the indentation of the file taken off.
  A fence that is in no file is a fault.
- A fence that begins with the word hilde is a command line and is read as
  one: its command is one that lib/CliParser.ml takes, each option it gives
  is one that file names, and each file it names under standard/, examples/
  or test-programs/ exists.  The files of the programme itself (Main.hih)
  are the reader's own and are not looked for.
- Every row of a table that has the columns "Code" and a column of tests
  names tests that exist, each with a hilde-stderr.txt, and the codes of the
  row are exactly the codes those tests give.  The suite is in the heading of
  the column, "Test (in `<suite>/`)", or in the name of the test,
  `<suite>/<test>`.
- Every other test the text names in a code span, `<test>`,
  exists in some suite; every example it names, `examples/learn-tasks/`, is
  one that run-examples.sh runs.

The last line says how many fences, rows and names were checked and how many
faults were found.  Exit 0 with no fault, 1 with a fault, 9 when the check
could not run.  --self-test plants faults in the guide itself, one at a time,
and ends 1 when a check does not see the fault it is given or when the guide
as it is has a fault.
"""
import os
import re
import sys

DOC = "docs/learning-hilde.md"
FROM = "# Writing Hilde: a guide for models"
SUITES = "test-programs/suites"
SOURCES = (".hiq", ".hih", ".jinja")
PARSER = "lib/CliParser.ml"
OWN = ("standard/", "examples/", "test-programs/")


def read(path):
    with open(path, encoding="utf-8", errors="replace") as stream:
        return stream.read()


def source_files(root):
    """Every source file under examples/ and test-programs/, as (path, lines)."""
    found = []
    for top in ("examples", "test-programs"):
        for directory, _, names in os.walk(os.path.join(root, top)):
            for name in sorted(names):
                if name.endswith(SOURCES):
                    found.append((os.path.join(directory, name), read(os.path.join(directory, name)).split("\n")))
    return found


def indent(line):
    return len(line) - len(line.lstrip(" "))


def find_excerpt(block, files):
    """The file and line where block stands in one piece, with the file's indentation taken off."""
    first = block[0].strip()
    for path, lines in files:
        for i, line in enumerate(lines):
            if line.strip() != first:
                continue
            shift = indent(line) - indent(block[0])
            if shift < 0:
                continue
            for k, wanted in enumerate(block):
                if i + k >= len(lines):
                    break
                got = lines[i + k]
                if wanted.strip() == "" and got.strip() == "":
                    continue
                if got[:shift].strip() != "" or got[shift:].rstrip() != wanted.rstrip():
                    break
            else:
                return path, i + 1
    return None


def fences(lines):
    """The body of every fence, with the lines before it cut off at the closing fence."""
    found = []
    current = None
    for line in lines:
        if line.startswith("```"):
            if current is None:
                current = []
            else:
                while current and current[-1] == "":
                    current.pop()
                found.append(current)
                current = None
        elif current is not None:
            current.append(line)
    return found


def command_findings(block, root):
    """The faults of a fence that is a command line of hilde, continued with a backslash."""
    words = " ".join(line.rstrip("\\").strip() for line in block).split()
    parser = read(os.path.join(root, PARSER))
    # A command matched alone, PositionalArg "compile", or among others,
    # PositionalArg ("compile" | "build").
    if len(words) < 2 or not re.search(r'PositionalArg \(?(?:"[a-z-]+" \| )*"%s"' % re.escape(words[1]), parser):
        return ["the command line has no command that %s takes: %s" % (PARSER, block[0])]
    findings = []
    for word in words[2:]:
        if word.startswith("--"):
            option = word.split("=")[0]
            if not re.search('"%s["=]' % re.escape(option), parser):
                findings.append("the command line gives %s, which %s does not name" % (option, PARSER))
            continue
        for path in word.split(","):
            if path.endswith((".hih", ".hiq")) and path.startswith(OWN) and not os.path.isfile(os.path.join(root, path)):
                findings.append("the command line names %s, which is not a file" % path)
    return findings


def stderr_code(path):
    """The code of the first error in the expected output of a test, or None."""
    codes = re.findall(r'"code": "(H\d{4})"', read(path))
    return codes[0] if codes else None


def check_text(text, root):
    """(findings, fences, rows, names) for the guide text, against the tree at root."""
    findings = []
    if FROM not in text:
        return ["the heading %r is not in the guide" % FROM.strip()], 0, 0, 0
    part = text[text.index(FROM):]
    lines = part.split("\n")
    files = source_files(root)
    blocks = fences(lines)
    for block in blocks:
        if block and re.match(r"hilde\s", block[0]):
            findings.extend(command_findings(block, root))
        elif not block or find_excerpt(block, files) is None:
            findings.append("a fence is in no file of examples/ or test-programs/: %s" % (block[0] if block else "(empty)"))
    suite = None
    rows = 0
    for line in lines:
        heading = re.search(r"Test \(in `([0-9a-z-]+)/`\)", line)
        if heading:
            suite = heading.group(1)
        elif line.startswith("| The compiler refuses | Code | Test |"):
            suite = None
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| The compiler"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != 3:
            continue
        rows += 1
        codes = set(re.findall(r"H\d{4}", cells[1]))
        got = set()
        for name in re.findall(r"`([0-9a-z/-]+)`", cells[2]):
            path = os.path.join(root, SUITES, name if "/" in name else "%s/%s" % (suite, name), "hilde-stderr.txt")
            if not os.path.isfile(path):
                findings.append("no test with an expected error at %s" % path[len(root) + 1:])
            else:
                got.add(stderr_code(path) or "none")
        if got != codes:
            findings.append("the row [%s] says %s and its tests give %s" % (cells[0][:50], sorted(codes), sorted(got)))
    names = 0
    every = set()
    suites = os.path.join(root, SUITES)
    for entry in os.listdir(suites):
        if os.path.isdir(os.path.join(suites, entry)):
            every.update(os.listdir(os.path.join(suites, entry)))
    for name in sorted(set(re.findall(r"`(\d{3}-[a-z0-9-]+)`", part))):
        names += 1
        if name not in every and not os.path.isdir(os.path.join(suites, name)):
            findings.append("the test %s is in no suite" % name)
    runner = read(os.path.join(root, "run-examples.sh"))
    for example in sorted(set(re.findall(r"`examples/([a-z0-9-]+)/`", part))):
        names += 1
        if not os.path.isdir(os.path.join(root, "examples", example)) or ("examples/" + example) not in runner:
            findings.append("the example %s is not one that run-examples.sh runs" % example)
    return findings, len(blocks), rows, names


def self_test(root):
    text = read(os.path.join(root, DOC))
    wrong = 0
    findings, _, _, _ = check_text(text, root)
    print("self-test: the guide as it is has %d faults (want 0)" % len(findings))
    wrong += 1 if findings else 0
    cases = (
        ("a letter of a fence changed", "        code: Nat8;", "        code: Nat9;"),
        ("a code of a row changed", "| H3061 | `020-unsatisfied-constraint` |", "| H3062 | `020-unsatisfied-constraint` |"),
        ("a test that does not exist", "`101-missing-variant-level-1`", "`101-missing-variant-level-9`"),
        ("an example that is not run", "`examples/learn-match/`", "`examples/learn-nothing/`"),
        ("a letter of a fence in section 4 changed", "    seat: Nat32;", "    seat: Nat33;"),
        ("a code of a row in section 4 changed", "| H4008 | `006-linearity/008-consume-twice` |", "| H4009 | `006-linearity/008-consume-twice` |"),
        ("a command of hilde that does not exist", "hilde compile standard/src/String.hih", "hilde compyle standard/src/String.hih"),
        ("an option of a command line that does not exist", "--entrypoint=Main:main", "--entrypoynt=Main:main"),
        ("a file of a command line that does not exist", "standard/src/String.hih,standard/src/String.hiq", "standard/src/Strung.hih,standard/src/String.hiq"),
    )
    for what, old, new in cases:
        if text.count(old) < 1:
            print("self-test: %s: the text to change is not in the guide" % what)
            wrong += 1
            continue
        found, _, _, _ = check_text(text.replace(old, new, 1), root)
        ok = len(found) >= 1
        print("self-test: %s: %d faults seen (want at least 1) %s" % (what, len(found), "ok" if ok else "WRONG"))
        wrong += 0 if ok else 1
    print("self-test-cases=%d self-test-wrong=%d" % (len(cases) + 1, wrong))
    return 1 if wrong else 0


def main():
    args = sys.argv[1:]
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if args and args[0] != "--self-test":
        root = args[0]
    if not os.path.isfile(os.path.join(root, DOC)):
        print("learning-doc: NOT RUN -- %s is not in %s" % (DOC, root))
        return 9
    if args and args[0] == "--self-test":
        return self_test(root)
    findings, blocks, rows, names = check_text(read(os.path.join(root, DOC)), root)
    for finding in findings:
        print("learning-doc: %s" % finding)
    print("learning-doc fences=%d rows=%d names=%d faults=%d" % (blocks, rows, names, len(findings)))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
