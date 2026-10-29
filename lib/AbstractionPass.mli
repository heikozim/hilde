(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** In the abstraction pass, we:

    1. Qualify identifiers.
    2. Qualify type specifiers.
    3. Reshape let statements: put the code after a let
       under the let.
    4. Turn blocks from lists to pairs.
 *)
open Imports
open Cst
module Ast = Stages.Ast
open Ast

val abs_stmt : import_map -> cstmt -> astmt

val abs_expr :import_map -> cexpr -> aexpr

(** Whether a function takes the call site of its callers, because it has a
    requires; set by the combining pass while it combines a module. *)
val contract_callee : (Identifier.qident -> bool) ref
