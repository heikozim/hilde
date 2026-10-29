(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

open Identifier

type region
[@@deriving (eq, show, sexp)]

val region_id: region -> int

val static_region_name : identifier

val static_region : region

val fresh_region : unit -> region

(* The name a borrow statement gives a region, for messages. *)
val name_region : region -> identifier -> unit

(* The name of a region if a borrow statement gave it one, otherwise its
   number. *)
val region_label : region -> string
