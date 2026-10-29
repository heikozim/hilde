(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The targets a module interface names with [pragma Targets]. *)

(** The names of the targets, out of [Util.target_names], and the module
    to take instead on a target that is not among them, if there is one. *)
type targets = {
    names: string list;
    instead: string option;
  }

(** [register name targets] keeps what the interface of module [name]
    names; a later one for the same module replaces it. *)
val register : string -> targets -> unit

(** [find name] is what the interface of module [name] names, or [None]
    when it names no targets, which means every target. *)
val find : string -> targets option
