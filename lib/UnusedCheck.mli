(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The warning N002: a parameter or a let binding of a free type that the
    body of its function never reads; and the store of the warnings that
    hilde check gathers, N001 of NamingCheck among them. *)
open Span
open Stages.Tast

(** One finding: where it stands, the name, whether it is a parameter, the
    function it belongs to, its code (N001 or N002) and its text. *)
type finding = {
    span: span;
    name: string;
    parameter: bool;
    func: string;
    code: string;
    text: string;
  }

(** The findings of a typed module.  Linear values are left to the
    linearity check, instance methods to their type class, whose signature
    they cannot change; generated names and the files below
    bindings/generated are skipped. *)
val findings: typed_module -> finding list

(** The place of the first statement of a body that carries one: where a
    finding about a parameter stands, since a parameter has no place of its
    own in the typed tree.  None for a body without one. *)
val first_span: tstmt -> span option

(** Whether a place lies in a file below bindings/generated, or in none. *)
val generated_file: span -> bool

(** The code and the text of a finding, without its place. *)
val message: finding -> string

(** Forgets the findings recorded so far. *)
val reset: unit -> unit

(** Records findings of a module that hilde check has checked. *)
val record: finding list -> unit

(** The findings recorded since the last reset, in the order of the
    modules and of their source. *)
val recorded: unit -> finding list
