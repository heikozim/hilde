(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** The type checker. *)
open Identifier
open Common
open Env
open Stages.AstDB
open Stages.Linked
open Stages.Tast

(** The context for statement checking. *)
type stmt_ctx

val augment_stmt: stmt_ctx -> astmt -> tstmt

val augment_decl : module_name -> module_kind -> env -> linked_definition -> typed_decl

val augment_module : env -> linked_module -> typed_module
