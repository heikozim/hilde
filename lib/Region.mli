(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
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
