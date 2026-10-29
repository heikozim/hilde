(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Identifier
open Imports
open Cst
open Stages.Ast

(* Turn an identifier into a qualified identifier, given the import map. *)
val qualify_identifier : import_map -> identifier -> qident

val qualify_typespec : import_map -> typespec -> qtypespec
