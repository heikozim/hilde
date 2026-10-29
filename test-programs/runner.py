#!/usr/bin/env python3
# Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
# Hilde is derived from the Austral project and extends it substantially.
# Modified by Heiko Zimmermann, 2026.
"""
This script runs the end-to-end tests of the compiler.
"""
import functools
import os
import re
import shutil
import signal
import subprocess
import time
from concurrent.futures import ProcessPoolExecutor, Future

#
# Constants
#

# The `test-programs/` directory.
DIR: str = "test-programs/"

# Every test program runs in a working directory of its own,
# `_e2e-work/<suite>_<test>/' under the tree, made before the run and removed
# after it -- and the removal is checked, as `test -e' would check it.  A
# programme run in the tree itself would leave its files there: the kernel
# writes the `core' of 032-arena-guard-page/001, which crashes on purpose,
# and 036, 039 and 049 make files of their own.  The name starts with `_'
# so that dune does not look into it, and .gitignore names it.  The test's
# C file and binary lie in that directory too, and the programme runs in
# `run' below it.
WORK_BASE: str = "_e2e-work"

# The tree's path, for a program that reads a file of the tree --
# the replayer of 047, the scripts of 049, so that they do not depend on
# the depth of WORK_BASE.  The runner runs in the tree, so its own
# directory is the value.
TREE_VARIABLE: str = "HILDE_TREE"

# A variable that is set and empty, for 040-process/002-environment,
# which holds that such a variable reads as Some("") and not as None.  A
# program cannot set its own environment in Hilde, so the runner does it.
EMPTY_VARIABLE: str = "HILDE_TEST_EMPTY"

# A test may carry `env.txt', one NAME=VALUE per line, set in its
# program's environment over whatever the runner was started with.  The
# task tests use it for HILDE_TASK_THREADS: the ones that assert the
# interleaving of one thread say 1, the ones that must run on several say
# how many, so that a machine with one processor still runs them on
# several.  A name is capitals, digits and `_'; a value is printable ASCII.
ENV_FILE: str = "env.txt"
ENV_LINE: re.Pattern = re.compile(r"^([A-Z][A-Z0-9_]*)=([ -~]*)$")

# A test may carry `server.txt' naming the kind of database server
# its programme talks to.  The runner starts one for the test with
# scripts/db/server.sh before the programme, puts the NAME=VALUE lines the
# script prints into the programme's environment, and stops the server
# after it; a server that does not start, or whose directory is not removed
# afterwards, fails the test.
SERVER_FILE: str = "server.txt"
SERVER_KINDS: tuple[str, ...] = ("postgres", "mariadb")
SERVER_SCRIPT: str = os.path.join("scripts", "db", "server.sh")

# Three settings for the gate's runs that put an
# instrument around the programmes.
#
# HILDE_TEST_WRAPPER: words put in front of every test programme's command,
# split on whitespace as HILDE_TEST_CFLAGS is -- valgrind and its options.
WRAPPER_VARIABLE: str = "HILDE_TEST_WRAPPER"
# HILDE_TEST_SUITES: the directory the suites are read from instead of
# test-programs/suites -- the controls of the instruments, which fail under
# their instrument on purpose and so cannot be part of the ordinary run.
SUITES_VARIABLE: str = "HILDE_TEST_SUITES"
# HILDE_TEST_NOT_RUN: a file naming tests that are not run, one per line,
# `<suite>/<test> <reason>'; blank lines and lines starting with `#' are
# skipped.  Each named test is printed NOT RUN with its reason instead of
# being run.  A line without a reason, a line naming a test the collection
# does not have, and a test named twice end the run: a list that has gone
# stale must not hide a test by a name that no longer means it.
NOT_RUN_VARIABLE: str = "HILDE_TEST_NOT_RUN"


#
# Error Reporting
#


def report(properties, outputs):
    print("\n\n--- BEGIN ERROR ---")
    for name, value in properties:
        print(f"{name}: {value}")
    for name, value in outputs:
        print(f"--- BEGIN {name} ---")
        print(value)
        print(f"--- END {name} ---\n")
    print("--- END ERROR ---")
    exit(-1)


#
# Classes
#


class Test(object):
    """
    Base class of test objects.
    """

    name: str
    suite_name: str
    directory: str
    work_dir: str
    run_dir: str
    c_path: str
    bin_path: str

    def __init__(self, name: str, suite_name: str, directory: str, cli: str | None):
        self.name = name
        self.suite_name = suite_name
        self.directory = directory
        self.cli = cli
        # Everything of one test lies in one directory under
        # WORK_BASE -- the C file, the binary, and `run', the programme's
        # working directory.  Nothing goes to /tmp, where it would stay
        # behind.  `run' is a directory of its own so that the
        # programme's working directory holds only what the programme makes.
        ident: str = suite_name + "_" + name
        self.work_dir = os.path.join(WORK_BASE, ident)
        self.run_dir = os.path.join(self.work_dir, "run")
        self.c_path = os.path.join(self.work_dir, "program.c")
        self.bin_path = os.path.join(self.work_dir, "program.bin")


class TestSuccess(Test):
    """
    A test that is expected to succeed: the program ends with the exit
    status expected_exit, 0 unless program-exit.txt names another.
    """

    expected_output: str | None
    expected_exit: int

    def __init__(
        self,
        name: str,
        suite_name: str,
        directory: str,
        cli: str | None,
        expected_output: str | None,
        expected_exit: int = 0,
    ):
        super().__init__(name, suite_name, directory, cli)
        self.expected_output = expected_output
        self.expected_exit = expected_exit


class TestFailure(Test):
    """
    A test that is expected to fail when compiling the code.
    """

    expected_compiler_error: str

    def __init__(
        self,
        name: str,
        suite_name: str,
        directory: str,
        cli: str | None,
        expected_compiler_error: str,
    ):
        super().__init__(name, suite_name, directory, cli)
        self.expected_compiler_error = expected_compiler_error


class TestProgramFailure(Test):
    """
    A test that is expected to compile successfully, but the compiled program
    should return a failure exit code, and print to stderr.

    With `program-stdout.txt` beside `program-stderr.txt`
    the standard output is checked as well: the run must fail AND
    both outputs must match.  Without it, standard output is not looked at,
    as before.
    """

    expected_program_stderr: str
    expected_program_stdout: str | None

    def __init__(
        self,
        name: str,
        suite_name: str,
        directory: str,
        cli: str | None,
        expected_program_stderr: str,
        expected_program_stdout: str | None = None,
    ):
        super().__init__(name, suite_name, directory, cli)
        self.expected_program_stderr = expected_program_stderr
        self.expected_program_stdout = expected_program_stdout


class TestResult(object):
    """
    Base class of test results.
    """

    test: Test

    def __init__(self, test: Test):
        self.test = test


class TestPass(TestResult):
    """
    Represents a passing test.
    """

    def __init__(self, test: Test):
        super().__init__(test)


class TestFail(TestResult):
    """
    Represents a test that failed.
    """

    hilde_cmd: list[str] | None
    cc_cmd: list[str] | None
    reason: str
    outputs: list[tuple[str, str]]

    def __init__(
        self,
        test: Test,
        hilde_cmd: list[str] | None,
        cc_cmd: list[str] | None,
        reason: str,
        outputs: list[tuple[str, str]],
    ):
        super().__init__(test)
        self.hilde_cmd = hilde_cmd
        self.cc_cmd = cc_cmd
        self.reason = reason
        self.outputs = outputs


class TestNotRun(TestResult):
    """
    A test named in the HILDE_TEST_NOT_RUN file: not run, with the reason
    the file gives.
    """

    reason: str

    def __init__(self, test: Test, reason: str):
        super().__init__(test)
        self.reason = reason


#
# Reporting
#


def report_test_results(results: list[TestResult]):
    fails: list[TestFail] = []

    for result in results:
        if isinstance(result, TestPass):
            report_pass(result)
        elif isinstance(result, TestFail):
            report_fail(result)
            fails.append(result)
        elif isinstance(result, TestNotRun):
            report_not_run(result)
        else:
            raise ValueError("Unknown test result type: ", result)

    if fails:
        with open("FAILURES.txt", "w") as stream:
            for fail in fails:
                report_fail_details(fail, stream)

        print("\n\nDetailed failures written to FAILURES.txt")


def report_pass(result: TestPass):
    suite: str = result.test.suite_name
    name: str = result.test.name
    print(f"{suite.ljust(45)}  {name.ljust(45)}  PASS")


def report_fail(result: TestFail):
    suite: str = result.test.suite_name
    name: str = result.test.name
    print(f"{suite.ljust(45)}  {name.ljust(45)}  FAIL")


def report_not_run(result: TestNotRun):
    suite: str = result.test.suite_name
    name: str = result.test.name
    print(f"{suite.ljust(45)}  {name.ljust(45)}  NOT RUN  {result.reason}")


def report_fail_details(result: TestFail, stream):
    print("Suite:", result.test.suite_name, file=stream)
    print("Test:", result.test.name, file=stream)
    print("C File:", result.test.c_path, file=stream)
    print("Bin File:", result.test.bin_path, file=stream)
    print("  (both removed with the test's directory; the commands below make them again)", file=stream)
    print("Hilde command:", try_join(result.hilde_cmd), file=stream)
    print("cc command:", try_join(result.cc_cmd), file=stream)
    print("Reason:", result.reason, file=stream)
    for key, value in result.outputs:
        print(key, file=stream)
        for line in value.split("\n"):
            print(f"\t{line}", file=stream)
        print(file=stream)
    print("\n\n\n\n\n", file=stream)


def try_join(l: list[str] | None) -> str:
    if l is None:
        return ""
    else:
        return " ".join(l)


#
# Collection
#


def collect_tests() -> list[Test]:
    """
    Get the list of all test suites.
    """
    # Result aggregator.
    tests: list[Test] = []
    # Find the `suites/`` directory, or the one HILDE_TEST_SUITES names.
    suites_dir: str = os.environ.get(SUITES_VARIABLE) or os.path.join(DIR, "suites")
    if not os.path.isdir(suites_dir):
        raise ValueError(f"{suites_dir} is not a directory of suites.")
    # Find the test suites.
    suite_names: list = sorted(os.listdir(suites_dir))
    # Iterate over each test suite.
    for suite_name in suite_names:
        # Find the tests in this suite.
        suite_dir: str = os.path.join(suites_dir, suite_name)
        test_names: list = sorted(
            [name for name in os.listdir(suite_dir) if name != "README.md"]
        )
        # Iterate over each test.
        for test_name in test_names:
            test_dir: str = os.path.join(suite_dir, test_name)
            expected_error: str | None = _get_file_contents(
                test_dir, "hilde-stderr.txt"
            )
            expected_output: str | None = _get_file_contents(
                test_dir, "program-stdout.txt"
            )
            program_stderr: str | None = _get_file_contents(
                test_dir, "program-stderr.txt"
            )
            cli: str | None = _get_file_contents(test_dir, "cli.txt")
            expected_exit: int | None = _get_exit_status(test_dir)
            if (expected_exit is not None) and (
                (expected_error is not None) or (program_stderr is not None)
            ):
                raise ValueError(
                    f"{test_dir}: `program-exit.txt` belongs to a program that ends normally."
                )
            if (expected_error is not None) and (expected_output is not None):
                raise ValueError(
                    "Can't have both `hilde-stderr.txt` and `program-stdout.txt` in the same test."
                )
            elif (expected_error is not None) and (expected_output is None):
                # The test should fail to compile, and the compiler output must
                # match the contents of the file.
                tests.append(
                    TestFailure(
                        name=test_name,
                        suite_name=suite_name,
                        directory=test_dir,
                        cli=cli,
                        expected_compiler_error=expected_error,
                    )
                )
            elif (
                (expected_error is None)
                and (expected_output is not None)
                and (program_stderr is not None)
            ):
                # Both outputs expected.  The program should
                # compile, FAIL, and print exactly this to stdout and this to
                # stderr.  It must not fall into the branch below, where
                # the stderr file would never be read.
                tests.append(
                    TestProgramFailure(
                        name=test_name,
                        suite_name=suite_name,
                        directory=test_dir,
                        cli=cli,
                        expected_program_stderr=program_stderr,
                        expected_program_stdout=expected_output,
                    )
                )
            elif (expected_error is None) and (expected_output is not None):
                # The program should compile, run successfully, produce stdout
                # that matches the contents of the file.
                tests.append(
                    TestSuccess(
                        name=test_name,
                        suite_name=suite_name,
                        directory=test_dir,
                        cli=cli,
                        expected_output=expected_output,
                        expected_exit=expected_exit or 0,
                    )
                )
            # There is neither an `hilde-stderr.txt` nor an `program-stdout.txt `file.
            else:
                if program_stderr is None:
                    # The program should compile and run successfully and produce no
                    # stdout.
                    tests.append(
                        TestSuccess(
                            name=test_name,
                            suite_name=suite_name,
                            directory=test_dir,
                            cli=cli,
                            expected_output=None,
                            expected_exit=expected_exit or 0,
                        )
                    )
                else:
                    # The program should compile successfully, return a failure
                    # exit code, and print stderr.
                    tests.append(
                        TestProgramFailure(
                            name=test_name,
                            suite_name=suite_name,
                            directory=test_dir,
                            cli=cli,
                            expected_program_stderr=program_stderr,
                        )
                    )
    return tests


def _get_exit_status(test_dir: str) -> int | None:
    """The exit status in program-exit.txt, a number from 0 to 255, or None
    when the file is not there."""
    text: str | None = _get_file_contents(test_dir, "program-exit.txt")
    if text is None:
        return None
    if not text.isdigit() or int(text) > 255:
        raise ValueError(f"{test_dir}: `program-exit.txt` must hold a number from 0 to 255.")
    return int(text)


def _get_file_contents(test_dir: str, filename: str) -> str | None:
    if os.path.isfile(os.path.join(test_dir, filename)):
        with open(os.path.join(test_dir, filename), "r") as stream:
            data: str = stream.read().strip()
            if not data:
                raise ValueError(f"`{filename}` exists, but it is empty.")
            return data
    else:
        return None


#
# Test Execution
#


def run_test(test: Test, replace_stderr: bool) -> TestResult | None:
    """Run one test in its own directory.

    The directory is made here and nowhere else, so an existing one is a
    leftover and not taken over.  It is removed when the test is over,
    however it ended, and a directory still there after the removal fails
    the test.
    """
    try:
        os.mkdir(test.work_dir)
        os.mkdir(test.run_dir)
    except OSError as e:
        return TestFail(
            test=test,
            hilde_cmd=None,
            cc_cmd=None,
            reason=f"could not make the test's directory {test.work_dir}: {e}",
            outputs=[],
        )
    try:
        result: TestResult = run_test_inner(test, replace_stderr)
    except Exception as e:
        print(e)
        result = None
    finally:
        shutil.rmtree(test.work_dir, ignore_errors=True)
    if os.path.lexists(test.work_dir):
        return TestFail(
            test=test,
            hilde_cmd=None,
            cc_cmd=None,
            reason=f"the test's directory {test.work_dir} is still there after its removal",
            outputs=[],
        )
    return result


def run_test_inner(test: Test, replace_stderr: bool) -> TestResult:
    if isinstance(test, TestSuccess):
        return _run_success_test(test)
    elif isinstance(test, TestFailure):
        return _run_failure_test(test, replace_stderr)
    elif isinstance(test, TestProgramFailure):
        return _run_program_failure_test(test)
    else:
        raise ValueError("Unknown test type.")


def _test_cmd(test: Test) -> list[str]:
    if test.cli:
        cli: str = test.cli
        cli: str = cli.replace("$DIR", test.directory)
        cli: str = cli.replace("$C_PATH", test.c_path)
        return cli.split(" ")
    else:
        body_path: str = os.path.join(test.directory, "Test.hiq")
        return [
            "./hilde",
            "compile",
            f"{body_path}",
            "--entrypoint=Test:main",
            "--target-type=c",
            f"--output={test.c_path}",
            "--error-format=hilde-json",
        ]


# The compiler writes the C libraries the program needs as the last line of
# the emitted C, `/* hilde link libraries: m */'.  One place knows
# (lib/CliEngine.ml writes the line, this reads it), so nothing has to be
# kept in step.
LINK_MANIFEST_PREFIX: str = "/* hilde link libraries:"


@functools.cache
def _library_flags(name: str) -> tuple[str, ...]:
    """The cc flags for one library of the manifest.

    A library pkg-config knows by the name the module gave it takes
    pkg-config's flags: on OpenBSD SQLite comes from ports and lives in
    /usr/local, which the base cc does not search, and pkg-config answers
    `-I/usr/local/include -L/usr/local/lib -lsqlite3'.  A name pkg-config
    does not know, or a system without pkg-config, gets `-l<name>' as before.
    Debian's sqlite3.pc answers `-lsqlite3', so the line there does not
    change.  lib/Util.ml (library_flags) applies the same rule for the
    compiler's own link; the two must not differ.

    A name pkg-config does not know is asked for as `lib<name>'
    too -- PCRE2's library is `-lpcre2-8' and its .pc `libpcre2-8', and on
    OpenBSD `-lpcre2-8' alone does not find /usr/local/lib.
    """
    plain: tuple[str, ...] = ("-l" + name,)
    for known in (name, "lib" + name):
        flags: tuple[str, ...] | None = _pkg_config_flags(known)
        if flags is not None:
            return flags
    return plain


def _pkg_config_flags(name: str) -> tuple[str, ...] | None:
    """pkg-config's flags for `name', or None when it does not answer."""
    try:
        known = subprocess.run(
            ["pkg-config", "--exists", name],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        ).returncode == 0
        if not known:
            return None
        answer = subprocess.run(
            ["pkg-config", "--cflags", "--libs", name],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        )
    except OSError:
        return None
    flags: tuple[str, ...] = tuple(answer.stdout.decode("utf-8").split())
    if answer.returncode != 0 or not flags:
        return None
    return flags


def _link_libraries(c_path: str) -> list[str]:
    """The link flags for the program in `c_path', read from its manifest."""
    try:
        with open(c_path) as stream:
            lines = stream.read().splitlines()
    except OSError:
        return []
    for line in reversed(lines):
        if line.startswith(LINK_MANIFEST_PREFIX):
            body: str = line[len(LINK_MANIFEST_PREFIX):]
            body = body.removesuffix("*/").strip()
            return [flag for name in body.split() for flag in _library_flags(name)]
    # No manifest: an older compiler, or a file this runner did not produce.
    # Saying so beats linking against a guess.
    raise ValueError(
        "no link manifest in " + c_path + " -- expected a line starting with "
        + repr(LINK_MANIFEST_PREFIX)
    )


def _extra_cflags() -> list[str]:
    """Flags the caller adds to every cc call, from HILDE_TEST_CFLAGS.

    It exists for one caller: the gate runs suite 031-arena a second time
    with -DHILDE_ARENA_PASSTHROUGH, which is the mode the arena requires and
    which is chosen at COMPILE time.  Split on whitespace, so a flag with a
    space in it cannot be passed -- none is needed and a quoting rule nobody
    can see is worse than a limit that is written down.
    """
    return os.environ.get("HILDE_TEST_CFLAGS", "").split()


# A test may carry `cflags.txt', compile
# switches of the prelude its program is built with -- one `-DNAME' per
# line, capitals, digits and `_' only.  The quarantine of the arena is a
# switch that is OFF in the default build, and its own suite
# (033-arena-quarantine) is built with it ON wherever it runs, so that every
# gate runs it.  Anything else on a line fails the test.
CFLAGS_FILE: str = "cflags.txt"
CFLAGS_LINE: re.Pattern = re.compile(r"^-D[A-Z][A-Z0-9_]*$")


def _test_cflags(test: "Test") -> tuple[list[str], str | None]:
    """The switches of the test's cflags.txt, or a reason it fails."""
    text: str | None = _get_file_contents(test.directory, CFLAGS_FILE)
    if text is None:
        return [], None
    flags: list[str] = []
    for line in text.splitlines():
        if CFLAGS_LINE.match(line) is None:
            return [], f"{CFLAGS_FILE}: a line is not -DNAME: {line!r}"
        flags.append(line)
    return flags, None


def _cc_cmd(c_path: str, bin_path: str, test_flags: list[str]) -> list[str]:
    # -fstack-clash-protection: a frame larger than a page touches every
    # page it spans, so it reaches the guard pages below a task's stack and
    # cannot step over them into other memory.
    return (
        ["cc", "-std=c17", "-Wall", "-Wextra", "-fstack-clash-protection"]
        + _extra_cflags()
        + test_flags
        + [c_path]
        + _link_libraries(c_path)
        + ["-o", bin_path]
    )


def _run_program(
    test: Test,
) -> tuple[subprocess.CompletedProcess | None, str | None]:
    """Run the test's binary in its working directory, `run' under the
    test's own directory, which run_test made and removes.

    Returns the finished process and a reason the test fails for, or None.
    """
    environment: dict[str, str] = dict(os.environ)
    environment[TREE_VARIABLE] = os.getcwd()
    environment[EMPTY_VARIABLE] = ""
    settings: str | None = _get_file_contents(test.directory, ENV_FILE)
    if settings is not None:
        for line in settings.splitlines():
            match: re.Match | None = ENV_LINE.match(line)
            if match is None:
                return None, f"{ENV_FILE}: a line is not NAME=VALUE: {line!r}"
            environment[match.group(1)] = match.group(2)
    server: str | None = _get_file_contents(test.directory, SERVER_FILE)
    if server is None:
        return _run_binary(test, environment), None
    kind: str = server.strip()
    if kind not in SERVER_KINDS:
        return None, f"{SERVER_FILE}: no server of the kind {kind!r}"
    name: str = f"{test.suite_name}_{test.name}"
    started: subprocess.CompletedProcess = subprocess.run(
        ["sh", SERVER_SCRIPT, "start", kind, name],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if started.returncode != 0:
        return None, (
            f"{SERVER_FILE}: the {kind} server did not start, exit"
            f" {started.returncode}: {started.stderr.decode(errors='replace').strip()}"
        )
    for line in started.stdout.decode().splitlines():
        match = ENV_LINE.match(line)
        if match is None:
            _stop_server(kind, name)
            return None, f"{SERVER_FILE}: the server script printed {line!r}"
        environment[match.group(1)] = match.group(2)
    try:
        result: subprocess.CompletedProcess = _run_binary(test, environment)
    finally:
        stopped: bool = _stop_server(kind, name)
    if not stopped:
        return None, f"{SERVER_FILE}: the {kind} server of the test was not removed"
    return result, None


def _stop_server(kind: str, name: str) -> bool:
    """Stop the server of a test; True when its directory is gone."""
    stopped: subprocess.CompletedProcess = subprocess.run(
        ["sh", SERVER_SCRIPT, "stop", kind, name],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return stopped.returncode == 0 and b"test-e-after-rm=1" in stopped.stderr


def _run_binary(
    test: Test, environment: dict[str, str]
) -> subprocess.CompletedProcess:
    """The test's binary, run in `run' with environment."""
    return subprocess.run(
        # Relative to `run', so that argv[0] is the same wherever the tree
        # lies (001-trivial/010-cli prints it); on POSIX a path with a slash
        # is found from the child's working directory.  HILDE_TEST_WRAPPER's
        # words go in front of it.
        os.environ.get(WRAPPER_VARIABLE, "").split()
        + [os.path.join("..", os.path.basename(test.bin_path))],
        cwd=test.run_dir,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def _make_work_base() -> None:
    """Make WORK_BASE, which must not exist yet."""
    if os.path.lexists(WORK_BASE):
        raise ValueError(
            f"{WORK_BASE} exists: an earlier run did not finish.  Look at it"
            " and remove it by hand; this runner removes only what it made."
        )
    os.mkdir(WORK_BASE)


def _remove_work_base() -> bool:
    """Remove WORK_BASE, which every test has emptied; True when it is gone."""
    try:
        os.rmdir(WORK_BASE)
    except OSError as e:
        print(f"{WORK_BASE} could not be removed: {e}")
    return not os.path.lexists(WORK_BASE)


def _how_it_ended(code: int) -> str:
    """The exit code of a programme that did not end with 0, or the name of
    the signal that ended it (subprocess gives a signal as a negative code)."""
    if code < 0:
        try:
            return f"signal {signal.Signals(-code).name}"
        except ValueError:
            return f"signal {-code}"
    return f"exit code {code}"


def _run_success_test(test: TestSuccess) -> TestResult:
    # Find the source files.
    expected_output = test.expected_output
    suite_name: str = test.suite_name
    test_name: str = test.name
    # Construct the compiler command.
    compile_cmd: list[str] = _test_cmd(test)
    # Call the compiler.
    result: subprocess.CompletedProcess = subprocess.run(
        compile_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    code: int = result.returncode
    if code != 0:
        # Compilation failed.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=None,
            reason="Hilde compilation failed, but was expected to succeed.",
            outputs=[
                ("HILDE STDOUT", result.stdout.decode("utf-8")),
                ("HILDE STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # The compiler executed successfully. Compile the program with cc.
    test_flags, flags_fault = _test_cflags(test)
    if flags_fault is not None:
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=None,
            reason=flags_fault,
            outputs=[],
        )
    cc_cmd: list[str] = _cc_cmd(test.c_path, test.bin_path, test_flags)
    # Call cc.
    result: subprocess.CompletedProcess = subprocess.run(
        cc_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    code: int = result.returncode
    if code != 0:
        # cc compilation failed.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="cc compilation failed, but was expected to succeed.",
            outputs=[
                ("cc STDOUT", result.stdout.decode("utf-8")),
                ("cc STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # cc compilation succeeded. Run the program.
    result, work_fault = _run_program(test)
    if work_fault is not None:
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason=work_fault,
            outputs=[],
        )
    code: int = result.returncode
    if code != test.expected_exit and test.expected_exit != 0:
        # The program ended, but not with the status program-exit.txt names.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason=f"Program ended with {_how_it_ended(code)}, expected exit code {test.expected_exit}.",
            outputs=[
                ("STDOUT", result.stdout.decode("utf-8")),
                ("STDERR", result.stderr.decode("utf-8")),
            ],
        )
    if code != test.expected_exit:
        # Program did not terminate successfully.  The exit code, or the
        # signal that ended it, is named: a programme built to trap on
        # undefined behaviour ends by a signal and prints nothing.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason=f"Program terminated abnormally ({_how_it_ended(code)}).",
            outputs=[
                ("STDOUT", result.stdout.decode("utf-8")),
                ("STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # Program ran successfully. Did it produce output?
    stdout: str = result.stdout.decode("utf-8").strip()
    if stdout and expected_output:
        # Have output, expected output. Check they match.
        if stdout == expected_output:
            # Output matches. Pass.
            return TestPass(test=test)
        else:
            # Output mismatch. Error.
            return TestFail(
                test=test,
                hilde_cmd=compile_cmd,
                cc_cmd=cc_cmd,
                reason="Program produced the wrong stdout.",
                outputs=[
                    ("ACTUAL STDOUT", stdout),
                    ("EXPECTED STDOUT", expected_output),
                ],
            )
    elif stdout and (not expected_output):
        # Have output, did not expect it. Error.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="Program produced stdout, which we did not expect.",
            outputs=[
                ("STDOUT", stdout),
            ],
        )
    elif (not stdout) and expected_output:
        # Don't have output, expected it. Error.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="Program did not produce stdout, but we expected it.",
            outputs=[
                ("EXPECTED OUTPUT", expected_output),
            ],
        )
    else:
        # Don't have output, didn't expect it. Pass.
        return TestPass(test=test)

    return TestPass(test=test)


def trim_lines(text):
    return "\n".join(
        [line if line.strip() else "" for line in text.strip().split("\n")]
    )


def _run_failure_test(test: TestFailure, replace_stderr: bool) -> TestResult:
    suite_name: str = test.suite_name
    test_name: str = test.name
    # Construct the compiler command.
    compile_cmd: list[str] = _test_cmd(test)
    # Call the compiler.
    result: subprocess.CompletedProcess = subprocess.run(
        compile_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    code: int = result.returncode
    if code == 0:
        # Compilation succeeded.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=None,
            reason="Hilde compiler succeeded, but was expected to fail.",
            outputs=[
                ("EXPECTED STDERR", test.expected_compiler_error),
            ],
        )
    # Compilation failed. Does the actual stderr match expected?
    if replace_stderr:
        # If replace_stderr is true, just take the actual stderr and overwrite the expected stderr.
        stderr: str = trim_lines(result.stderr.decode("utf-8"))
        with open(test.directory + "/hilde-stderr.txt", "w") as stream:
            # A text file of the repository ends in a line feed.
            stream.write(stderr + "\n")
    else:
        stderr: str = trim_lines(result.stderr.decode("utf-8"))
        if stderr != trim_lines(test.expected_compiler_error):
            return TestFail(
                test=test,
                hilde_cmd=compile_cmd,
                cc_cmd=None,
                reason="Hilde compiler failed, but compiler output does not match what we expected.",
                outputs=[
                    ("EXPECTED STDERR", test.expected_compiler_error),
                    ("ACTUAL STDERR", stderr),
                ],
            )
    # Compilation failed and output matches.
    return TestPass(test=test)


def _run_program_failure_test(test: TestProgramFailure) -> TestResult:
    # Find the source files.
    expected_stderr: str = test.expected_program_stderr
    suite_name: str = test.suite_name
    test_name: str = test.name
    # Construct the compiler command.
    compile_cmd: list[str] = _test_cmd(test)
    # Call the compiler.
    result: subprocess.CompletedProcess = subprocess.run(
        compile_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    code: int = result.returncode
    if code != 0:
        # Compilation failed: print the output.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=None,
            reason="Hilde compilation failed, but was expected to succeed.",
            outputs=[
                ("HILDE STDOUT", result.stdout.decode("utf-8")),
                ("HILDE STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # The compiler executed successfully. Compile the program with cc.
    test_flags, flags_fault = _test_cflags(test)
    if flags_fault is not None:
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=None,
            reason=flags_fault,
            outputs=[],
        )
    cc_cmd: list[str] = _cc_cmd(test.c_path, test.bin_path, test_flags)
    # Call cc.
    result: subprocess.CompletedProcess = subprocess.run(
        cc_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    code: int = result.returncode
    if code != 0:
        # cc compilation failed.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="cc compilation failed, but was expected to succeed.",
            outputs=[
                ("cc STDOUT", result.stdout.decode("utf-8")),
                ("cc STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # cc compilation succeeded. Run the program.
    result, work_fault = _run_program(test)
    if work_fault is not None:
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason=work_fault,
            outputs=[],
        )
    code: int = result.returncode
    if code == 0:
        # Program did terminated successfully, but we didn't want that.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="Program terminated successfully, but we expected a failure.",
            outputs=[
                ("STDOUT", result.stdout.decode("utf-8")),
                ("STDERR", result.stderr.decode("utf-8")),
            ],
        )
    # Did it produce output?
    stderr: str = result.stderr.decode("utf-8").strip()
    if not stderr:
        # Don't have output, expected it. Error.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="Program did not produce stderr, but we expected stderr",
            outputs=[
                ("EXPECTED STDERR", expected_stderr),
                ("ACTUAL STDOUT", result.stdout.decode("utf-8")),
            ],
        )
    if stderr != expected_stderr:
        # Output mismatch. Error.
        return TestFail(
            test=test,
            hilde_cmd=compile_cmd,
            cc_cmd=cc_cmd,
            reason="Program produced stderr, but it was not what we expected",
            outputs=[
                ("ACTUAL STDERR", stderr),
                ("EXPECTED STDERR", expected_stderr),
            ],
        )
    # When stdout is expected too, it must match as well.  An empty
    # stdout is compared like any other: it is the symptom this check exists
    # for (the output printed before a stop, lost in stdio's buffer).
    expected_stdout: str | None = test.expected_program_stdout
    if expected_stdout is not None:
        stdout: str = result.stdout.decode("utf-8").strip()
        if stdout != expected_stdout:
            return TestFail(
                test=test,
                hilde_cmd=compile_cmd,
                cc_cmd=cc_cmd,
                reason="Program failed with the expected stderr, but its stdout was not what we expected",
                outputs=[
                    ("ACTUAL STDOUT", stdout),
                    ("EXPECTED STDOUT", expected_stdout),
                    ("STDERR", stderr),
                ],
            )
    return TestPass(test=test)


#
# Test Runner
#


def filter_tests(
    tests: list[Test],
    suite_pattern: str | None,
    name_pattern: str | None,
) -> list[Test]:
    filtered: list[Test] = []
    for test in tests:
        if suite_pattern is not None:
            if test.suite_name.find(suite_pattern) == -1:
                continue

        if name_pattern is not None:
            if test.name.find(name_pattern) == -1:
                continue

        filtered.append(test)

    return filtered


def test_key(test: Test) -> str:
    return test.suite_name + "/" + test.name


def read_not_run(tests: list[Test]) -> dict[str, str]:
    """The tests the HILDE_TEST_NOT_RUN file names, each with its reason;
    empty when the variable is not set."""
    path: str | None = os.environ.get(NOT_RUN_VARIABLE)
    if not path:
        return {}
    try:
        with open(path) as stream:
            lines: list[str] = stream.read().splitlines()
    except OSError as e:
        raise ValueError(f"{NOT_RUN_VARIABLE}: {path} cannot be read: {e}")
    known: set[str] = {test_key(test) for test in tests}
    entries: dict[str, str] = {}
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.startswith("#"):
            continue
        key, _, reason = line.partition(" ")
        reason = reason.strip()
        if not reason:
            raise ValueError(f"{path}:{number}: no reason after {key!r}.")
        if key not in known:
            raise ValueError(f"{path}:{number}: {key!r} names no test of the collection.")
        if key in entries:
            raise ValueError(f"{path}:{number}: {key!r} is named twice.")
        entries[key] = reason
    return entries


def run_all_tests(
    tests: list[Test],
    suite_pattern: str | None,
    name_pattern: str | None,
    replace_stderr: bool,
    not_run: dict[str, str],
) -> list[TestResult]:
    """
    Run the given suites.

    If suite_pattern is given, only tests in suites containing the given string are considered.
    If name_pattern is given, only tests that have names containing the given string are run.
    An empty pattern means match all.  A test `not_run' names is reported
    with its reason and not run.
    """
    filtered: list[Test] = filter_tests(tests, suite_pattern, name_pattern)
    to_run: list[Test] = [t for t in filtered if test_key(t) not in not_run]
    left_out: list[TestResult] = [
        TestNotRun(test=t, reason=not_run[test_key(t)])
        for t in filtered
        if test_key(t) in not_run
    ]
    results: list[TestResult] = run_tests_parallel(to_run, replace_stderr) + left_out
    return sorted(results, key=lambda r: r.test.suite_name + "_" + r.test.name)


def run_tests_parallel(
    tests: list[Test],
    replace_stderr: bool,
) -> list[TestResult]:
    with ProcessPoolExecutor() as executor:
        futures: list[Future[TestResult | None]] = [
            executor.submit(run_test, test, replace_stderr)
            for test in tests
        ]
    results: list[TestResult] = [r for f in futures if (r := f.result()) is not None]
    assert len(results) == len(tests)

    return sorted(results, key=lambda r: r.test.suite_name + "_" + r.test.name)


#
# Entrypoint
#


def have_failures(l: list[TestResult]) -> bool:
    for result in results:
        if isinstance(result, TestFail):
            return True
    return False


if __name__ == "__main__":
    import sys

    replace_stderr: bool = "--replace-stderr" in sys.argv
    args: list[str] = [arg for arg in sys.argv if not arg.startswith("--")]
    suite_pattern: str | None = args[1] if len(args) > 1 else None
    name_pattern: str | None = args[2] if len(args) > 2 else None
    try:
        print("Collecting...")
        tests: list[Test] = collect_tests()
        not_run: dict[str, str] = read_not_run(tests)
        print("Running...")
        _make_work_base()
        try:
            results: list[TestResult] = run_all_tests(
                tests,
                suite_pattern,
                name_pattern,
                replace_stderr,
                not_run,
            )
        finally:
            work_base_gone: bool = _remove_work_base()
        report_test_results(results)
        if not work_base_gone:
            print(f"\n{WORK_BASE} is still there after the run")
            exit(-1)
        if have_failures(results):
            print("\nSome tests failed")
            exit(-1)
        else:
            print("\nAll tests passed")
            exit(0)
    except ValueError as e:
        print(e)
        exit(-1)
