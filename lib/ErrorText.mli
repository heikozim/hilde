(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
(** This module provides a representation-independent way of writing the text in
    error messages. Rather than concatenating strings, we use a more structured
    representation, which can then be rendered to both plain text and HTML. *)
open Type

(** The contents of an error message. *)
type err_text = text_elem list

(** An individual error text element. *)
and text_elem =
  | Text of string
  (** Human-readable prose. *)
  | Code of string
  (** Hilde text, like the name of an identifier or a type. *)
  | Type of ty
  (** A Hilde type. *)
  | Break
  (** A paragraph break. *)
  | Suggest of suggestion
  (** A fix: the text that replaces the place of the error, or the place
      [at] when it is given.  [certain] says whether a tool may apply it
      without asking: true only where the replacement is the one fix. *)

and suggestion = {
    replacement: string;
    at: Span.span option;
    certain: bool;
  }

(** Render error text to plain text for disply in the terminal. *)
val error_text_to_plain : err_text -> string

val error_text_to_html  : err_text -> string

val error_text_to_json  : err_text -> Yojson.Basic.t

(** The suggestions of a text, in their order. *)
val suggestions_of : err_text -> suggestion list

(** The text without its suggestions. *)
val without_suggestions : err_text -> err_text
