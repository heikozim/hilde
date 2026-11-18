# 063-log

`Standard.Log`: logs written to files and to standard
error.  The lines' form at a fixed time is the library's own test
(`standard/src/Log.test.hiq`); here the time is the wall clock's, so each
test checks the time's form and prints the rest of the line.

- 001: a file at the level Info, a Debug entry dropped, two lines with
  fields.
- 002: the file removed under the log, as a rotation renames it away, and
  `reopenLog` opening the path again; then a reopen whose directory is
  gone, which says false while the log keeps writing into its old file.
- 003: a file in JSON lines, an escaped quotation mark.
- 004: `writeErrorText` after bytes written one at a time, and a log to
  standard error that drops an entry below its level.

Every file a test makes is removed by the test.
