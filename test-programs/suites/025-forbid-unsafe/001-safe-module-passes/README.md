A safe program compiled WITH --forbid-unsafe-modules.  It has to build and
run, although Hilde.Pervasive -- which it imports implicitly, as every module
does -- carries pragma Unsafe_Module; itself.  That is the exemption by
origin, and this case is what would fail if it were ever lost.
