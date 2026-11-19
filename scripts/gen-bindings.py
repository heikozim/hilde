#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
"""Produce Hilde foreign-import declarations from a C header.

    python3 scripts/gen-bindings.py <spec>            write the module
    python3 scripts/gen-bindings.py --check <spec>    write nothing, compare

A SPEC says what to take, because a header does not.  A header is thousands
of declarations and no statement about which of them belong together; a
generator that emitted all of it would produce something nobody can read and
nobody can review.  The spec is line-based, `#` starts a comment:

    module   Example.Libm          the Hilde module to write
    header   fixtures/libm.h       the C header to read, relative to the spec
    library  m                     pragma Foreign_Library, may repeat
    output   generated/Libm        `.hih' and `.hiq' are appended
    function sqrt                  take this function
    preprocess yes                 run the header through `cc -E -P' first
    flags    Rounding Nat32 FE_    every #define with this prefix, as a TYPE
    constant SQLITE_OK Int32       one #define, typed as the functions use it
    opaque   sqlite3               a struct the header only points at
    handle   Diag Diag             a pointer the caller owns, as a linear
                                   type of its own with one function
                                   that frees the object
    struct   DiplomatStringView D  a struct the header passes by value,
                                   as a record with the fields in the
                                   order of the header
    requires diag_write out_len > 0
                                   the precondition the header states,
                                   over the parameter names of one
                                   function, as the caller's duty
    ctype    sqlite3_int64 Int64   a typedef name, and the Hilde type it is
    callbacks address              a function-pointer parameter is an Address
    system-header openssl/evp.h    pragma Foreign_Header, may repeat
    system-constant NID_X25519 Int32
                                   a #define whose VALUE the C compiler
                                   takes from the system header

`flags` is the reason the tool exists at all rather than a sed script.  The
order says constants and flags must arrive as TYPES OF THEIR OWN and not as
raw integers, so a group of `#define`s becomes a Hilde record with one field
and one constant per name, and the integers are inside it where nothing can
add them to a length by accident.

The last four came with the first real header the tool was pointed at for
a binding that is used.  `constant' is for a code a function RETURNS as an
int and a caller compares -- a result code is not a flag, nothing combines
it, and giving it the function's own type is what lets the comparison be
written at all.  `opaque' and `ctype' are statements a person makes about
the header and can be read back; `callbacks address' is one about the
platform: a function pointer and a data pointer are passed alike on every
platform Hilde supports, and the only callback SQLite needs here is a
constant.

`handle' came with the first Diplomat-style header.  A handle is a pointer
the caller owns: the value stands for one C object, one function of the
spec frees it -- named after the C type, `Diag_destroy', `Diag_free' or
`Diag_close' -- and the type is linear, so the compiler holds that nothing
uses a value after that function has run.  When no function of the spec
follows a convention, the spec names the one that frees it as the fourth
word, `handle DiplomatWrite DiplomatWrite diplomat_free_write'.  A spec
with a handle binds for a safe layer: the pointer parameters of its
functions are Pointer, the type a caller can only hold after a check, so
the safe layer hands a live buffer over.  A spec without one binds raw,
and its pointers stay Address.  The compiler refuses a contract on a
foreign function -- a contract is checked by statements in a body, and a
foreign function has none -- so a contract stands on a function of the
module's own.  A `requires' line is what makes the tool write one: the
raw import keeps the C name with `_raw' behind it, and the function of
the module's own carries the requires the header states, in the words of
the header, and the compiler holds every caller to it.  A function the
tool wraps for no contract of its own -- a make, a free, a call that
hands a handle over and takes it back -- carries a note that names the
reason no contract holds: the value it gives back has no property but
its type, it only frees or closes what it is given, or the work is the
work of C behind the pointer.  The handle needs
the safe layer, since a raw pointer and a linear object are nothing a
caller of a programme should hold.

`struct' and `requires' came with the rest of the Diplomat patterns.  A
slice is a struct by value, `DiplomatStringView' with a pointer to the
bytes and a size_t for their length, and a result is a struct with the
value, the error code and a bool that says which one is live.  A struct
of the spec becomes a record with the fields in the order of the header,
each named in snake_case; a field that is itself a struct, an array or a
union stops the tool.  The result struct of a bridge is written flat --
value, error, flag -- so a caller of any language reads it without a
union; that is the shape the bridge crate of this repository emits, and
the reason no union is parsed here.

`system-constant' came with the first OpenBSD run of Standard.Libcrypto:
OpenSSL numbers X25519 1034, LibreSSL 950, and a value copied into the
binding is right on one platform only.  Such a constant has NO
value here -- the binding writes `@embed(Int32, "NAME")', the module names
the header with `pragma Foreign_Header', and the C compiler of the machine
that builds the program reads the number from that machine's header.  The
fixture need not carry the #define, and a `system-constant' without a
`system-header' stops the tool.

Exit 0 when it wrote (or, under --check, when nothing would change), 1 when
--check found a difference, 9 when it could not run.  A C type this tool does
not know STOPS it; nothing is guessed.
"""
import os
import re
import sys

# The only C types a binding may mention.  Everything else stops the tool:
# a wrong guess here is a call with the wrong ABI, which no test catches
# because it compiles.
C_TO_HILDE = {
    "void": "Unit",
    "int": "Int32",
    "unsigned int": "Nat32",
    "unsigned": "Nat32",
    "long": "Int64",
    "unsigned long": "Nat64",
    "long long": "Int64",
    "unsigned long long": "Nat64",
    "bool": "Bool",
    "_Bool": "Bool",
    "float": "Float32",
    "double": "Float64",
    "size_t": "Index",
    "ssize_t": "Int64",
    # The names a real POSIX header uses.  Every one of them is a
    # 64-bit integer on every platform Hilde supports; on a 32-bit
    # target this table is wrong, and that is why the platforms Hilde
    # supports are stated rather than left to be assumed.
    "off_t": "Int64",
    "__off_t": "Int64",
    "off64_t": "Int64",
    "__off64_t": "Int64",
    "pid_t": "Int32",
    "__pid_t": "Int32",
    "mode_t": "Nat32",
    "__mode_t": "Nat32",
    "int8_t": "Int8",
    "int16_t": "Int16",
    "int32_t": "Int32",
    "int64_t": "Int64",
    "uint8_t": "Nat8",
    "uint16_t": "Nat16",
    "uint32_t": "Nat32",
    "uint64_t": "Nat64",
    "void *": "Address[Unit]",
    "void*": "Address[Unit]",
}

# `char' is a byte ONLY behind a pointer.  As a value its
# signedness is the platform's -- signed on x86-64, unsigned on aarch64 --
# and a parameter of that type would be extended differently on the two, so
# it stops the tool there like any other unknown type.
POINTEE_ONLY = {
    "char": "Nat8",
    "unsigned char": "Nat8",
    "signed char": "Int8",
}

# A function-pointer parameter: `void(*)(void*)', `int (*cb)(void*, int)'.
FUNCTION_POINTER = re.compile(r"^[A-Za-z_][A-Za-z0-9_ \*]*\(\s*\*\s*[A-Za-z_0-9]*\s*\)\s*\(.*\)$")

DEFINE = re.compile(r"^\s*#\s*define\s+([A-Za-z_][A-Za-z0-9_]*)\s+(.+?)\s*$")
# An optional minus, as PCRE2 writes its result codes: `(-1)'.
INTEGER = re.compile(r"^\(*\s*(-?)\s*(0[xX][0-9a-fA-F]+|[0-9]+)\s*[uUlL]*\s*\)*$")



def close_without_blank(parts, closing):
    """Append the end of a module, the blank line before it taken away: hilde
    fmt writes none before an end."""
    while parts and parts[-1].endswith("\n\n"):
        parts[-1] = parts[-1][:-1]
    parts.append(closing)

def die(message):
    print("ABORT: " + message, file=sys.stderr)
    sys.exit(9)


def read_spec(path):
    spec = {"library": [], "function": [], "flags": [], "preprocess": False,
            "constant": [], "opaque": [], "handle": {}, "ctype": {},
            "callbacks": False, "system-header": [], "system-constant": [],
            "struct": {}, "requires": [], "handle-free": {}}
    with open(path) as stream:
        for number, line in enumerate(stream, 1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            key = parts[0]
            if key in ("module", "header", "output"):
                if len(parts) != 2:
                    die("%s:%d: `%s' takes one word" % (path, number, key))
                spec[key] = parts[1]
            elif key == "preprocess":
                if len(parts) != 2 or parts[1] not in ("yes", "no"):
                    die("%s:%d: `preprocess' takes yes or no" % (path, number))
                spec["preprocess"] = (parts[1] == "yes")
            elif key in ("library", "function", "system-header"):
                if len(parts) != 2:
                    die("%s:%d: `%s' takes one word" % (path, number, key))
                spec[key].append(parts[1])
            elif key == "constant":
                if len(parts) != 3:
                    die("%s:%d: `constant' takes a name and a Hilde type" % (path, number))
                spec["constant"].append((parts[1], parts[2]))
            elif key == "system-constant":
                if len(parts) != 3:
                    die("%s:%d: `system-constant' takes a name and a Hilde type" % (path, number))
                spec["system-constant"].append((parts[1], parts[2]))
            elif key == "opaque":
                if len(parts) != 2:
                    die("%s:%d: `opaque' takes one C name" % (path, number))
                spec["opaque"].append(parts[1])
            elif key == "handle":
                if len(parts) not in (3, 4):
                    die("%s:%d: `handle' takes a C name, the Hilde type it "
                        "is, and, when no name of the conventions frees it, "
                        "the one function that does" % (path, number))
                if not re.fullmatch(r"[A-Z][A-Za-z0-9_]*", parts[2]):
                    die("%s:%d: the Hilde type of a handle is a name of its "
                        "own, like Diag" % (path, number))
                spec["handle"][parts[1]] = parts[2]
                if len(parts) == 4:
                    spec["handle-free"][parts[1]] = parts[3]
            elif key == "struct":
                if len(parts) != 3:
                    die("%s:%d: `struct' takes a C name and the Hilde type it is"
                        % (path, number))
                if not re.fullmatch(r"[A-Z][A-Za-z0-9_]*", parts[2]):
                    die("%s:%d: the Hilde type of a struct is a name of its "
                        "own, like DiplomatStringView" % (path, number))
                spec["struct"][parts[1]] = parts[2]
            elif key == "requires":
                if len(parts) < 3:
                    die("%s:%d: `requires' takes a function and the condition "
                        "over its parameters, like diag_write out_len > 0"
                        % (path, number))
                spec["requires"].append((parts[1], " ".join(parts[2:])))
            elif key == "ctype":
                if len(parts) != 3:
                    die("%s:%d: `ctype' takes a C name and a Hilde type" % (path, number))
                spec["ctype"][parts[1]] = parts[2]
            elif key == "callbacks":
                if len(parts) != 2 or parts[1] != "address":
                    die("%s:%d: `callbacks' takes the word address" % (path, number))
                spec["callbacks"] = True
            elif key == "flags":
                if len(parts) != 4:
                    die("%s:%d: `flags' takes a type name, a width and a prefix"
                        % (path, number))
                spec["flags"].append((parts[1], parts[2], parts[3]))
            else:
                die("%s:%d: unknown word `%s'" % (path, number, key))
    for key in ("module", "header", "output"):
        if key not in spec:
            die("%s: no `%s' line" % (path, key))
    if spec["system-constant"] and not spec["system-header"]:
        die("%s: a `system-constant' needs a `system-header' to come from" % path)
    return spec


def normalise(text):
    return " ".join(text.replace("*", " * ").split())


# The spec's own words about the header -- `opaque', `handle', `struct',
# `ctype', `callbacks' -- are read by hilde_type; build() sets them before
# the first call.
SPEC_WORDS = {"opaque": [], "handle": {}, "struct": {}, "ctype": {},
              "callbacks": False}


# A spec with a handle binds for a safe layer, so the pointers its
# functions take are checked ones; a spec without one binds raw.
def pointer_wrap():
    return "Pointer" if SPEC_WORDS["handle"] else "Address"


# The marker of a borrowed handle: `const Diag *', the pointer a read-only
# method of a Diplomat bridge takes, stands for the object without owning
# it.  The type is written `&[Diag]' here and gets its region letter when
# the function is wrapped.
BORROWED = "&["


def borrowed_handle(c_type):
    """The handle name of a `const <Handle> *', else None."""
    text = normalise(c_type)
    if not text.endswith(" *"):
        return None
    base = text[:-2].strip()
    if not base.startswith("const "):
        return None
    inner = base[len("const "):].strip()
    return SPEC_WORDS["handle"].get(inner)


def hilde_type(c_type, where):
    raw = c_type.strip()
    for word in ("const ", "extern ", "static ", "inline ", "register "):
        raw = raw.replace(word, "")
    if FUNCTION_POINTER.match(raw.strip()):
        if SPEC_WORDS["callbacks"]:
            return "Address[Unit]"
        die("%s: `%s' is a function pointer, and the spec has no `callbacks address'"
            % (where, normalise(raw)))
    borrowed = borrowed_handle(c_type)
    if borrowed is not None:
        # A read through the object: the caller keeps the value, so the
        # wrapper takes a reference and C gets the pointer it holds.
        return BORROWED + borrowed + "]"
    c_type = normalise(c_type)
    c_type = c_type.replace("const ", "")
    # A storage class says nothing about the ABI, and a real header
    # writes one on every declaration.
    for word in ("extern ", "static ", "inline ", "register "):
        c_type = c_type.replace(word, "")
    c_type = normalise(c_type)
    if c_type.endswith(" *") or c_type == "*":
        base = c_type[:-2].strip()
        if base == "void":
            return "Address[Unit]"
        if base in SPEC_WORDS["handle"]:
            # The handle itself: the value owns the object, and one
            # function of the spec frees it.
            return SPEC_WORDS["handle"][base]
        if base in SPEC_WORDS["opaque"]:
            return "Address[Unit]"
        if base in POINTEE_ONLY:
            return "%s[%s]" % (pointer_wrap(), POINTEE_ONLY[base])
        # A pointer to a pointer: `sqlite3 **' is an Address of an Address.
        if base.endswith(" *"):
            if base[:-2].strip() in SPEC_WORDS["handle"]:
                die("%s: `%s' is a handle, and a handle of a handle is not "
                    "a thing this tool writes" % (where, c_type))
            return "Address[%s]" % hilde_type(base, where)
        if base in C_TO_HILDE and base != "void":
            return "%s[%s]" % (pointer_wrap(), C_TO_HILDE[base])
        if base in SPEC_WORDS["ctype"]:
            return "%s[%s]" % (pointer_wrap(), SPEC_WORDS["ctype"][base])
        if base in SPEC_WORDS["struct"]:
            die("%s: `%s' is a struct of the spec, and a struct is passed by "
                "value, not pointed at" % (where, c_type))
        die("%s: no Hilde type for the C type `%s'" % (where, c_type))
    if c_type in C_TO_HILDE:
        return C_TO_HILDE[c_type]
    if c_type in SPEC_WORDS["ctype"]:
        return SPEC_WORDS["ctype"][c_type]
    if c_type in SPEC_WORDS["struct"]:
        return SPEC_WORDS["struct"][c_type]
    if c_type in SPEC_WORDS["opaque"]:
        die("%s: `%s' is opaque and can only be pointed at" % (where, c_type))
    if c_type in SPEC_WORDS["handle"]:
        die("%s: `%s' is a handle and can only be pointed at" % (where, c_type))
    die("%s: no Hilde type for the C type `%s'" % (where, c_type))


# What a real glibc header puts on a declaration and what a reader of C
# declarations has to take off again.  None of it changes the ABI; all of it
# stands between the return type and the name, or between the closing paren
# and the semicolon.
DECORATION = re.compile(
    r"__attribute__\s*\(\((?:[^()]|\([^()]*\))*\)\)"
    r"|__asm__\s*\([^)]*\)"
    r"|\b__extension__\b"
    r"|\b__restrict\b"
    r"|\b__THROW\b"
    r"|\b__nonnull\s*\(\([^)]*\)\)")


def preprocess(path):
    """The header as the C preprocessor sees it.

    A real header hides its prototypes behind macros -- glibc writes `sqrt'
    with `__MATHCALL' -- so a reader that does not expand them finds
    nothing.  The dependency this brings is a C compiler at generation time,
    which every Hilde build needs anyway.
    """
    import subprocess
    try:
        done = subprocess.run(["cc", "-E", "-P", path],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError as problem:
        die("cannot run the C preprocessor: %s" % problem)
    if done.returncode != 0:
        die("cc -E -P %s failed: %s"
            % (path, done.stderr.decode("utf-8", "replace").strip()[:200]))
    return done.stdout.decode("utf-8", "replace")


def preprocessed_defines(path):
    """Every macro the header defines, after preprocessing.

    `cc -E -P' CONSUMES the #defines, which is its job, so a header whose
    constants live in a header it includes -- which is the ordinary shape of
    a POSIX header -- would lose all of them.  `-dM' prints the macros
    instead of the text, and that is where they come back from.
    """
    import subprocess
    try:
        done = subprocess.run(["cc", "-E", "-dM", "-P", path],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError as problem:
        die("cannot run the C preprocessor: %s" % problem)
    if done.returncode != 0:
        die("cc -E -dM -P %s failed" % path)
    out = []
    for line in done.stdout.decode("utf-8", "replace").split("\n"):
        hit = DEFINE.match(line)
        if hit:
            out.append((hit.group(1), hit.group(2)))
    return out


def read_header(path, use_preprocessor=False):
    """The header as one line, with comments removed, plus its #define lines.

    Prototypes are matched over the joined text because a prototype may be
    written over several lines; #defines are matched line by line because
    they end at one.  The #defines always come from the RAW file: the
    preprocessor consumes them, which is its job and the opposite of what is
    wanted here.
    """
    with open(path) as stream:
        raw = stream.read()
    defines = []
    for line in raw.split("\n"):
        hit = DEFINE.match(line)
        if hit:
            defines.append((hit.group(1), hit.group(2)))
    if use_preprocessor:
        defines = preprocessed_defines(path)
    source = preprocess(path) if use_preprocessor else raw
    without_comments = re.sub(r"/\*.*?\*/", " ", source, flags=re.S)
    without_comments = DECORATION.sub(" ", without_comments)
    without_comments = re.sub(r"//[^\n]*", " ", without_comments)
    without_defines = "\n".join(
        line for line in without_comments.split("\n")
        if not line.lstrip().startswith("#"))
    return " ".join(without_defines.split()), defines


def find_prototype(text, name, where):
    pattern = re.compile(
        r"([A-Za-z_][A-Za-z0-9_ ]*?[ \*]+)" + re.escape(name) + r"\s*\(([^;]*?)\)\s*;")
    hit = pattern.search(text)
    if hit is None:
        die("%s: no prototype for `%s' in the header" % (where, name))
    return_type = hilde_type(hit.group(1), "%s: the return type of %s" % (where, name))
    raw_params = hit.group(2).strip()
    params = []
    if raw_params not in ("", "void"):
        for index, piece in enumerate(split_parameters(raw_params)):
            if FUNCTION_POINTER.match(piece.strip()):
                params.append(("arg%d" % (index + 1), hilde_type(
                    piece, "%s: parameter %d of %s" % (where, index + 1, name))))
                continue
            piece = normalise(piece)
            words = piece.split(" ")
            # A parameter may or may not be named.  When the last word is a
            # plain identifier and is not a type this tool knows, it is the
            # name; otherwise the whole piece is the type.
            if len(words) > 1 and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", words[-1]) \
                    and " ".join(words[:-1]).replace(" *", "*") not in ("",):
                maybe_type = " ".join(words[:-1])
                # A qualifier says nothing about which type it is: libargon2
                # declares `const uint32_t t_cost', a uint32_t, and before
                # the qualifier was taken off here the name went into the
                # type and the tool stopped.
                bare = normalise(maybe_type.replace("const ", "").replace("volatile ", ""))
                # A typedef the spec names with ctype is a type as well: DuckDB
                # passes its handles by value, `duckdb_config config'.  So is
                # a struct of the spec: Diplomat hands a slice over by value,
                # `DiplomatStringView message'.
                if bare in C_TO_HILDE or bare in SPEC_WORDS["ctype"] \
                        or bare in SPEC_WORDS["struct"] or maybe_type.endswith("*"):
                    params.append((hilde_name(words[-1], "arg%d" % (index + 1)),
                                   hilde_type(maybe_type,
                                              "%s: parameter %d of %s"
                                              % (where, index + 1, name))))
                    continue
            params.append(("arg%d" % (index + 1), hilde_type(
                piece, "%s: parameter %d of %s" % (where, index + 1, name))))
    return return_type, params


def split_parameters(raw):
    """The parameter list split at the commas that are not inside a
    function pointer's own parameter list."""
    pieces, depth, current = [], 0, ""
    for ch in raw:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            pieces.append(current)
            current = ""
        else:
            current += ch
    pieces.append(current)
    return pieces


STRUCT_BODY = re.compile(
    r"typedef\s+struct\s*(?:[A-Za-z_][A-Za-z0-9_]*)?\s*\{(.*?)\}\s*([A-Za-z_][A-Za-z0-9_]*)\s*;")


def read_struct(text, cname, where):
    """The fields of one struct the header passes by value, in the order
    of the header, each a (name, Hilde type).

    A slice and a flat result struct are all a bridge needs: a struct
    with a struct, an array or a union inside has an ABI this tool cannot
    name in a record, and stops it rather than being guessed at.
    """
    for hit in STRUCT_BODY.finditer(text):
        if hit.group(2) != cname:
            continue
        fields = []
        for piece in hit.group(1).split(";"):
            piece = normalise(piece)
            if not piece:
                continue
            if "[" in piece or "{" in piece:
                die("%s: the struct %s has a field of an array or a nested "
                    "body, and that ABI is not a record this tool writes"
                    % (where, cname))
            words = piece.split(" ")
            if len(words) < 2 or not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", words[-1]):
                die("%s: the struct %s has an unnamed field: %s"
                    % (where, cname, piece))
            fields.append((hilde_name(words[-1], "field%d" % (len(fields) + 1)),
                           hilde_type(" ".join(words[:-1]),
                                      "%s: the field %s of %s"
                                      % (where, words[-1], cname))))
        if not fields:
            die("%s: the struct %s has no field" % (where, cname))
        return fields
    die("%s: no struct %s in the header" % (where, cname))


# The keywords of lib/Lexer.mll that a C parameter name could be.
HILDE_KEYWORDS = {
    "and", "or", "not", "module", "is", "body", "import", "as", "end",
    "constant", "type", "function", "generic", "record", "union", "case",
    "of", "when", "typeclass", "instance", "method", "if", "then", "else",
    "let", "var", "while", "for", "do", "from", "to", "borrow", "return",
    "skip", "pragma", "sizeof", "nil", "true", "false",
}


def snake(name):
    """A name in snake_case, as a variable and a constant are written."""
    name = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name)
    name = re.sub(r"(?<=[A-Z])([A-Z])(?=[a-z])", r"_\1", name)
    return name.lower()


def hilde_name(raw, fallback):
    """A C parameter name as a Hilde identifier, or the fallback.

    A real header calls its parameters `__x' and `__addr': the underscores
    keep them out of the user's namespace in C, and a Hilde identifier may
    not begin with one.  Stripping them is safe -- the name is documentation
    on this side of the binding and nothing links against it.
    """
    name = raw.lstrip("_")
    if not name or not re.match(r"^[A-Za-z][A-Za-z0-9_]*$", name):
        return fallback
    name = snake(name)
    # A word the Hilde lexer takes for a keyword cannot name a parameter.
    # OpenSSL calls parameters `type'.
    if name in HILDE_KEYWORDS:
        return fallback
    return name


def integer_of(text):
    shifted = re.fullmatch(r"\(\s*1\s*<<\s*([0-9]+)\s*\)", text.strip())
    if shifted is not None:
        return 1 << int(shifted.group(1))
    hit = INTEGER.match(text.strip())
    if hit is None:
        return None
    body = hit.group(2)
    value = int(body, 16) if body[:2] in ("0x", "0X") else int(body)
    return -value if hit.group(1) == "-" else value


BANNER = ("-- Generated by scripts/gen-bindings.py from %s.  Do not edit:\n"
          "-- the generator is the source, and the gate runs it with --check.\n")


# The name a length parameter goes by: one of these whole snake_case
# names, or a name with len or length as a word of its own, or n over
# bytes or keys.  A count of something else, n_page of pages or n_params
# of parameters, is not the length of a buffer, and a note that said so
# would be a lie.
LENGTH_NAME = re.compile(
    r"^(n|len|length|size|count|room|buflen|outlen|out_len)$"
    r"|(^|_)len($|_)"
    r"|(^|_)length($|_)"
    r"|len$|length$"
    r"|^n_(byte|bytes|key)$")

INTEGER_TYPES = {"Int8", "Int16", "Int32", "Int64", "Nat8", "Nat16",
                 "Nat32", "Nat64", "Index", "ByteSize"}


def has_buffer_pair(params):
    """Whether one parameter is a pointer and a later one the length of
    what it points at.  The pointer may be an Address[Unit]: a buffer of
    bytes reads as void * in C as often as not.  The length is told from
    a count of pages by its name, len or length or n over bytes; a
    parameter the header leaves unnamed and puts an integer behind a
    pointer is its length as well, sqlite3_bind_text over the text and
    its byte count."""
    seen_pointer = False
    previous_typed = False
    for p, t in params:
        if t.startswith("Pointer[") or t.startswith("Address["):
            seen_pointer = True
            # A pointer of no element type is a handle or a context as
            # often as a buffer, so only one the header types carries an
            # unnamed length behind it.
            previous_typed = t != "Address[Unit]"
        elif seen_pointer and t in INTEGER_TYPES:
            if LENGTH_NAME.search(p) or (re.fullmatch(r"arg\d+", p)
                                         and previous_typed):
                return True
        else:
            previous_typed = False


def build(spec, spec_dir):
    header_path = os.path.join(spec_dir, spec["header"])
    if not os.path.isfile(header_path):
        die("no such header: " + header_path)
    text, defines = read_header(header_path, spec["preprocess"])
    where = spec["header"]
    SPEC_WORDS["opaque"] = spec["opaque"]
    SPEC_WORDS["handle"] = spec["handle"]
    SPEC_WORDS["struct"] = spec["struct"]
    SPEC_WORDS["ctype"] = spec["ctype"]
    SPEC_WORDS["callbacks"] = spec["callbacks"]
    if set(spec["struct"]) & set(spec["handle"]):
        die("%s: %s is named as a struct and as a handle, and one C type "
            "cannot be both" % (where, ", ".join(
                sorted(set(spec["struct"]) & set(spec["handle"])))))
    # The structs are read before the functions, so a function that takes
    # one by value already finds its Hilde type.
    struct_fields = {}
    for cname in sorted(spec["struct"]):
        struct_fields[cname] = read_struct(text, cname, where)

    constants = []
    known = dict(defines)
    for name, hilde in spec["constant"]:
        if hilde not in ("Int8", "Int16", "Int32", "Int64", "Nat8", "Nat16", "Nat32", "Nat64"):
            die("constant %s: the type must be an integer type, not `%s'" % (name, hilde))
        if name not in known:
            die("constant %s: the header has no #define of that name" % name)
        number = integer_of(known[name])
        if number is None:
            die("constant %s: its #define is not an integer: %s" % (name, known[name]))
        # PCRE2's result codes are negative, `(-1)'.  A negative
        # value in an unsigned type would be a different number, so it stops.
        if number < 0 and hilde.startswith("Nat"):
            die("constant %s: %d does not fit the unsigned type %s" % (name, number, hilde))
        constants.append((name, hilde, number))
    # A system constant has no value; the C compiler takes it from the
    # system header.
    for name, hilde in spec["system-constant"]:
        if hilde not in ("Int8", "Int16", "Int32", "Int64", "Nat8", "Nat16", "Nat32", "Nat64"):
            die("constant %s: the type must be an integer type, not `%s'" % (name, hilde))
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            die("constant %s: not a C identifier" % name)
        constants.append((name, hilde, None))
    names = [name for name, _h, _n in constants]
    if len(names) != len(set(names)):
        die("a constant is named twice: " + ", ".join(sorted(n for n in names if names.count(n) > 1)))
    constants.sort()

    functions = []
    for name in spec["function"]:
        return_type, params = find_prototype(text, name, where)
        functions.append((name, return_type, params))

    # A handle is a value that owns one C object, and the spec has to say
    # which function frees it: a linear type with no free function is a
    # leak the compiler cannot see past.  The one that frees it is named
    # after the C type and takes the handle, and no function takes two of
    # one kind, since the wrapper hands one pointer over at a time.
    free_of = {}
    for cname, hname in sorted(spec["handle"].items()):
        # A C function follows the case of the C side, and that is not
        # always the case the type is written in: sqlite3_close over
        # sqlite3, diag_destroy over Diag.  Both spellings are a free
        # function; the spec names one that follows no convention, such
        # as Diplomat's diplomat_free_write, as the fourth word.
        if cname in spec["handle-free"]:
            free_names = {spec["handle-free"][cname]}
        else:
            free_names = {cname + suffix
                          for suffix in ("_free", "_destroy", "_close")}
            free_names |= {cname.lower() + suffix
                           for suffix in ("_free", "_destroy", "_close")}
        for name, return_type, params in functions:
            if name not in free_names:
                continue
            if any(t == hname for _p, t in params):
                free_of[hname] = name
                break
        if hname not in free_of:
            die("handle %s: no function of the spec frees it; a linear "
                "handle needs one named %s_free, %s_destroy or %s_close "
                "that takes it" % (cname, cname, cname, cname))
    wrapped = []
    for name, return_type, params in functions:
        handle_params = [(p, t) for p, t in params if t in free_of]
        if len(handle_params) > 1:
            die("%s: the function %s takes two handles, and a wrapper hands "
                "one object over at a time" % (where, name))
        # A borrowed handle is read through and stays with the caller, so
        # each one takes a region of its own: R, Q, S, W.
        regions = ["R", "Q", "S", "W"]
        borrowed = [p for p, t in params if t.startswith(BORROWED)]
        if len(borrowed) > len(regions):
            die("%s: the function %s borrows more than four handles" % (where, name))
        final_params = []
        next_region = 0
        for p, t in params:
            if t.startswith(BORROWED):
                final_params.append(
                    (p, "%s%s, %s]" % (BORROWED, t[len(BORROWED):-1], regions[next_region])))
                next_region += 1
            else:
                final_params.append((p, t))
        params = final_params
        # A wrapper is the one place a contract can stand: the compiler
        # refuses a contract on a foreign function (H2052), and a wrapper
        # is a function of the module's own.  A function takes one when a
        # handle is unwrapped, when the C side hands an object back, when
        # one is read through a reference, or when the spec states a
        # precondition over its parameters.
        handle_param = handle_params[0][0] if handle_params else None
        needs_wrapper = (handle_param is not None or return_type in free_of
                         or borrowed
                         or name in {fname for fname, _e in spec["requires"]})
        wrapped.append((name, return_type, params,
                        handle_param, return_type in free_of, needs_wrapper))

    # The one contract a binding states in its own words: the precondition
    # the header states, over the names of the parameters.  Every name in
    # the condition must be a parameter of that function, so a condition
    # over a name the header does not use stops the tool instead of
    # standing as a lie in the committed file.
    requires_of = {}
    params_of = {name: params for name, _r, params, _h, _hr, _w in wrapped}
    for fname, expression in spec["requires"]:
        if fname not in params_of:
            die("%s: the `requires' names the function %s, and the spec "
                "takes no function of that name" % (where, fname))
        allowed = {p for p, _t in params_of[fname]}
        for word in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expression):
            if word not in allowed and word not in ("and", "or", "not",
                                                    "true", "false"):
                die("%s: the `requires' of %s names `%s', and that is no "
                    "parameter of it" % (where, fname, word))
        requires_of.setdefault(fname, []).append(expression)

    groups = []
    for type_name, width, prefix in spec["flags"]:
        if width not in ("Nat8", "Nat16", "Nat32", "Nat64"):
            die("flags %s: the width must be a Nat type, not `%s'" % (type_name, width))
        members = []
        for name, value in defines:
            if not name.startswith(prefix):
                continue
            number = integer_of(value)
            if number is None:
                continue
            members.append((name, number))
        if not members:
            die("flags %s: no #define with the prefix `%s' has an integer value"
                % (type_name, prefix))
        # By NAME, because the output is committed and the gate compares it.
        # `cc -E -dM' prints macros in an order of its own, and an artefact
        # whose order is the compiler's is an artefact that flaps.
        members.sort()
        groups.append((type_name, width, prefix, members))

    # `Address' and `Pointer' are not in the pervasive scope, so a module
    # that mentions one has to import it -- and the generator knows whether
    # it does.  A hand that forgets this import is the first thing a
    # generator should take off it.
    memory_names = set()
    for _name, return_type, params in functions:
        for rendered in [return_type] + [t for _p, t in params]:
            for name in ("Address", "Pointer"):
                if rendered.startswith(name + "["):
                    memory_names.add(name)
    # A struct of the spec carries its fields with it, and a field behind
    # a pointer needs the import as well.
    for cname in sorted(spec["struct"]):
        for _field, ftype in struct_fields[cname]:
            for name in ("Address", "Pointer"):
                if ftype.startswith(name + "["):
                    memory_names.add(name)
    # The body wraps every handle over the pointer the object lives at,
    # so a module with handles needs Address even when no function of
    # the interface mentions a pointer.
    if spec["handle"]:
        memory_names.add("Address")
    # A wrapper of a borrowed handle reads the address out of the
    # reference; it needs no name of its own beyond Address.
    body_names = set(memory_names)
    for _name, _return_type, params, _h, _hr, _w in wrapped:
        if any(t.startswith(BORROWED) for _p, t in params):
            body_names.add("Address")

    interface = [BANNER % spec["header"]]
    if memory_names:
        interface.append("import Hilde.Memory (\n%s\n);\n\n"
                         % ",\n".join("    " + n for n in sorted(memory_names)))
    interface.append("module %s is\n" % spec["module"])
    for cname in sorted(spec["handle"]):
        hname = spec["handle"][cname]
        interface.append("""    \"\"\"
    The %s of the header, as a value of its own.  A value owns one C
    object; %s frees it.  The type is linear: the compiler holds that
    nothing uses a value after the object is gone.
    \"\"\"
    type %s: Linear;

""" % (cname, free_of[hname], hname))
    for cname in sorted(spec["struct"]):
        interface.append("""    \"\"\"
    The %s of the header, passed by value.  The fields stand in the
    order of the header, each named as a Hilde field is.
    \"\"\"
    record %s: Free is
""" % (cname, spec["struct"][cname]))
        for field, ftype in struct_fields[cname]:
            interface.append("        %s: %s;\n" % (field, ftype))
        interface.append("    end;\n\n")
    for name, hilde, _number in constants:
        interface.append("    constant %s: %s;\n" % (snake(name), hilde))
    if constants:
        interface.append("\n")
    for type_name, width, prefix, members in groups:
        interface.append("""    \"\"\"
    The %s constants of the header, as a type of their own.  The number
    is inside; nothing outside this module can add one to a length by
    accident.
    \"\"\"
    record %s: Free is
        bits: %s;
    end;

""" % (prefix, type_name, width))
        interface.append("""    \"\"\"
    Two of them together.
    \"\"\"
    function combine%s(left: %s, right: %s): %s
        ensures result.bits = bitwiseOr(left.bits, right.bits);

    \"\"\"
    The number the C side wants.  The one place it leaves the type.
    \"\"\"
    function raw%s(value: %s): %s
        ensures result = value.bits;

""" % (type_name, type_name, type_name, type_name,
       type_name, type_name, width))
        for name, _number in members:
            interface.append("    constant %s: %s;\n" % (snake(name), type_name))
        interface.append("\n")
    for name, return_type, params, handle_param, handle_return, needs_wrapper in wrapped:
        borrowed = [p for p, t in params if t.startswith(BORROWED)]
        if handle_param is not None and handle_return:
            line = ("Takes the object the value stands for, does its work, "
                    "and gives it back.")
        elif handle_return:
            line = ("Makes the object the value stands for; %s frees it."
                    % free_of[return_type])
        elif borrowed:
            line = ("Reads through the object the value stands for; the "
                    "object stays with the caller.")
        elif handle_param is not None:
            hname = dict(params)[handle_param]
            if name == free_of[hname]:
                line = ("Frees the object the value stands for.  The value "
                        "is gone with it.")
            else:
                line = ("Takes the object the value stands for and spends "
                        "it; %s is the one that frees it." % free_of[hname])
        else:
            line = "%s from the header." % name
        reqs = requires_of.get(name, [])
        if reqs:
            # The contract is stated, in the words of the header, on a
            # function of the module's own: the compiler holds every
            # caller to it, and no note stands beside it.
            interface.append('    """\n    %s\n    """\n' % line)
        elif needs_wrapper:
            # A function of the module's own whose work is C behind a
            # pointer: what it gives back has no property a contract
            # could hold, and the reason says which one it is.
            if handle_param is not None and handle_return:
                reason = ("No contract: the work is the work of C behind "
                          "the pointer.")
            elif handle_return:
                reason = ("No contract: the value it gives back has no "
                          "property but its type.")
            elif handle_param is not None and name == free_of[dict(params)[handle_param]]:
                reason = ("No contract: it only frees or closes what it "
                          "is given.")
            elif has_buffer_pair(params):
                reason = ("No contract: the header names no bound a "
                          "requires could copy, and the duty over the "
                          "buffer behind the pointer -- it holds the "
                          "bytes the length names -- no type of this "
                          "module can state.  The safe module built on "
                          "this one hands a span over and holds the "
                          "bound with the length of the span.")
            else:
                reason = ("No contract: the work is the work of C behind "
                          "the pointer.")
            interface.append('    """\n    %s\n\n    %s\n    """\n'
                             % (line, reason))
        elif has_buffer_pair(params):
            interface.append('    """\n'
                             '    %s\n'
                             '\n'
                             '    No contract: the header names no bound a '
                             'requires could copy, and the duty over the '
                             'buffer behind the pointer -- it holds the '
                             'bytes the length names -- no type of this '
                             'module can state.  The safe module built on '
                             'this one hands a span over and holds the '
                             'bound with the length of the span.\n'
                             '    """\n' % line)
        else:
            interface.append('    """\n'
                             '    %s\n'
                             '\n'
                             '    No contract: the header states no '
                             'condition over its parameters, and a '
                             'condition the header does not state would '
                             'be a lie.\n'
                             '    """\n' % line)
        rendered = ", ".join("%s: %s" % (p, t) for p, t in params)
        generic = ""
        if borrowed:
            generic = "    generic [%s]\n" % ", ".join(
                "%s: Region" % t[len(BORROWED):-1].split(", ")[1] for _p, t in params
                if t.startswith(BORROWED))
        if reqs:
            interface.append("%s    function %s(%s): %s\n%s\n"
                             % (generic, name, rendered, return_type,
                                "".join("        requires %s;\n" % r
                                        for r in reqs)))
        else:
            interface.append("%s    function %s(%s): %s;\n\n"
                             % (generic, name, rendered, return_type))
    close_without_blank(interface, "end module.\n")

    body = [BANNER % spec["header"]]
    body.append("pragma Unsafe_Module;\n")
    for library in spec["library"]:
        body.append('pragma Foreign_Library(Name => "%s");\n' % library)
    for header in spec["system-header"]:
        body.append('pragma Foreign_Header(Name => "%s");\n' % header)
    if body_names:
        body.append("\nimport Hilde.Memory (\n%s\n);\n"
                    % ",\n".join("    " + n for n in sorted(body_names)))
    body.append("\nmodule body %s is\n" % spec["module"])
    for cname in sorted(spec["handle"]):
        hname = spec["handle"][cname]
        body.append("    record %s: Linear is\n        pointer: Address[Unit];\n    end;\n\n"
                    % hname)
    for name, hilde, number in constants:
        if number is None:
            body.append('    constant %s: %s := @embed(%s, "%s");\n' % (snake(name), hilde, hilde, name))
        else:
            body.append("    constant %s: %s := %d;\n" % (snake(name), hilde, number))
    if constants:
        body.append("\n")
    for type_name, width, prefix, members in groups:
        body.append("    function combine%s(left: %s, right: %s): %s is\n"
                    "        return %s(bits => bitwiseOr(left.bits, right.bits));\n"
                    "    end;\n\n" % (type_name, type_name, type_name, type_name,
                                      type_name))
        body.append("    function raw%s(value: %s): %s is\n"
                    "        return value.bits;\n    end;\n\n"
                    % (type_name, type_name, width))
        for name, number in members:
            body.append("    constant %s: %s := %s(bits => %d);\n"
                        % (snake(name), type_name, type_name, number))
        body.append("\n")
    for name, return_type, params, handle_param, handle_return, needs_wrapper in wrapped:
        rendered = ", ".join("%s: %s" % (p, t) for p, t in params)
        borrowed = [p for p, t in params if t.startswith(BORROWED)]
        generic = ""
        if borrowed:
            generic = "    generic [%s]\n" % ", ".join(
                "%s: Region" % t[len(BORROWED):-1].split(", ")[1] for _p, t in params
                if t.startswith(BORROWED))
        if handle_param is None and not handle_return and not borrowed:
            if not needs_wrapper:
                body.append('    pragma Foreign_Import(External_Name => "%s");\n' % name)
                body.append("    function %s(%s): %s is\n    end;\n\n"
                            % (name, rendered, return_type))
                continue
            # A wrapper for the contract alone: the raw import keeps the
            # C name, and the function of the module's own carries the
            # requires the interface states and hands the call over.
            raw_name = name + "_raw"
            call_arguments = ", ".join(p for p, _t in params)
            body.append('    pragma Foreign_Import(External_Name => "%s");\n' % name)
            body.append("    function %s(%s): %s is\n    end;\n\n"
                        % (raw_name, rendered, return_type))
            if return_type == "Unit":
                body.append("    function %s(%s): Unit is\n"
                            "        %s(%s);\n"
                            "        return nil;\n    end;\n\n"
                            % (name, rendered, raw_name, call_arguments))
            else:
                body.append("    function %s(%s): %s is\n"
                            "        return %s(%s);\n    end;\n\n"
                            % (name, rendered, return_type, raw_name,
                               call_arguments))
            continue
        if borrowed and handle_param is None and not handle_return:
            # A read through the object: the value stays with the caller,
            # so the raw import takes the address the value holds and the
            # wrapper reads that address out of the reference.
            raw_name = name + "_raw"
            raw_params = ", ".join(
                "%s: Address[Unit]" % p if p in borrowed else "%s: %s" % (p, t)
                for p, t in params)
            call_arguments = ", ".join(
                "%s_pointer" % p if p in borrowed else p for p, _t in params)
            body.append('    pragma Foreign_Import(External_Name => "%s");\n' % name)
            body.append("    function %s(%s): %s is\n    end;\n\n"
                        % (raw_name, raw_params, return_type))
            prelude = "".join(
                "        let %s_pointer: Address[Unit] := (%s->pointer);\n"
                % (p, p) for p in borrowed)
            if return_type == "Unit":
                body.append("%s    function %s(%s): Unit is\n"
                            "%s        %s(%s);\n"
                            "        return nil;\n    end;\n\n"
                            % (generic, name, rendered, prelude,
                               raw_name, call_arguments))
            else:
                body.append("%s    function %s(%s): %s is\n"
                            "%s        return %s(%s);\n    end;\n\n"
                            % (generic, name, rendered, return_type, prelude,
                               raw_name, call_arguments))
            continue
        # The C function takes the pointer the object lives at and gives
        # nothing of the value back; the wrapper takes the linear value,
        # hands the pointer over, and builds the value again when the C
        # side gives the object back.  The raw function keeps the C name
        # with _raw behind it, so the pragma names the C function and the
        # wrapper the one a caller sees.
        raw_name = name + "_raw"
        raw_params = ", ".join(
            "%s: %s" % (p, "Address[Unit]" if p == handle_param else t)
            for p, t in params)
        raw_return = "Address[Unit]" if handle_return else return_type
        call_arguments = ", ".join(
            "pointer" if p == handle_param else p for p, _t in params)
        body.append('    pragma Foreign_Import(External_Name => "%s");\n' % name)
        body.append("    function %s(%s): %s is\n    end;\n\n"
                    % (raw_name, raw_params, raw_return))
        if handle_param is not None:
            body.append("    function %s(%s): %s is\n"
                        "        let { pointer: Address[Unit] } := %s;\n"
                        % (name, rendered, return_type, handle_param))
            if handle_return:
                body.append("        let given_back: Address[Unit] := %s(%s);\n"
                            "        return %s(pointer => given_back);\n    end;\n\n"
                            % (raw_name, call_arguments, return_type))
            elif return_type == "Unit":
                body.append("        %s(%s);\n        return nil;\n    end;\n\n"
                            % (raw_name, call_arguments))
            else:
                body.append("        return %s(%s);\n    end;\n\n"
                            % (raw_name, call_arguments))
        else:
            body.append("    function %s(%s): %s is\n"
                        "        let pointer: Address[Unit] := %s(%s);\n"
                        "        return %s(pointer => pointer);\n    end;\n\n"
                        % (name, rendered, return_type, raw_name,
                           call_arguments, return_type))
    close_without_blank(body, "end module body.\n")

    return "".join(interface), "".join(body)


def main():
    args = sys.argv[1:]
    check = "--check" in args
    rest = [a for a in args if not a.startswith("--")]
    if len(rest) != 1:
        print(__doc__, file=sys.stderr)
        sys.exit(9)
    spec_path = rest[0]
    if not os.path.isfile(spec_path):
        die("no such spec: " + spec_path)
    spec_dir = os.path.dirname(os.path.abspath(spec_path))
    spec = read_spec(spec_path)
    interface, body = build(spec, spec_dir)

    out = os.path.join(spec_dir, spec["output"])
    pairs = [(out + ".hih", interface), (out + ".hiq", body)]
    if check:
        bad = 0
        for path, wanted in pairs:
            if not os.path.isfile(path):
                print("%s: missing" % path)
                bad += 1
                continue
            if open(path).read() != wanted:
                print("%s: differs from what the generator produces" % path)
                bad += 1
        if bad:
            print("gen-bindings --check: %d file(s) out of date" % bad)
            sys.exit(1)
        print("gen-bindings --check: %s is current (%d files)"
              % (spec["module"], len(pairs)))
        sys.exit(0)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    for path, contents in pairs:
        with open(path, "w") as stream:
            stream.write(contents)
        print("wrote %s (%d bytes)" % (path, len(contents)))


if __name__ == "__main__":
    main()
