<!-- Modified by Heiko Zimmermann for Hilde, 2026. -->
# Test Programs

End-to-end tests of the compiler.

The file hierarchy is:

```
test-programs/
    suites/
        XXX-suite/      # Represents a test suite
            YYY-test/      # Represents a test
                Test.hih   # Module interface
                Test.hiq   # Module body
                output.txt # Expected program output, if the program is meant to compile.
                error.txt  # Expected compiler output, if the program is meant to compile.
```

The `suites` directory has numbered subdirectories, each representing a test suite: a collection of tests covering specific compiler features.

Each test directory contains some Hilde source files (in the simplest cases, `Test.hih` and `Test.hiq`) and some control files:

1. `hilde-stderr.txt` is the compiler's error message if the test is expected to fail.

2. `program-stdout.txt` is the compiled program's stdout if the compiler is expected to succeed and the program is expected to produce stdout and return normally.

3. `program-stderr.txt` alone is the compiled program's stderr if the program is expected to FAIL: the run must end with a failure exit code and stderr must match; stdout is not looked at.

4. `program-stdout.txt` and `program-stderr.txt` together: the program must fail, and BOTH outputs must match -- what it printed before it stopped, and why it stopped.

5. If none of these files is present, the test is expected to compile and run successfully but produce no output.

6. `env.txt`, beside any of the above: one `NAME=VALUE` per line, set in the program's environment when it runs.  A name is capitals, digits and `_`; a value is printable ASCII; any other line fails the test.  The task tests use it for `HILDE_TASK_THREADS`: 1 where the test asserts the order of one thread, a larger number where it must run on several whatever the machine.

7. `cflags.txt`, beside any of the above: one `-DNAME` per line, compile switches the program is built with -- capitals, digits and `_` only; any other line fails the test.  The arena quarantine is a switch that is off by default; its suite, `033-arena-quarantine`, is built with it on wherever it runs.

8. `program-exit.txt`, beside `program-stdout.txt` or alone: the exit status, a number from 0 to 255, with which the program must end; without the file it is 0.  Beside `hilde-stderr.txt` or `program-stderr.txt` it fails the collection.  Suite `099-exit-status` uses it for `ExitStatus`.

Suite and test directories are numbered so that tests run in a predictable order.

The `runner.py` script runs the tests.

Four variables of the environment change what it does:

1. `HILDE_TEST_CFLAGS`: words added to every C compiler call -- the checks build the suites with sanitizers or with a switch of the runtime this way.

2. `HILDE_TEST_WRAPPER`: words put in front of every test programme's command -- valgrind and its options.

3. `HILDE_TEST_SUITES`: the directory the suites are read from instead of `suites`.  `controls/` holds programmes with a fault on purpose -- a read past a buffer, a lost buffer, a misaligned load -- beside a clean one; each instrument of the checks must fail exactly the faults it is there to see, so they are kept out of the ordinary run.

4. `HILDE_TEST_NOT_RUN`: a file naming tests that are not run, one per line, `<suite>/<test> <reason>`.  Each is printed `NOT RUN` with its reason.  A line without a reason, a name that names no test and a test named twice end the run.  `not-run-memory.txt` and `not-run-valgrind.txt` are the lists of the gates' runs under the sanitizers and under valgrind.
