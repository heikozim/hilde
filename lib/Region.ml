(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

open Identifier
open Sexplib
open Std

type region = Region of int
[@@deriving (eq, show, sexp)]

let region_id (Region i) = i

let static_region_name = make_ident "Static"

let static_region = Region (0)

let region_counter: int ref = ref 1

let fresh_region _ =
  let i = !region_counter in
  region_counter := i + 1;
  Region i

(* The name a borrow statement gives its region, for messages.  A region is
   a number, and the number counts every region created before it in the
   whole compilation, so a message that printed it changed with any module
   compiled earlier. *)
let region_names: (int, string) Hashtbl.t = Hashtbl.create 64

let name_region (r: region) (name: identifier): unit =
  let s = ident_string name in
  (* The regions of anonymous borrows are named by the compiler
     (`_tmp_region_N'); those keep their number. *)
  if String.length s > 0 && s.[0] <> '_' then
    Hashtbl.replace region_names (region_id r) s

let region_label (r: region): string =
  match Hashtbl.find_opt region_names (region_id r) with
  | Some name -> name
  | None -> string_of_int (region_id r)
