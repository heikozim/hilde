(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

open Identifier
open Imports
open Cst
open Stages.Ast

(* Turn an identifier into a qualified identifier, given the import map. *)
val qualify_identifier : import_map -> identifier -> qident

val qualify_typespec : import_map -> typespec -> qtypespec
