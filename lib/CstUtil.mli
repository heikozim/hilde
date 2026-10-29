(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** Utilities for the concrete syntax tree. *)
open Identifier
open Cst
open Common

(** Used by the parser to easily create a module body from its components and a list of pragmas. *)
(** A module interface from its parts; the pragmas before it may only be
    one pragma Targets, whose targets are kept in ModuleTargets (H2069). *)
val make_module_int : module_name -> docstring -> pragma list -> concrete_import_list list -> concrete_decl list -> concrete_module_interface

val make_module_body : module_name -> concrete_import_list list -> pragma list -> concrete_def list -> docstring -> concrete_module_body

(** The text of the file being parsed, set by ParserInterface before each
    parse, read by the parser for the text of a contract's condition. *)
val parse_source : string ref

(** The bytes of the file being parsed between two positions; a run of
    white space that holds a line end becomes one space. *)
val source_text : Lexing.position -> Lexing.position -> string

(** A contract clause from its kind, the start of its keyword, the start and
    end of its condition, and the condition. *)
val make_contract_clause : contract_kind -> Lexing.position -> Lexing.position -> Lexing.position -> cexpr -> contract_clause
val make_raises_clause : Lexing.position -> Lexing.position -> identifier list -> contract_clause

val concrete_decl_name : concrete_decl -> identifier option

val def_name : concrete_def -> identifier option

val get_concrete_decl : concrete_module_interface -> identifier -> concrete_decl option

val get_concrete_def : concrete_module_body -> identifier -> concrete_def option

val has_instance_decl : concrete_module_interface -> identifier -> concrete_type_param list -> typespec -> bool

val get_instance_def : concrete_module_body -> identifier -> concrete_type_param list -> typespec -> concrete_instance option

val make_pragma : identifier -> concrete_arglist -> pragma

val mod_int_name : concrete_module_interface -> module_name

val mod_body_name : concrete_module_body -> module_name

val typespec_string : typespec -> string

val decl_replace_docstring_and_pragmas: concrete_decl -> docstring -> pragma list -> concrete_decl

val def_replace_docstring_and_pragmas: concrete_def -> docstring -> pragma list -> concrete_def
