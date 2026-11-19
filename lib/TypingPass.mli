(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
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
