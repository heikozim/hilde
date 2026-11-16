(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

(** Utility code used throughout the compiler. *)

open Identifier

(** Explode a string into a list of characters. *)
val string_explode : string -> char list

(** Implode a list of characters into a string. *)
val string_implode : char list -> string

(** Read the file at the given path into a string. *)
val read_file_to_string : string -> string

(** Raises the error of a file that could not be opened or read, H1034,
    with the path and the message of the system. *)
val read_error : string -> string -> 'a

(** Write the contents of a string to a file.

    The first argument is the path, the second the contents. *)
val write_string_to_file : string -> string -> unit

(** Remove all instances of a given character from a string. *)
val remove_char : string -> char -> string

(** Replace all instances of a given character with a string.

    The first argument is the string to search/replace on, the third
    argument is the string to replace the character with. *)
val replace_char : string -> char -> string -> string

type replacement = { text: string; search: string; replacement: string }

(** Replace a string with another in a text. *)
val search_replace : replacement -> string

(** Remove the first n characters of a string. *)
val remove_leading : string -> int -> string

(** Parse a hexadecimal string into an integer. *)
val parse_hex : string -> int

(** Parse a binary string into an integer. *)
val parse_bin : string -> int

(** Parse an octal string into an integer. *)
val parse_oct : string -> int

(** The text between the apostrophes of a character literal. *)
val char_body : string -> string

(** Parse an ASCII character into its integer code, handling escape sequences. *)
val parse_ascii_char : string -> int

(** Take the contents of a triple-quoted string, and trim the leading and ending
   empty lines as well as indentation. *)
val process_triple_string : string -> string

(** Check whether two lists of identifiers are the same set. *)
val ident_set_eq : identifier list -> identifier list -> bool

(** Represents the output of running an external command. *)
type command_output =
  CommandOutput of { command: string; code: int; stdout: string; stderr: string }

(** Run a program and return its output.

    The first element of the argument vector is the program, which is looked
    up in PATH; the rest are its arguments. No shell is involved: an argument
    containing a space or a shell metacharacter is passed through whole. *)
val run_command : string array -> command_output

(** Call the C compiler on the given file.

    The first argument is the source file path.

    The second argument is the output binary file path. *)
(** [library_flags name] is the cc flags for one library of the link
    manifest: pkg-config's [--cflags --libs] when pkg-config knows [name],
    otherwise [-lname]. *)
val library_flags : string -> string list

(** The flags of cc that every executable programme is built with, from
    one file or in parts: -O2, and -fno-strict-aliasing, since the runtime
    and the generated C do not promise that pointers of different types
    never meet.
    Ensures: holds -O2 and -fno-strict-aliasing. *)
val programme_flags : string list

(** [compile_c_code source output libraries] runs the C compiler over
    [source], linking against each name of [libraries] with the flags of
    [library_flags].  [extra_flags] go after the compiler's own and before
    the source: [hilde test] passes its instrument's flags there. *)
val compile_c_code : ?extra_flags:string list -> string -> string -> string list -> command_output

(** [compile_library ~shared source output libraries] builds a library from
    one C file, both kinds with -fPIC: a shared object with -shared and
    -fvisibility=hidden, linked against [libraries], or a static archive
    made by ar(1) from one object.  H1014 when cc or ar fails. *)
val compile_library : shared:bool -> string -> string -> string list -> unit

(** [find_on_path name] is the first file [name] in a directory of PATH. *)
val find_on_path : string -> string option

(** The compiler for wasm32-wasi as the first words of its command line:
    zig (HILDE_ZIG, else on PATH), else clang on PATH with wasm-ld and the C
    library of WASI; HILDE_WASM_CC=zig or clang chooses.  H1038 when none
    is found, H1039 for another name in HILDE_WASM_CC. *)
val wasm_compiler : string list Lazy.t

(** [compile_wasm_module ~reactor source output exports libraries] builds a
    module for wasm32-wasi from one C file: a reactor, a library whose host
    calls it, with the runtime's functions exported, or a command, a
    programme with main.  [exports] are exported in both.  H1014 when the
    compiler fails. *)
val compile_wasm_module : reactor:bool -> string -> string -> string list -> string list -> unit

(** [compile_wasm source output exports libraries] is
    [compile_wasm_module ~reactor:true]: a library for wasm32-wasi. *)
val compile_wasm : string -> string -> string list -> string list -> unit

(** wasmtime: HILDE_WASMTIME, else on PATH; H1040 when neither. *)
val wasm_runtime : string Lazy.t

(** [wasm_run_argv dir module args] is the command line that runs a command
    module in wasmtime with [dir] as its working directory, /tmp beside it,
    the environment passed on and [args] after the module. *)
val wasm_run_argv : string -> string -> string list -> string list

(** The line wasmtime writes to standard error before its report of a trap. *)
val wasm_trap_marker : string

(** Like `mapAccumL` in Haskell. *)
val map_with_context : (('c * 'a) -> ('c * 'b)) -> 'c -> 'a list -> ('c * ('b list))

val iter_with_context : ('c -> 'a -> 'c) -> 'c -> 'a list -> 'c

(** Get the last element of a list. Error for an empty list. *)
val last : 'a list -> 'a

(** Get all elements but the last one of a list. Error for an empty list. *)
val butlast : 'a list -> 'a list

(** The system the compiler runs on, as [uname -s] names it; the empty
    string when uname cannot be run. *)
val host_system : string Lazy.t

(** The names of the targets: linux, openbsd, freebsd, darwin and wasm. *)
val target_names : string list

(** The target of the system the compiler runs on; empty on another system. *)
val host_target : string Lazy.t

(** The target of this run, set from --target; empty means the host's. *)
val build_target : string ref

(** The target of this run: [build_target], else the host's. *)
val current_target : unit -> string

(** The machines a programme is cross-built for, by the values of --target
    that name a whole machine: x86_64-openbsd, aarch64-openbsd,
    x86_64-linux-musl and aarch64-linux-musl. *)
val target_triples : string list

(** [triple_system triple] is the name of [target_names] the machine is
    built for, the word between its width and its C library. *)
val triple_system : string -> string

(** [triple_shaped name] holds when the value is shaped as a machine name,
    <arch>-<system> with the system one of the two the machines build for. *)
val triple_shaped : string -> bool

(** The width of the machine the compiler runs on, from [uname -m], with
    amd64 and arm64 brought to x86_64 and aarch64; empty on another width. *)
val host_arch : string Lazy.t

(** [triple_is_host triple] holds when the machine's system and width are
    this one's; its C library is left out, since the native cc builds for
    its own. *)
val triple_is_host : string -> bool

(** The machine of --target that this run cross-builds for, set by the
    parser; empty without one. *)
val cross_triple : string ref

(** zig as the C compiler of a cross build, [zig; "cc"]: HILDE_ZIG, else
    zig on PATH; None when there is none.  Looked up each call. *)
val zig_cc : unit -> string list option

(** The C compiler of this run as the first words of its command line:
    [zig; "cc"; "-target"; <machine>] for a machine of --target with zig
    there, else the native cc. *)
val cc_command : unit -> string list

