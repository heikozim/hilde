(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Identifier
open Id
open Env
open Stages.Mtast
open CRepr

val gen_decl_id : decl_id -> string

val gen_mono_id : mono_id -> string

val gen_ident : identifier -> string

val gen_module_name : module_name -> string

val c_string_type : c_ty

val fn_type : c_ty

val gen_module : env -> mono_module -> c_unit

(** Write a [#line] before every generated function, pointing at the
    Hilde declaration it came from.  Off unless this is called with
    [true]. *)
val set_line_directives : bool -> unit
