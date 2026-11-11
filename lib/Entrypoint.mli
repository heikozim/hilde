(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

(** Entrypoint logic. *)
open Env
open Identifier

(** Given the env, and the name of the entrypoint function, generate the entrypoint code. *)
val entrypoint_code : env -> qident -> string
