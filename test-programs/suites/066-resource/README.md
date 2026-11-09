# 066-resource

`Standard.Resource`: the limits of the process as the
kernel enforces them.  Reading, lowering and raising the limits, the usage
and the uptime are the library's own test (`standard/src/Resource.test.hiq`);
here a limit is measured at its effect.

- 001: the soft limit of open files lowered to 10 refuses a descriptor
  before ten are open, and raised again lets fifty more be opened.  The
  counts depend on the descriptors the process holds at its start, so the
  test prints what must hold.
