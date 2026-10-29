(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** This module creates wrappers around exported functions, and the
    header of a library. *)
open Env

(** The C of the wrappers of every exported function: the handles, a
    prototype of each with default visibility, and the definitions. *)
val wrappers_code : env -> string

(** [library_header env file_name libraries] is the text of the header
    [file_name] of a library that needs [libraries] when it is linked as a
    static archive. *)
val library_header : env -> string -> string list -> string

(** The C names of the exported functions, in the order of the header. *)
val export_names : env -> string list
