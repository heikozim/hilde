(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(** Tools for excerpting pieces of code. *)
open Span

(** A source context is a list of (line number, line text) pairs. *)
type source_ctx = SourceContext of (int * string) list

(** Given a source file and a span, return the source context. *)
val get_source_ctx : string -> span -> source_ctx

(** Render a source context to plain text. *)
val source_ctx_to_plain_text : source_ctx -> string
