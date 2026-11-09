(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The types marked with pragma Thread_Bound, by the name of their module.
   The parser sees the pragma at a declaration before it knows the module
   the declaration is in, so it keeps the names of one file as pending and
   hands them over when it reaches the end of the module.  The interface and
   the body of a module are kept apart: parsing one again replaces only
   what that file marked. *)

let interface_table: (string, string list) Hashtbl.t = Hashtbl.create 16

let body_table: (string, string list) Hashtbl.t = Hashtbl.create 16

let pending: string list ref = ref []

let start_file (): unit =
  pending := []

let note (type_name: string): unit =
  pending := type_name :: !pending

let take (): string list =
  let names: string list = List.rev !pending in
  pending := [];
  names

let register_interface (module_name: string) (names: string list): unit =
  if names = [] then
    Hashtbl.remove interface_table module_name
  else
    Hashtbl.replace interface_table module_name names

let register_body (module_name: string) (names: string list): unit =
  if names = [] then
    Hashtbl.remove body_table module_name
  else
    Hashtbl.replace body_table module_name names

let is_marked (module_name: string) (type_name: string): bool =
  let marked_in table =
    match Hashtbl.find_opt table module_name with
    | Some names -> List.mem type_name names
    | None -> false
  in
  marked_in interface_table || marked_in body_table
