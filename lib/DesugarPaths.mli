(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
 *)

(** Desugar paths into reference transforms. *)
open Stages

val transform_expr : AstLC.aexpr -> AstDP.aexpr

val transform_stmt : AstLC.astmt -> AstDP.astmt
