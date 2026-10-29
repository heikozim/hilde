(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open Env
open Stages.Tast

(** Given a typed module, extract the function and instance method bodies and
    store them in the environment. *)
val extract_bodies : env -> typed_module -> env
