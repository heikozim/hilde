(*
   Part of Hilde, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-FileCopyrightText: 2026 Heiko Zimmermann
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(** Where a declaration was written. *)
open Id
open Span

(** Remember where a declaration was written.  Called from the extraction
    pass, which is the one place a span and a declaration id are both in
    hand. *)
val record_decl : decl_id -> span -> unit

(** Where a declaration was written, if it is known.  [None] for a
    declaration the extraction pass did not record -- a built-in module, for
    one -- and a caller has to be able to emit nothing in that case. *)
val find_decl : decl_id -> span option

(** Forget everything.  For a caller that compiles more than once in one
    process. *)
val reset : unit -> unit

(** How many declarations are known.  For a measurement, not for a decision. *)
val count : unit -> int
