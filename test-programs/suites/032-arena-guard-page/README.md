The guard page of the arena, in a suite of its own.

It is not in 031-arena because the gate runs that suite a second
time with -DHILDE_ARENA_PASSTHROUGH, and pass-through mode has
no guard page by construction: every allocation is a separate
calloc, and what protects it is the system allocator, not a page
this code maps: the same programme exits 0 in pass-through mode
instead of faulting.
