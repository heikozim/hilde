#!/usr/bin/env python3
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Two checks of the examples of run-examples.sh.

    python3 scripts/check-examples.py readmes
    python3 scripts/check-examples.py memory <label> [--only=<dir>] [--except=<dir>]

Run from the root of the tree.  Every line of run-examples.sh that starts
with `example' or `example_stops' names a directory, a programme and its
expected output.

readmes: the output an example's README.md shows under "What comes out"
is the output its lines hold.  Each fenced block of that section is one
expected text: the standard output of an `example' line, and where the
line gives a second text for OpenBSD, that one too, and a third for FreeBSD,
that one too unless it is the text of another system; for an
`example_stops' line its standard output followed by its standard error.
The blocks and the texts must be the same, in any order.  So the README
cannot drift from what the gate holds.

memory: builds each programme the way the end-to-end runner builds a
test, after the compiler is built (./hilde): the example's Makefile
writes it as C (target c), cc compiles it with -std=c17 -Wall -Wextra,
the words of HILDE_TEST_CFLAGS and the libraries the C names in its link
manifest, and it runs in the example's directory with the words of
HILDE_TEST_WRAPPER in front.  So the gate's sanitizer run and valgrind
run reach the examples with the same flags as the suites
(scripts/check-runtime.sh).  A programme of an `example' line holds when
it ends with 0, its standard output is the text of this system and its
standard error is empty -- a sanitizer or valgrind writes its report
there.  Under valgrind the lines valgrind writes about itself, which
start with --<pid>-- or --<pid>:<level>:, are taken off first and counted in the programme's
line; its reports start with ==<pid>== and stay.  A programme of an
`example_stops' line holds when it ends with
another status and both outputs are the texts.  After the example's clean
the directory must hold exactly the names it held before: nothing is left
behind.  --only and --except name a directory as the lines name it
(examples/learn-sandbox) and may be given more than once.  The examples
the file named by HILDE_EXAMPLES_NOT_RUN lists are left out as well and
printed as NOT RUN with their reason.

One line per example or programme, then the count.  Exit 0 when every
one held and there was at least one, 1 when one did not, 9 when the check
did not run.
"""
import os
import platform
import re
import shlex
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
import sys

sys.path.insert(0, "test-programs")
import runner  # noqa: E402  the runner's cc command and link manifest

LINES_FILE = "run-examples.sh"
SECTION = "## What comes out"
FENCE = "```"
# valgrind about itself: --<pid>-- notes, and --<pid>:<level>: lines of its
# debug log, which on FreeBSD say that a sysctl of its own was refused after
# the programme entered capability mode.
VALGRIND_NOTE = re.compile(r"^--[0-9]+(-- |:[0-9]+:)")
# What valgrind says on FreeBSD about itself when the programme enters
# capability mode: three lines it writes with ==<pid>==, word for word.
VALGRIND_CAPMODE = re.compile(
    r"^==[0-9]+== (WARNING: Valgrind may not operate correctly in capability mode\."
    r"| +Please consider disabling capability by using the RUNNING_ON_VALGRIND mechanism\."
    r"| +See http://valgrind\.org/docs/manual/manual-core-adv\.html#manual-core-adv\.clientreq)$")


class Line:
    """One example line: kind, directory, programme, the standard output,
    the standard output on OpenBSD, on FreeBSD and on macOS where they
    differ, the standard error of a programme that stops."""

    def __init__(self, kind: str, directory: str, programme: str,
                 stdout: str, openbsd: str | None, stderr: str | None,
                 freebsd: str | None = None, macos: str | None = None):
        self.kind = kind
        self.directory = directory
        self.programme = programme
        self.stdout = stdout
        self.openbsd = openbsd
        self.stderr = stderr
        self.freebsd = freebsd
        self.macos = macos

    def stdout_here(self) -> str:
        if self.openbsd is not None and platform.system() == "OpenBSD":
            return self.openbsd
        if self.freebsd is not None and platform.system() == "FreeBSD":
            return self.freebsd
        if self.macos is not None and platform.system() == "Darwin":
            return self.macos
        return self.stdout


def unescape(text: str) -> str:
    """The text echo -n -e prints for an argument after bash has read it.

    Only \\n, \\t and \\$ occur.  In double quotes bash takes the backslash
    away before a dollar sign and shlex does not, so \\$ is a dollar sign.
    """
    out = []
    i = 0
    while i < len(text):
        c = text[i]
        if c != "\\":
            out.append(c)
            i += 1
            continue
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if nxt == "n":
            out.append("\n")
        elif nxt == "t":
            out.append("\t")
        elif nxt == "$":
            out.append("$")
        else:
            raise ValueError("an escape this script does not read: \\" + nxt)
        i += 2
    return "".join(out)


def example_lines() -> list[Line]:
    found = []
    with open(LINES_FILE) as stream:
        for line in stream:
            words = line.split(None, 1)
            if not words or words[0] not in ("example", "example_stops"):
                continue
            args = shlex.split(line)
            if args[0] == "example":
                if len(args) not in (4, 5, 6, 7):
                    raise ValueError("an example line with a wrong number of words: " + line.strip())
                openbsd = unescape(args[4]) if len(args) >= 5 else None
                freebsd = unescape(args[5]) if len(args) >= 6 else None
                macos = unescape(args[6]) if len(args) == 7 else None
                found.append(Line(args[0], args[1], args[2], unescape(args[3]), openbsd, None, freebsd, macos))
            else:
                if len(args) != 5:
                    raise ValueError("an example_stops line with a wrong number of words: " + line.strip())
                found.append(Line(args[0], args[1], args[2], unescape(args[3]), None, unescape(args[4])))
    return found


def examples_not_run() -> dict[str, str]:
    """The examples the file named by HILDE_EXAMPLES_NOT_RUN lists, each
    directory with its reason; empty when the variable is not set."""
    path = os.environ.get("HILDE_EXAMPLES_NOT_RUN", "")
    if not path:
        return {}
    found = {}
    with open(path) as stream:
        for line in stream:
            words = line.split(None, 1)
            if not words or words[0].startswith("#"):
                continue
            found[words[0]] = words[1].strip() if len(words) == 2 else ""
    return found


def readme_blocks(path: str) -> list[str] | None:
    """The fenced blocks of the section "What comes out", each with a final
    line break, or None when the file or the section is missing."""
    try:
        with open(path) as stream:
            lines = stream.read().split("\n")
    except OSError:
        return None
    if SECTION not in lines:
        return None
    blocks = []
    inside = False
    current: list[str] = []
    for line in lines[lines.index(SECTION) + 1:]:
        if not inside and line.startswith("## "):
            break
        if line == FENCE:
            if inside:
                blocks.append("\n".join(current) + "\n")
                current = []
            inside = not inside
        elif inside:
            current.append(line)
    return blocks


def check_readmes() -> int:
    try:
        lines = example_lines()
    except (OSError, ValueError) as e:
        print(f"readmes: NOT RUN -- {e}")
        return 9
    directories = sorted({line.directory for line in lines})
    held = 0
    bad = 0
    for directory in directories:
        want = []
        for line in lines:
            if line.directory != directory:
                continue
            if line.kind == "example":
                want.append(line.stdout)
                if line.openbsd is not None and line.openbsd not in want:
                    want.append(line.openbsd)
                # FreeBSD's text is shown once: where it is the text of
                # another system the README has one block for both.
                if line.freebsd is not None and line.freebsd not in want[-2:]:
                    want.append(line.freebsd)
                if line.macos is not None and line.macos not in want:
                    want.append(line.macos)
            else:
                want.append(line.stdout + line.stderr)
        got = readme_blocks(os.path.join(directory, "README.md"))
        if got is None:
            print(f"readmes {directory} BAD no README.md with a section \"{SECTION[3:]}\"")
            bad += 1
        elif sorted(got) != sorted(want):
            missing = [t for t in want if t not in got]
            extra = [t for t in got if t not in want]
            print(f"readmes {directory} BAD blocks {len(got)}, texts {len(want)};"
                  f" not shown: {missing!r}; shown but not held: {extra!r}")
            bad += 1
        else:
            print(f"readmes {directory} ok ({len(got)} blocks)")
            held += 1
    print(f"readmes: examples={len(directories)} held={held} bad={bad}"
          f" (want {len(directories)} held, the directories of the example lines in {LINES_FILE})")
    return 0 if bad == 0 and held == len(directories) and held > 0 else 1


def make_tool() -> str:
    return "gmake" if shutil.which("gmake") else "make"


def make(directory: str, target: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [make_tool(), "-C", directory, target],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )


def valgrind_notes(wrapper: list[str], err: str) -> tuple[str, int]:
    """Standard error without valgrind's own notes, and how many there were.

    Under valgrind a line that starts with --<pid>-- or --<pid>:<level>: is
    valgrind speaking about itself, for example of a system call it does
    not know or of its own sysctl refused in capability mode; its
    reports of the programme start with ==<pid>== and are kept, and an
    error among them ends the run with the status the wrapper names.  Three
    ==<pid>== lines are valgrind about itself too: its warning when the
    programme enters capability mode on FreeBSD.
    Without valgrind nothing is taken away.
    """
    if not wrapper or os.path.basename(wrapper[0]) != "valgrind":
        return err, 0
    kept = []
    notes = 0
    for text in err.splitlines(keepends=True):
        if VALGRIND_NOTE.match(text) or VALGRIND_CAPMODE.match(text.rstrip("\n")):
            notes += 1
        else:
            kept.append(text)
    return "".join(kept), notes


def check_programme(line: Line) -> tuple[str | None, int]:
    """None when the programme held, else the reason it did not; and the
    number of valgrind's own notes taken off its standard error."""
    c_path = os.path.join(line.directory, line.programme + ".c")
    bin_path = os.path.join(line.directory, line.programme)
    cc_cmd = runner._cc_cmd(c_path, bin_path, [])
    built = subprocess.run(cc_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if built.returncode != 0:
        return "cc exit " + str(built.returncode) + ": " + built.stderr.decode("utf-8", "replace")[:600], 0
    wrapper = os.environ.get(runner.WRAPPER_VARIABLE, "").split()
    ran = subprocess.run(
        wrapper + ["./" + line.programme],
        cwd=line.directory, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    got_out = ran.stdout.decode("utf-8", "replace")
    got_err, notes = valgrind_notes(wrapper, ran.stderr.decode("utf-8", "replace"))
    if line.kind == "example":
        if ran.returncode != 0:
            return "exit " + str(ran.returncode) + ", want 0; stderr: " + got_err[:2000], notes
        if got_err != "":
            return "standard error is not empty: " + got_err[:2000], notes
    else:
        if ran.returncode == 0:
            return "exit 0, want another status", notes
        if got_err != line.stderr:
            return "standard error differs: " + repr(got_err[:2000]) + " want " + repr(line.stderr), notes
    if got_out != line.stdout_here():
        return "standard output differs: " + repr(got_out[:2000]) + " want " + repr(line.stdout_here()), notes
    return None, notes


def check_directory(label: str, directory: str, chosen: list[Line]) -> tuple[list[str], int, int]:
    """The lines of one directory of examples: built with make c, each
    programme checked, the directory cleaned and held to what it held
    before; with the count of programmes held and of faults."""
    said: list[str] = []
    held = 0
    bad = 0
    before = sorted(os.listdir(directory))
    made = make(directory, "c")
    if made.returncode != 0:
        for line in chosen:
            if line.directory == directory:
                said.append(f"{label} {directory} {line.programme} BAD make c exit {made.returncode}: "
                            + made.stderr.decode("utf-8", "replace")[:600])
                bad += 1
        make(directory, "clean")
        return said, held, bad
    for line in chosen:
        if line.directory != directory:
            continue
        try:
            reason, notes = check_programme(line)
        except ValueError as e:
            reason, notes = str(e), 0
        # On macOS cc writes the debug information of a programme it
        # compiles and links in one step beside it, as <programme>.dSYM.
        # It belongs to this build, not to the example, and goes with it.
        debug = os.path.join(line.directory, line.programme + ".dSYM")
        if debug not in (os.path.join(directory, name) for name in before) and os.path.isdir(debug):
            shutil.rmtree(debug)
        note = f" (valgrind's own notes on standard error, not held: {notes} lines)" if notes else ""
        if reason is None:
            said.append(f"{label} {directory} {line.programme} ok{note}")
            held += 1
        else:
            said.append(f"{label} {directory} {line.programme} BAD {reason}")
            bad += 1
    cleaned = make(directory, "clean")
    after = sorted(os.listdir(directory))
    if cleaned.returncode != 0 or after != before:
        left = sorted(set(after) - set(before))
        gone = sorted(set(before) - set(after))
        said.append(f"{label} {directory} BAD clean exit {cleaned.returncode}, left {left}, gone {gone}")
        bad += 1
    return said, held, bad


def check_memory(args: list[str]) -> int:
    if not args or args[0].startswith("--"):
        print("usage: python3 scripts/check-examples.py memory <label> [--only=<dir>] [--except=<dir>]")
        return 9
    label = args[0]
    only: list[str] = []
    skip: list[str] = []
    for arg in args[1:]:
        if arg.startswith("--only="):
            only.append(arg[len("--only="):])
        elif arg.startswith("--except="):
            skip.append(arg[len("--except="):])
        else:
            print(f"{label}: NOT RUN -- an argument this script does not know: {arg}")
            return 9
    if not os.access("./hilde", os.X_OK):
        print(f"{label}: NOT RUN -- ./hilde is not built")
        return 9
    try:
        lines = example_lines()
    except (OSError, ValueError) as e:
        print(f"{label}: NOT RUN -- {e}")
        return 9
    directories = sorted({line.directory for line in lines})
    for name in only + skip:
        if name not in directories:
            print(f"{label}: NOT RUN -- {name} is not a directory of the example lines")
            return 9
    try:
        not_run = examples_not_run()
    except OSError as e:
        print(f"{label}: NOT RUN -- {e}")
        return 9
    for directory in sorted(not_run):
        if directory in directories and (not only or directory in only) and directory not in skip:
            print(f"{label} {directory} NOT RUN {not_run[directory]}")
    skip = skip + sorted(not_run)
    chosen = [line for line in lines
              if (not only or line.directory in only) and line.directory not in skip]
    # Each directory is built, run and cleaned on its own, so the
    # directories run at once, HILDE_JOBS of them (all processors without
    # it); their lines are printed in the order of the directories, as one
    # after the other prints them.
    jobs = int(os.environ.get("HILDE_JOBS", "") or os.cpu_count() or 1)
    directories = sorted({line.directory for line in chosen})
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        parts = list(pool.map(lambda d: check_directory(label, d, chosen), directories))
    held = 0
    bad = 0
    for said, h, b in parts:
        for text in said:
            print(text)
        held += h
        bad += b
    print(f"{label}: programmes={len(chosen)} held={held} bad={bad}"
          f" (want {len(chosen)} held of {len(lines)} example lines in {LINES_FILE})")
    return 0 if bad == 0 and held == len(chosen) and held > 0 else 1


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "readmes" and len(sys.argv) == 2:
        return check_readmes()
    if len(sys.argv) >= 2 and sys.argv[1] == "memory":
        return check_memory(sys.argv[2:])
    print("usage: python3 scripts/check-examples.py readmes | memory <label> [--only=<dir>] [--except=<dir>]")
    return 9


if __name__ == "__main__":
    sys.exit(main())
