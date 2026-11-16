An instance that does not implement every method of its typeclass is refused
where it is written, and the message names the methods that are missing.

Austral does not check this direction: its extraction pass checks only that
every method GIVEN exists in the typeclass.  A missing method surfaces at
monomorphisation, as "Internal compiler error: Couldn't find instance
method ... This is a bug in the compiler", and only if something calls it.
