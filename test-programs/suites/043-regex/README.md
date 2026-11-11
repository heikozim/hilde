# 043-regex

`Standard.Regex`.

001 is generated from the table in `scripts/regex/cases.py`, and its
expected output is Go's `regexp` on the same table
(`scripts/regex/oracle.go`): every line that differs is a place where this
engine and RE2's semantics part.  002 is generated from the second table
there, the deliberate deviations, and its expected output is this engine's
own, reviewed.  003 and 005 are written by hand.  004 is generated as
well: every pattern of 001 and 002 and a list of edges, with the module's
answer for each; `test/RegexCheckTest.ml` holds the compiler's check of
literal patterns against it.

006 and 007 are written by hand, and say what several tasks can do with
a compiled pattern: in 006 two
tasks each compile their OWN `Regex`, search, yield and search again,
taking turns; in 007 one `Regex` is lent to a task, with the scope opened
and closed inside the borrow, and the programme does not compile (H3002).

008 is 007 with a lending scope: the one `Regex` is
lent to two tasks at once, each searches, yields and searches again, and
they take turns as in 006 -- one compiled pattern used by several tasks
without a lock.

009 is 008 on eight workers and without a yield: the one `Regex` is searched by eight tasks at the same time, on different threads, 500 rounds each -- what 008 on one thread could not show; the checks run it under ThreadSanitizer.  006 and 008 assert the order of one thread and name HILDE_TASK_THREADS=1 in an env.txt.

The Unicode classes (`\p`, `\P`) and the case folding beyond ASCII are
cases of 001, held to Go, and no deviations; 002
holds the property names that are none, and 004 every name the module
takes, so that the compiler's check and the module keep one list.

010: groupStart and groupEnd for a group the pattern does not have, the largest Index among them, answer None; 011: a pattern whose capture table of one search would pass 16,777,216 entries is refused by compile.

012: an anchored pattern with a literal after its start, 50 searches on 4 MiB without the literal, under a second; the required literal is not looked for when the pattern is anchored.
