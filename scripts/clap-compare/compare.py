#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""The clap programmes of docs/arguments-from-clap.md run against the output
of the Hilde programmes they model.

    python3 scripts/clap-compare/compare.py --self-test <binary-directory> [<root>]
    python3 scripts/clap-compare/compare.py <binary-directory> [<root>]

The binaries are the ones cargo builds from scripts/clap-compare (greet, pack,
convert) with the toolchain and the clap of Cargo.lock; there are none in the
gates, which have no Rust, so this runs by hand where a toolchain is.  The
root is the tree whose suite SUITE holds the Hilde output; with none it is
the tree this script lies in.

Each scenario is one command line that a Hilde programme of the suite runs, by
its label in program-stdout.txt.  What is compared depends on the kind:

- run: clap must accept the line and print exactly what the Hilde programme
  printed for it.
- refuse: clap must refuse the line (exit code not 0) and the Hilde programme
  must have refused it too (its output begins with the programme's name and a
  colon).  The words of the refusal are not compared: they differ, and the
  guide says so.
- text: the help or the version.  clap must accept the line; its output is
  compared with Hilde's and a difference is recorded, not counted as bad.

bad counts a scenario in which clap and Hilde disagree about accepting a line
or about what an accepted line gives.  --self-test plants a wrong expectation
in a run scenario and in a refuse scenario and ends 1 unless both are seen.
Exit 0 with no bad scenario, 1 with one, 9 when the check could not run.
"""
import difflib
import os
import subprocess
import sys

SUITE = os.path.join("test-programs", "suites", "055-arguments")

GREET = ("greet", "007-clap-simple", {}, (
    ("the defaults:", [], "run"),
    ("a name, a count and a flag:", ["-n", "Ann", "--times=2", "--polite=yes", "--loud"], "run"),
    ("a count out of its range:", ["--times", "9"], "refuse"),
    ("a Bool that is not one:", ["--polite=maybe"], "refuse"),
    ("a name nearly right:", ["--nmae", "Ann"], "refuse"),
    ("the version:", ["--version"], "text"),
    ("the help:", ["-h"], "text"),
))
PACK = ("pack", "008-clap-subcommands", {}, (
    ("add, with a flag and two files:", ["add", "-f", "a.txt", "b.txt"], "run"),
    ("the alias, and a global flag before the subcommand:", ["-vv", "a", "x.txt"], "run"),
    ("a global flag after the subcommand:", ["list", "-v", "--long"], "run"),
    ("no subcommand:", [], "refuse"),
    ("add without a file:", ["add", "-f"], "refuse"),
    ("a subcommand nearly right:", ["lst"], "refuse"),
    ("the help of a subcommand:", ["help", "add"], "text"),
))
CONVERT = ("convert", "009-clap-env-and-conflict", {"CONVERT_JOBS": "4"}, (
    ("the file alone, the jobs from the environment:", ["in.txt"], "run"),
    ("everything on the line, which wins over the environment:",
     ["-f", "json", "-j8", "-o", "out.json", "-x", "a.tmp", "--exclude=b.tmp", "in.txt"], "run"),
    ("an output without a format:", ["-o", "out.json", "in.txt"], "refuse"),
    ("two flags that exclude each other:", ["-q", "-v", "in.txt"], "refuse"),
    ("jobs out of the range:", ["-j", "99", "in.txt"], "refuse"),
    ("a format that is not one:", ["-f", "xml", "in.txt"], "refuse"),
    ("no input:", ["-v"], "refuse"),
))
PROGRAMMES = (GREET, PACK, CONVERT)


def sections(text, labels):
    """The output of a Hilde programme cut at its labels: {label: text after it}."""
    found = {}
    current = None
    for line in text.split("\n")[:-1]:
        if line in labels:
            current = line
            found[current] = []
        elif current is not None:
            found[current].append(line)
    return {label: "".join(line + "\n" for line in lines) for label, lines in found.items()}


def run_clap(binary, argv, env):
    """(exit code, stdout, stderr) of one run, in an environment with only what is given."""
    keep = {"PATH": os.environ.get("PATH", ""), "HOME": os.environ.get("HOME", "/")}
    keep.update(env)
    done = subprocess.run([binary] + argv, env=keep, stdin=subprocess.DEVNULL,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
    return done.returncode, done.stdout.decode("utf-8", "replace"), done.stderr.decode("utf-8", "replace")


def first_line(text):
    lines = text.strip().split("\n")
    return lines[0] if lines and lines[0] else "(nothing)"


def judge(name, label, kind, code, out, err, hilde):
    """(verdict, lines to show).  The verdicts: same, both-refuse, differs, bad."""
    if hilde is None:
        return "bad", ["  the Hilde output has no section for this label"]
    if kind == "run":
        if code == 0 and out == hilde:
            return "same", []
        return "bad", ["  clap exit %d, stdout:" % code] + ["    " + l for l in out.split("\n")[:-1]] + \
            ["  Hilde:"] + ["    " + l for l in hilde.split("\n")[:-1]]
    if kind == "refuse":
        hilde_refuses = hilde.startswith(name + ": ")
        if code != 0 and hilde_refuses:
            shown = ["  clap (exit %d):" % code] + ["    " + l for l in err.strip().split("\n")[:6]]
            return "both-refuse", shown + ["  Hilde: %s" % first_line(hilde)]
        return "bad", ["  clap exit %d, stderr: %s" % (code, first_line(err)), "  Hilde: %s" % first_line(hilde)]
    if code != 0:
        return "bad", ["  clap exit %d, stderr: %s" % (code, first_line(err))]
    if out == hilde:
        return "same", []
    diff = list(difflib.unified_diff(hilde.split("\n"), out.split("\n"), "hilde", "clap", lineterm="", n=0))
    return "differs", ["  " + l for l in diff]


def compare(bindir, root, planted=None):
    """Run every scenario; print a line each; return the counts.  planted is (name, label, new text):
    a Hilde section replaced by a wrong one, for the self-test."""
    counts = {"same": 0, "both-refuse": 0, "differs": 0, "bad": 0}
    for name, test, env, scenarios in PROGRAMMES:
        path = os.path.join(root, SUITE, test, "program-stdout.txt")
        with open(path, encoding="utf-8") as stream:
            found = sections(stream.read(), [label for label, _, _ in scenarios])
        for label, argv, kind in scenarios:
            hilde = found.get(label)
            if planted and planted[0] == name and planted[1] == label:
                hilde = planted[2]
            code, out, err = run_clap(os.path.join(bindir, name), argv, env)
            verdict, shown = judge(name, label, kind, code, out, err, hilde)
            counts[verdict] += 1
            print("%s: %s [%s] %s" % (name, label.rstrip(":"), kind, verdict))
            for line in shown:
                print(line.rstrip())
    return counts


def self_test(bindir, root):
    wrong = 0
    print("self-test: a run scenario with a wrong expectation")
    counts = compare_quiet(bindir, root, ("greet", "the defaults:", "Hello, world.\ntimes: 2\npolite: false\n"))
    seen = counts["bad"] == 1
    print("self-test: bad=%d (want 1) %s" % (counts["bad"], "ok" if seen else "WRONG"))
    wrong += 0 if seen else 1
    print("self-test: a refuse scenario whose line clap accepts")
    counts = compare_quiet(bindir, root, ("greet", "a count out of its range:", "greet: nothing wrong\n"), accept="a count out of its range:")
    seen = counts["bad"] >= 1
    print("self-test: bad=%d (want at least 1) %s" % (counts["bad"], "ok" if seen else "WRONG"))
    wrong += 0 if seen else 1
    print("self-test-cases=2 self-test-wrong=%d" % wrong)
    return 1 if wrong else 0


def compare_quiet(bindir, root, planted, accept=None):
    """compare() with its lines swallowed; with accept, the line of that label is made a valid one."""
    global PROGRAMMES
    saved = PROGRAMMES
    try:
        if accept:
            name, test, env, scenarios = GREET
            changed = tuple((label, [] if label == accept else argv, kind) for label, argv, kind in scenarios)
            PROGRAMMES = ((name, test, env, changed),)
        else:
            PROGRAMMES = tuple(p for p in PROGRAMMES if p[0] == "greet")
        real = sys.stdout
        sys.stdout = open(os.devnull, "w")
        try:
            return compare(bindir, root, planted)
        finally:
            sys.stdout.close()
            sys.stdout = real
    finally:
        PROGRAMMES = saved


def main():
    args = sys.argv[1:]
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(here))
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 9
    if args[0] == "--self-test":
        bindir = args[1] if len(args) > 1 else None
        if len(args) > 2:
            root = args[2]
        if not bindir:
            print("clap-compare: NOT RUN -- --self-test needs the binary directory")
            return 9
    else:
        bindir = args[0]
        if len(args) > 1:
            root = args[1]
    for name, _, _, _ in PROGRAMMES:
        if not os.access(os.path.join(bindir, name), os.X_OK):
            print("clap-compare: NOT RUN -- %s is not an executable in %s" % (name, bindir))
            return 9
    if args[0] == "--self-test":
        return self_test(bindir, root)
    counts = compare(bindir, root)
    total = sum(counts.values())
    print("clap-compare scenarios=%d same=%d both-refuse=%d differs=%d bad=%d" %
          (total, counts["same"], counts["both-refuse"], counts["differs"], counts["bad"]))
    return 1 if counts["bad"] else 0


if __name__ == "__main__":
    sys.exit(main())
