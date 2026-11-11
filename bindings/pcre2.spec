# The PCRE2 functions Standard.Pcre calls, for code units
# of 8 bits, read from the copy in fixtures/ (scripts/pcre/check-header.sh
# holds that copy against the real pcre2.h).  Only Standard.Pcre should
# import the generated module.
module     Bindings.C.Pcre2
header     fixtures/pcre2.h
output     generated/Pcre2
# The library's file name.  pkg-config calls it libpcre2-8; the compiler and
# the runner ask for that name too when they do not know this one.
library    pcre2-8
opaque     pcre2_general_context_8
opaque     pcre2_compile_context_8
opaque     pcre2_match_context_8
opaque     pcre2_code_8
opaque     pcre2_match_data_8
opaque     pcre2_jit_stack_8
# The callback of pcre2_jit_stack_assign_8 is always null here: the stack
# is handed over as its data.
callbacks  address
# The same numbers in every PCRE2 width and version this binding meets;
# check-header.sh holds each against the real header on each platform.
constant   PCRE2_ERROR_NOMATCH Int32
constant   PCRE2_ERROR_MATCHLIMIT Int32
constant   PCRE2_INFO_CAPTURECOUNT Nat32
# The JIT, which Standard.PcreJit asks for.
constant   PCRE2_JIT_COMPLETE Nat32
constant   PCRE2_ERROR_JIT_STACKLIMIT Int32
constant   PCRE2_CONFIG_JIT Nat32
constant   PCRE2_CONFIG_VERSION Nat32
function   pcre2_config_8
function   pcre2_jit_compile_8
function   pcre2_jit_stack_create_8
function   pcre2_jit_stack_assign_8
function   pcre2_jit_stack_free_8
function   pcre2_compile_8
function   pcre2_code_free_8
function   pcre2_pattern_info_8
function   pcre2_match_data_create_from_pattern_8
function   pcre2_match_8
function   pcre2_match_data_free_8
function   pcre2_get_ovector_pointer_8
function   pcre2_match_context_create_8
function   pcre2_match_context_free_8
function   pcre2_set_match_limit_8
# A heap limit for the interpreter: the
# interpreter's memory for one search is bounded by Standard.Pcre, not by
# what the host lets a process have.
function   pcre2_set_heap_limit_8
function   pcre2_get_error_message_8
