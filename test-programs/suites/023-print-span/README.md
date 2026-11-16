# 023-print-span

`printSpan` is the method of `Printable` that `print` reaches when it is
given a Span.  In Austral thirteen of the fourteen instances of it in the
Pervasive module were `return nil;` -- a declared method that printed
nothing -- and `instance Printable(Unit)` had no `printSpan` at all, which
was not a silent hole but an internal compiler error at the call site.
Both are fixed in `lib/builtin/Pervasive.hiq`.

001 prints a span with known contents, so a `printSpan` that went back to
doing nothing would fail the test rather than quietly print less.

002 is the compiler check that the second half of that defect needed: an
instance that leaves out a method of its typeclass is refused where it is
written, instead of crashing the compiler later and only if something calls
the missing method.
