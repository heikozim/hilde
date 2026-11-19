# 070-shared

`Standard.Shared`: a mutex that guards a value and an atomic word, shared by
the tasks of a lending scope.

- 001: eight tasks on eight workers, each 5000 rounds of adding one under the
  mutex and one to the atomic word; both end at 40000, and the mutex is not
  held at the end.  The gate runs the suite under ThreadSanitizer as well.
  Its control, a runtime whose mutex never waits, lost updates (36880) and
  gave two reports of ThreadSanitizer.
- 002: main holds the mutex and acquires it again; the runtime ends the
  programme with the deadlock message instead of hanging.
- 003: the key of one mutex given back to another stops the programme.
- 004: a key that is never given back does not compile (H4012).
