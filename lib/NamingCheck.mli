(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   Copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)

(** The warning N001: a name that breaks the case convention.  A variable, a
    parameter and a binding of a pattern are snake_case, with no capital; a
    function is camelCase, with no capital first and no underscore before a
    letter (an underscore before a digit stays, as in sha3_256).  Types,
    modules and slots are not looked at; nor are constants, which the typed
    tree gives no place to, and names the compiler made. *)
open Stages.Tast

(** The findings of a typed module, in the order of its functions. *)
val findings: typed_module -> UnusedCheck.finding list

(** Whether a name is snake_case: no capital in it. *)
val is_snake: string -> bool

(** Whether a name is a function name in camelCase: no capital first and no
    underscore before a letter. *)
val is_camel: string -> bool
