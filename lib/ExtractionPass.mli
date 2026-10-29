(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open TypeSignature
open Stages.SmallCombined
open Stages.Linked
open Env
open Id

(** Go through all the types in a combined module, convert them into type
    signatures, and return those signatures as a list. *)
val extract_type_signatures : combined_module -> type_signature list

(** Extract a combined module's declarations and put them in the environment,
    and returned a linked module. *)
val extract : env -> combined_module -> file_id option -> file_id -> (env * linked_module)
