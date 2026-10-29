#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""The files of the Unicode Character Database in the repository, and the
tables generated from them.

    python3 scripts/check-unicode-data.py --self-test
    python3 scripts/check-unicode-data.py

Run from the root of the tree.  It holds every file of
scripts/unicode/ucd/17.0.0 to its SHA-256 in SHA256SUMS there, and finds
no file that SHA256SUMS does not list; then it runs the four generators
of scripts/unicode against the tables of standard/src:

  properties     make-property-tables.py --check, UnicodeProperties.hiq
  case           make-case-tables.py --check, Unicode.hiq
  normalization  make-normalization-tables.py --check-ucd, Normalization.hiq
  grapheme       make-grapheme-tables.py --check-ucd, Grapheme.hiq

None of them needs an oracle.  Two parts of two tables cannot be checked
against the repository's data, and each is a NOT RUN line with its
reason: the listed composition exclusions of Normalization
(CompositionExclusions.txt is not in the repository) and the
Indic_Conjunct_Break bits of Grapheme (DerivedCoreProperties.txt is not).

--self-test runs the same checks on copies in _build/check-unicode-data
that are wrong in one place each -- one byte of a data file, one hex digit
of each module's table -- and every one must be found.  The last line
counts files, sums, tables and faults.  Exit 0 with no fault, 1 with a
fault, 9 when the check could not run.
"""
import hashlib
import os
import shutil
import subprocess
import sys

UCD = os.path.join("scripts", "unicode", "ucd", "17.0.0")
WORK = os.path.join("_build", "check-unicode-data")
KEPT = {"SHA256SUMS", "README.md"}
GENERATORS = [
    ("properties", ["scripts/unicode/make-property-tables.py", "--check"], "standard/src/UnicodeProperties.hiq"),
    ("case", ["scripts/unicode/make-case-tables.py", "--check"], "standard/src/Unicode.hiq"),
    ("normalization", ["scripts/unicode/make-normalization-tables.py", "--check-ucd"], "standard/src/Normalization.hiq"),
    ("grapheme", ["scripts/unicode/make-grapheme-tables.py", "--check-ucd"], "standard/src/Grapheme.hiq"),
]
NOT_RUN = [
    ("normalization listed exclusions",
     "CompositionExclusions.txt 17.0.0 is not in the repository yet"),
    ("grapheme Indic_Conjunct_Break",
     "DerivedCoreProperties.txt 17.0.0 is not in the repository yet"),
]


def sums(directory):
    """The faults of the files of directory against its SHA256SUMS, and the
    number of files held."""
    faults = []
    listed = {}
    path = os.path.join(directory, "SHA256SUMS")
    if not os.path.exists(path):
        return ["%s: no SHA256SUMS" % directory], 0
    for line in open(path, encoding="ascii"):
        digest, _, name = line.rstrip("\n").partition("  ")
        if len(digest) != 64 or not name:
            faults.append("SHA256SUMS: a line that is not a sum and a name: %r" % line)
            continue
        listed[name] = digest
    held = 0
    for name, digest in sorted(listed.items()):
        full = os.path.join(directory, name)
        if not os.path.exists(full):
            faults.append("%s: listed in SHA256SUMS and not there" % name)
            continue
        got = hashlib.sha256(open(full, "rb").read()).hexdigest()
        if got != digest:
            faults.append("%s: sha256 %s, SHA256SUMS says %s" % (name, got, digest))
        else:
            held += 1
    for name in sorted(os.listdir(directory)):
        if name not in listed and name not in KEPT:
            faults.append("%s: in the directory and not in SHA256SUMS" % name)
    return faults, held


def generator(name, command, module):
    """Run one generator's check; a fault when it does not end with 0."""
    done = subprocess.run([sys.executable, "-B"] + command + [module],
                          capture_output=True, text=True)
    said = (done.stdout + done.stderr).strip().split("\n")[-1] if (done.stdout + done.stderr).strip() else "(nothing)"
    print("%s: exit %d: %s" % (name, done.returncode, said))
    return [] if done.returncode == 0 else ["%s: the table does not agree with the data" % name]


def check():
    if not os.path.isdir(UCD):
        print("unicode-data: NOT RUN -- %s is not here (not at the root of the tree?)" % UCD)
        return 9
    faults, held = sums(UCD)
    files = len([n for n in os.listdir(UCD) if n not in KEPT])
    equal = 0
    for name, command, module in GENERATORS:
        f = generator(name, command, module)
        faults += f
        equal += 0 if f else 1
    for what, why in NOT_RUN:
        print("%s: NOT RUN -- %s" % (what, why))
    for f in faults:
        print("FAULT " + f)
    print("unicode-data files=%d sums-held=%d tables-equal=%d of %d not-run=%d faults=%d"
          % (files, held, equal, len(GENERATORS), len(NOT_RUN), len(faults)))
    return 1 if faults else 0


def flip_table_digit(path):
    """A copy of the module at path with the first hex digit of its first
    generated table changed; the copy's path."""
    text = open(path, encoding="utf-8").read()
    at = text.index("written by scripts/unicode/make-")
    at = text.index('return "', at) + len('return "')
    digit = text[at]
    changed = "1" if digit != "1" else "2"
    out = os.path.join(WORK, os.path.basename(path))
    open(out, "w", encoding="utf-8").write(text[:at] + changed + text[at + 1:])
    return out


def self_test():
    if os.path.exists(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    missed = 0
    held = 0
    try:
        # One byte of a data file changed: the sums must find it.
        data = os.path.join(WORK, "ucd")
        shutil.copytree(UCD, data)
        target = os.path.join(data, "Scripts.txt")
        raw = bytearray(open(target, "rb").read())
        raw[-2] = ord("X") if raw[-2] != ord("X") else ord("Y")
        open(target, "wb").write(bytes(raw))
        faults, _ = sums(data)
        if any(f.startswith("Scripts.txt: sha256") for f in faults):
            held += 1
            print("control held: a changed data file")
        else:
            missed += 1
            print("CONTROL MISSED: a changed data file")
        # A file SHA256SUMS does not list.
        open(os.path.join(data, "Extra.txt"), "w").write("x\n")
        faults, _ = sums(data)
        if any(f.startswith("Extra.txt: in the directory") for f in faults):
            held += 1
            print("control held: a file not listed")
        else:
            missed += 1
            print("CONTROL MISSED: a file not listed")
        # The unchanged files hold.
        faults, count = sums(UCD)
        if not faults and count > 0:
            held += 1
            print("control held: the files as they are, %d held" % count)
        else:
            missed += 1
            print("CONTROL MISSED: the files as they are: %s" % faults)
        # One hex digit of each module's table changed: its check must fail.
        for name, command, module in GENERATORS:
            copy = flip_table_digit(module)
            done = subprocess.run([sys.executable, "-B"] + command + [copy], capture_output=True, text=True)
            if done.returncode != 0:
                held += 1
                print("control held: %s with one digit changed, exit %d" % (name, done.returncode))
            else:
                missed += 1
                print("CONTROL MISSED: %s with one digit changed passed" % name)
    finally:
        shutil.rmtree(WORK)
    print("unicode-data self-test controls=%d held=%d missed=%d" % (held + missed, held, missed))
    return 1 if missed else 0


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        return self_test()
    if len(sys.argv) > 1:
        print(__doc__)
        return 9
    return check()


if __name__ == "__main__":
    sys.exit(main())
