(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(* The targets each module interface names with pragma Targets, by the name
   of the module, as the parser read them.  A module that names none is not
   in the table, and is there for every target. *)

type targets = {
    names: string list;
    instead: string option;
  }

let table: (string, targets) Hashtbl.t = Hashtbl.create 64

let register (module_name: string) (targets: targets): unit =
  Hashtbl.replace table module_name targets

let find (module_name: string): targets option =
  Hashtbl.find_opt table module_name
