The compiler's own command line, where it refused with an exception or
with the wrong code before.

101: an output file whose directory does not exist is refused with
H1015; the compiler stopped with an uncaught exception.

102: `--no-entrypoint` without `--target-type=c` is refused with H1006;
the flag was looked up under a name the argument list does not keep, and
the compiler said H1003, the missing `--entrypoint`.

103 to 105: a source file that cannot be read is refused with H1034,
with the path and the message of the system: 103 a missing file given
to compile, 104 a directory given as one, which opens and then fails to
read, 105 a missing file given to check.  The compiler stopped with an
uncaught Sys_error of OCaml.

106: `hilde check --fix` over a module with an operator that has no
precedence leaves the error's hint alone.  The hint is not marked as the
one fix, so nothing is written and the check reports the error as it does
without the flag; the test fails to check, which it would not if the hint
had been written into the file.

107: `hilde check` refuses a borrow handed to a task with H3002, as
compile does.  The check is made by the monomorphiser, which check did
not run, so check passed a module that compile refused.

The case the flag is for, `--no-entrypoint` with `--target-type=c`, and
the values of `--target-type` the help names, are held by the unit tests
of the command line, `test/CliParserTest.ml`: a programme without an
entrypoint compiles, but a test here would also have to link and run it.
