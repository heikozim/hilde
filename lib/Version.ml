(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)

(** Stores the compiler's version. *)

type version = int * int * int

let version: version = (1, 0, 0)

let version_string: string =
  let (mj, mi, p) = version
  and s = string_of_int in
  let (mj, mi, p) = (s mj, s mi, s p) in
  mj ^ "." ^ mi ^ "." ^ p
