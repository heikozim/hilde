(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
 *)

(** Desugar paths into reference transforms. *)
open Stages

val transform_expr : AstLC.aexpr -> AstDP.aexpr

val transform_stmt : AstLC.astmt -> AstDP.astmt
