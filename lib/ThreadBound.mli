(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The types marked with [pragma Thread_Bound]: values whose C object
    must stay on the thread that made it. *)

(** [start_file ()] forgets the names a parse that did not reach the end of
    its module left pending. *)
val start_file : unit -> unit

(** [note name] keeps the type [name] of the file being parsed as marked. *)
val note : string -> unit

(** [take ()] is the names noted since the file was started, in the order
    they were written, and forgets them. *)
val take : unit -> string list

(** [register_interface m names] keeps what the interface of module [m]
    marks; a later one for the same module replaces it. *)
val register_interface : string -> string list -> unit

(** [register_body m names] keeps what the body of module [m] marks; a
    later one for the same module replaces it. *)
val register_body : string -> string list -> unit

(** [is_marked m name] is whether the interface or the body of module [m]
    marks the type [name]. *)
val is_marked : string -> string -> bool
