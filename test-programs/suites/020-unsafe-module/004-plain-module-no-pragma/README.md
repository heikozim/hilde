The normal case, and the control for the whole suite: an ordinary module
with no pragma at all, using nothing but `Hilde.Pervasive`.  It must
compile and exit 0.

It is here because `Hilde.Pervasive` and `Hilde.Memory` now carry
`pragma Unsafe_Module;` themselves, and every module imports
`Hilde.Pervasive` implicitly.  This test holds the rule that the mark
sits on the module that embeds C and does not travel to the modules that
import it.  If it ever goes red, the rule has started to propagate.
