Two modules declare the same instance for a type that belongs to
neither of them.  Test_TC owns the typeclass and instantiates it for
Bool; Test imports the typeclass and instantiates it for Bool as well.
Only the program-wide uniqueness check can see this: neither module
has two instances of its own.
