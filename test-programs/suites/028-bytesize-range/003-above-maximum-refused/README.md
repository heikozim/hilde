One past the largest 64-bit size_t.  Without this the fix would be
indistinguishable from removing the check: the bound moved, it did not go.
