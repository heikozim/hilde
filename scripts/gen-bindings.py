#!/usr/bin/env python3
#
# Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE file for details.
#
# SPDX-FileCopyrightText: 2026 Heiko Zimmermann
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
            "constant": [], "opaque": [], "ctype": {}, "callbacks": False,
            "system-header": [], "system-constant": []}
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


# The spec's own words about the header -- `opaque', `ctype', `callbacks'
# -- are read by hilde_type; build() sets them before the first call.
SPEC_WORDS = {"opaque": [], "ctype": {}, "callbacks": False}


def hilde_type(c_type, where):
    raw = c_type.strip()
    for word in ("const ", "extern ", "static ", "inline ", "register "):
        raw = raw.replace(word, "")
    if FUNCTION_POINTER.match(raw.strip()):
        if SPEC_WORDS["callbacks"]:
            return "Address[Unit]"
        die("%s: `%s' is a function pointer, and the spec has no `callbacks address'"
            % (where, normalise(raw)))
    c_type = normalise(c_type)
    c_type = c_type.replace("const ", "")
    # A storage class says nothing about the ABI, and a real header
    # writes one on every declaration.
    for word in ("extern ", "static ", "inline ", "register "):
        c_type = c_type.replace(word, "")
    c_type = normalise(c_type)
    if c_type.endswith(" *") or c_type == "*":
        base = c_type[:-2].strip()
        if base == "void" or base in SPEC_WORDS["opaque"]:
            return "Address[Unit]"
        if base in POINTEE_ONLY:
            return "Address[%s]" % POINTEE_ONLY[base]
        # A pointer to a pointer: `sqlite3 **' is an Address of an Address.
        if base.endswith(" *"):
            return "Address[%s]" % hilde_type(base, where)
        if base in C_TO_HILDE and base != "void":
            return "Address[%s]" % C_TO_HILDE[base]
        if base in SPEC_WORDS["ctype"]:
            return "Address[%s]" % SPEC_WORDS["ctype"][base]
        die("%s: no Hilde type for the C type `%s'" % (where, c_type))
    if c_type in C_TO_HILDE:
        return C_TO_HILDE[c_type]
    if c_type in SPEC_WORDS["ctype"]:
        return SPEC_WORDS["ctype"][c_type]
    if c_type in SPEC_WORDS["opaque"]:
        die("%s: `%s' is opaque and can only be pointed at" % (where, c_type))
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
                # passes its handles by value, `duckdb_config config'.
                if bare in C_TO_HILDE or bare in SPEC_WORDS["ctype"] or maybe_type.endswith("*"):
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


# The keywords of lib/Lexer.mll that a C parameter name could be.
HILDE_KEYWORDS = {
    "and", "or", "not", "module", "is", "body", "import", "as", "end",
    "constant", "type", "function", "generic", "record", "union", "case",
    "of", "when", "typeclass", "instance", "method", "if", "then", "else",
    "let", "var", "while", "for", "do", "from", "to", "borrow", "return",
    "skip", "pragma", "sizeof", "nil", "true", "false",
}


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


def build(spec, spec_dir):
    header_path = os.path.join(spec_dir, spec["header"])
    if not os.path.isfile(header_path):
        die("no such header: " + header_path)
    text, defines = read_header(header_path, spec["preprocess"])
    where = spec["header"]
    SPEC_WORDS["opaque"] = spec["opaque"]
    SPEC_WORDS["ctype"] = spec["ctype"]
    SPEC_WORDS["callbacks"] = spec["callbacks"]

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

    # `Address' is not in the pervasive scope, so a module that mentions it
    # has to import it -- and the generator knows whether it does.  A hand
    # that forgets this import is the first thing a generator should take
    # off it.
    uses_address = any(
        rendered.startswith("Address[")
        for _name, return_type, params in functions
        for rendered in [return_type] + [t for _p, t in params])

    interface = [BANNER % spec["header"]]
    if uses_address:
        interface.append("import Hilde.Memory (\n    Address\n);\n\n")
    interface.append("module %s is\n" % spec["module"])
    for name, hilde, _number in constants:
        interface.append("    constant %s: %s;\n" % (name, hilde))
    if constants:
        interface.append("\n")
    for type_name, width, prefix, members in groups:
        interface.append("""    \"\"\"
    The %s constants of the header, as a type of their own.  The number
    is inside; nothing outside this module can add one to a length by
    accident.
    \"\"\"
    type %s: Free;

    \"\"\"
    Two of them together.
    \"\"\"
    function combine%s(left: %s, right: %s): %s;

    \"\"\"
    The number the C side wants.  The one place it leaves the type.
    \"\"\"
    function raw%s(value: %s): %s;

""" % (prefix, type_name, type_name, type_name, type_name, type_name,
       type_name, type_name, width))
        for name, _number in members:
            interface.append("    constant %s: %s;\n" % (name, type_name))
        interface.append("\n")
    for name, return_type, params in functions:
        rendered = ", ".join("%s: %s" % (p, t) for p, t in params)
        interface.append("    function %s(%s): %s;\n\n" % (name, rendered, return_type))
    close_without_blank(interface, "end module.\n")

    body = [BANNER % spec["header"]]
    body.append("pragma Unsafe_Module;\n")
    for library in spec["library"]:
        body.append('pragma Foreign_Library(Name => "%s");\n' % library)
    for header in spec["system-header"]:
        body.append('pragma Foreign_Header(Name => "%s");\n' % header)
    if uses_address:
        body.append("\nimport Hilde.Memory (\n    Address\n);\n")
    body.append("\nmodule body %s is\n" % spec["module"])
    for name, hilde, number in constants:
        if number is None:
            body.append('    constant %s: %s := @embed(%s, "%s");\n' % (name, hilde, hilde, name))
        else:
            body.append("    constant %s: %s := %d;\n" % (name, hilde, number))
    if constants:
        body.append("\n")
    for type_name, width, prefix, members in groups:
        body.append("    record %s: Free is\n        bits: %s;\n    end;\n\n"
                    % (type_name, width))
        body.append("    function combine%s(left: %s, right: %s): %s is\n"
                    "        return %s(bits => bitwiseOr(left.bits, right.bits));\n"
                    "    end;\n\n" % (type_name, type_name, type_name, type_name,
                                      type_name))
        body.append("    function raw%s(value: %s): %s is\n"
                    "        return value.bits;\n    end;\n\n"
                    % (type_name, type_name, width))
        for name, number in members:
            body.append("    constant %s: %s := %s(bits => %d);\n"
                        % (name, type_name, type_name, number))
        body.append("\n")
    for name, return_type, params in functions:
        rendered = ", ".join("%s: %s" % (p, t) for p, t in params)
        body.append('    pragma Foreign_Import(External_Name => "%s");\n' % name)
        body.append("    function %s(%s): %s is\n    end;\n\n"
                    % (name, rendered, return_type))
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
