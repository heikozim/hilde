ignore() may not become a way around linearity.  Its type parameter is
constrained to the Free universe, so a linear value cannot be passed to
it at all -- and the refusal comes from the universe machinery, not
from a check written for this function.
