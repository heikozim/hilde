/*
** The part of PCRE2's pcre2.h that Standard.Pcre binds, for code units of
** 8 bits.
**
** pcre2.h does not write these declarations out: it defines each group once
** as a macro (PCRE2_COMPILE_FUNCTIONS, ...) and expands it for every code
** unit width, renaming every name with PCRE2_SUFFIX -- pcre2_compile
** becomes pcre2_compile_8, pcre2_code becomes pcre2_code_8.  So the
** lines below are those macros expanded for width 8, with PCRE2_EXP_DECL
** and PCRE2_CALL_CONVENTION (both empty on these platforms) left out and
** PCRE2_SPTR8, PCRE2_UCHAR8 and PCRE2_SIZE written as the types they are.
** The header lines each one comes from are named, from pcre2.h of PCRE2
** 10.46 (Debian libpcre2-dev 10.46-1~deb13u2); the lines of the JIT and of
** pcre2_config are named from pcre2.h of PCRE2 10.45, the release the gate
** image builds, whose header the check now holds the whole copy against.
** PCRE2 is Copyright the
** University of Cambridge and Philip Hazel and licensed under the BSD
** licence; these are its declarations, quoted for the binding generator.
**
** Why a copy: the checks of this repository read no file of the machine
** they run on.  scripts/pcre/check-header.sh compiles this file together
** with the real pcre2.h (PCRE2_CODE_UNIT_WIDTH 8), and C accepts a
** declaration, a typedef or a macro twice only when both say the same -- a
** const left out of a parameter here would stop it.
*/
#include <stddef.h>
#include <stdint.h>

/* pcre2.h lines 515, 519 */
typedef uint8_t  PCRE2_UCHAR8;
typedef const PCRE2_UCHAR8  *PCRE2_SPTR8;

/* pcre2.h lines 536-553 (PCRE2_TYPES_LIST, width 8) */
typedef struct pcre2_real_general_context_8 pcre2_general_context_8;
typedef struct pcre2_real_compile_context_8 pcre2_compile_context_8;
typedef struct pcre2_real_match_context_8 pcre2_match_context_8;
typedef struct pcre2_real_code_8 pcre2_code_8;
typedef struct pcre2_real_match_data_8 pcre2_match_data_8;

/* pcre2.h 10.45 line 556 (PCRE2_TYPES_LIST, width 8) */
typedef struct pcre2_real_jit_stack_8 pcre2_jit_stack_8;

/* pcre2.h lines 349, 410, 443 -- the same in every width, so not renamed */
#define PCRE2_ERROR_NOMATCH          (-1)
#define PCRE2_ERROR_MATCHLIMIT        (-47)
#define PCRE2_INFO_CAPTURECOUNT          4

/* pcre2.h 10.45 lines 170, 409, 471 */
#define PCRE2_JIT_COMPLETE        0x00000001u
#define PCRE2_ERROR_JIT_STACKLIMIT    (-46)
#define PCRE2_CONFIG_JIT                     1

/* pcre2.h 10.45 line 482 */
#define PCRE2_CONFIG_VERSION                11

/* pcre2.h 10.45 line 625 (PCRE2_GENERAL_INFO_FUNCTIONS, width 8) */
int pcre2_config_8(uint32_t what, void *where);

/* pcre2.h 10.45 lines 837-849 (PCRE2_JIT_FUNCTIONS, width 8); the
   callback of line 847 is the type pcre2_jit_callback_8 of line 558,
   written out */
int pcre2_jit_compile_8(pcre2_code_8 *code, uint32_t options);
pcre2_jit_stack_8 *pcre2_jit_stack_create_8(size_t startsize,
    size_t maxsize, pcre2_general_context_8 *gcontext);
void pcre2_jit_stack_assign_8(pcre2_match_context_8 *mcontext,
    pcre2_jit_stack_8 *(*callback)(void *), void *callback_data);
void pcre2_jit_stack_free_8(pcre2_jit_stack_8 *jit_stack);

/* pcre2.h lines 716-721 */
pcre2_code_8 *pcre2_compile_8(const uint8_t *pattern, size_t length,
    uint32_t options, int *errorcode, size_t *erroroffset,
    pcre2_compile_context_8 *ccontext);
void pcre2_code_free_8(pcre2_code_8 *code);

/* pcre2.h lines 730-732 */
int pcre2_pattern_info_8(const pcre2_code_8 *code, uint32_t what, void *where);

/* pcre2.h lines 740-745 */
pcre2_match_data_8 *pcre2_match_data_create_from_pattern_8(
    const pcre2_code_8 *code, pcre2_general_context_8 *gcontext);

/* pcre2.h lines 749-753 */
int pcre2_match_8(const pcre2_code_8 *code, const uint8_t *subject,
    size_t length, size_t startoffset, uint32_t options,
    pcre2_match_data_8 *match_data, pcre2_match_context_8 *mcontext);
void pcre2_match_data_free_8(pcre2_match_data_8 *match_data);

/* pcre2.h lines 762-763 */
size_t *pcre2_get_ovector_pointer_8(pcre2_match_data_8 *match_data);

/* pcre2.h lines 669-675 */
pcre2_match_context_8 *pcre2_match_context_create_8(
    pcre2_general_context_8 *gcontext);
void pcre2_match_context_free_8(pcre2_match_context_8 *mcontext);

/* pcre2.h lines 689-690 */
int pcre2_set_heap_limit_8(pcre2_match_context_8 *mcontext, uint32_t value);

/* pcre2.h lines 691-692 */
int pcre2_set_match_limit_8(pcre2_match_context_8 *mcontext, uint32_t value);

/* pcre2.h lines 855-856 */
int pcre2_get_error_message_8(int errorcode, uint8_t *buffer, size_t bufflen);
