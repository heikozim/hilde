(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)
open CRepr

type indentation

type line

val zero_indent : indentation

val render_type : c_ty -> string

val render_line : line -> string

val render_unit : c_unit -> string

val render_unit_declarations : c_unit -> string
(** The unit with every function definition turned into the declaration of
    its head, for the other translation units of a programme built in
    parts.
    No contract: every unit is accepted, and what the text holds is the
    work of [render_unit]. *)

val render_decl : indentation -> c_decl -> line list

(* render_stmt and render_switch_case were exported here and called from
   nowhere.  They now take the set of names the surrounding function declares
   and never reads, which is a fact about a whole function body and cannot be
   supplied by a caller holding one statement.  Rather than export a set type
   for nobody, the two are internal to CRenderer. *)

val render_expr : c_expr -> string
