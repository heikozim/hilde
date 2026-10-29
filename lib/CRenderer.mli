(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open CRepr

type indentation

type line

val zero_indent : indentation

val render_type : c_ty -> string

val render_line : line -> string

val render_unit : c_unit -> string

val render_decl : indentation -> c_decl -> line list

(* render_stmt and render_switch_case were exported here and called from
   nowhere.  They now take the set of names the surrounding function declares
   and never reads, which is a fact about a whole function body and cannot be
   supplied by a caller holding one statement.  Rather than export a set type
   for nobody, the two are internal to CRenderer. *)

val render_expr : c_expr -> string
