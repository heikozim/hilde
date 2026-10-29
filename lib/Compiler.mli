(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier

type compiler

val empty_compiler : compiler

val compiler_code : compiler -> string

(** The C libraries the modules compiled so far have named with
    [pragma Foreign_Library(Name => "...")], in the order the modules were
    reached, each name once, the first occurrence kept. *)
val compiler_libraries : compiler -> string list

type module_source =
  | TwoFileModuleSource of {
      int_filename: string;
      int_code: string;
      body_filename: string;
      body_code: string
    }
  | BodyModuleSource of {
      body_filename: string;
      body_code: string
    }

val compile_mod : ?emit:bool -> compiler -> module_source -> compiler

(** Put a list of modules into an order in which each one is compiled after
    the modules it imports from.  Stable among modules that do not depend on
    each other, and a no-op where the order cannot be computed -- an
    unreadable head, a cycle -- so that the compilation itself reports those
    in its own words.  Exported so that it can be tested without running a
    compilation. *)
val sort_modules : module_source list -> module_source list

(** Refuse any of these modules that carries [pragma Unsafe_Module;].  The
    modules that ship with the compiler are exempt by origin: they never pass
    through here, because [empty_compiler] compiles them from sources
    embedded in the binary.  A module whose head does not parse is left to
    the compilation to report. *)
val refuse_unsafe_modules : module_source list -> unit

val compile_multiple : compiler -> module_source list -> compiler

(** hilde check: the modules in the order of their imports, each parsed,
    typed, its contracts and its linearity checked, and nothing
    monomorphised or written as C.  The first error is raised as
    compile_multiple raises it. *)
val check_multiple : compiler -> module_source list -> compiler

(** `hilde query': compile the modules, then describe
    the named one -- every declaration with its kind, its types as the
    compiler resolved them, and its span -- as JSON.  A module that is not
    among them is a command-line error. *)
val query_modules : module_source list -> module_name -> Yojson.Basic.t

(** hilde guard: compile the modules,
    then report the programme's attack surface as text -- the unsafe modules
    on the command line, the C libraries and headers, every foreign function
    and embed with whether the programme reaches it, and the exported
    functions.  An entrypoint that is not a function of those modules is a
    command-line error. *)
val guard_modules : module_source list -> (module_name * identifier) option -> string

(** The same report with the part on vulnerabilities when a check is given,
    and the number of advisories the programme reaches. *)
val guard_report : module_source list -> (module_name * identifier) option
  -> vulnerabilities:Guard.vulnerability_check option -> string * int

(** hilde guard inside a package: the capabilities each package uses, held
    against those its hilde.toml declares; the lines of the report and the
    number used undeclared. *)
val guard_capabilities : module_source list -> (module_name * identifier) option
  -> packages:Guard.package_rule list -> string list * int

val compile_entrypoint : compiler -> module_name -> identifier -> compiler

val post_compile : compiler -> compiler

(** The head of the link manifest, the last line of every C file the
    compiler writes: [/* hilde link libraries: m z */]. *)
val link_manifest_prefix : string

(** The C of the compiled programme followed by its link manifest, as
    [hilde compile --target-type=c] writes it. *)
val c_file_text : compiler -> string

(** The C of a library: HILDE_LIBRARY defined, then the programme's C. *)
val library_code : compiler -> string

(** [library_header_text compiler file_name] is the header of the library,
    to be written as [file_name] beside it. *)
val library_header_text : compiler -> string -> string

(** [library_export_names compiler] are the C names of the exported
    functions, in the order of the header. *)
val library_export_names : compiler -> string list

(** The name of a module and the modules it imports, read from its source.
    A head that does not parse raises the error the compilation would. *)
val module_name_and_imports : module_source -> module_name * module_name list

(** The two forms of a test: no parameter, or the root capability
    lent to it. *)
type test_form =
  | TestPlain
  | TestWithRoot

(** Whether a function's name makes it a test: [test] followed by a capital
    letter or a digit. *)
val is_test_name : identifier -> bool

(** The tests of a test file the compiler has already compiled, in the order
    the file declares them.  A function with a test's name and another form
    is H2046; a test file without a test is H2047. *)
val test_functions : compiler -> module_source -> module_name * (identifier * test_form) list
