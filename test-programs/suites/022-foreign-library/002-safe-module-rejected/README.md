A safe module cannot name a C library: it can hold neither a foreign import
nor an @embed, so it has no C to link against.
