# The libargon2 functions Bindings.Argon2 calls, read from
# the copy in fixtures/ (scripts/argon2/check-header.sh holds it against the
# real argon2.h).  Only Bindings.Argon2 should import the generated module.
module     Bindings.C.Argon2
header     fixtures/argon2.h
output     generated/Argon2
# The library's file name; pkg-config knows it as libargon2 on Debian, and
# the compiler and the runner ask for that too.
library    argon2
opaque     argon2_context
# Bindings.Argon2 sets the fields of argon2_context by name, as the header of
# the machine that compiles the program lays them out, so that header is
# included and no offset is written down here.
system-header argon2.h
function   argon2id_hash_raw
function   argon2id_ctx
