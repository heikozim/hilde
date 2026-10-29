(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(** The reporter keeps track of the compiler's call tree, and is useful for
    debugging crashes and bugs. *)
open Identifier
open Type

(** True once --dump-calltree was given; dump and HtmlError.html_error_dump
    write nothing without it. *)
val dump_requested: bool ref

(** Render the event list into calltree.html, when dump_requested is set. *)
val dump: unit -> unit

(** Run some code inside a named frame. *)
val with_frame : string -> (unit -> 'a) -> 'a

(** The type of property labels.*)
type label = string

(** Push a string property to the current frame. *)
val ps : (label * string) -> unit

(** Push an identifier property to the current frame. *)
val pi: (label * identifier) -> unit

(** Push a qualified identifier property to the current frame. *)
val pqi: (label * qident) -> unit

(** Push a type expression property to the current frame. *)
val pt: (label * ty) -> unit
