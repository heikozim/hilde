(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Derived from the Austral project, https://github.com/austral/austral.
   Modifications copyright (c) 2026 Heiko Zimmermann <code@heiko-zimmermann.com>.
*)

(** Stores the compiler's version. *)

type version = int * int * int

let version: version = (1, 1, 1)

let version_string: string =
  let (mj, mi, p) = version
  and s = string_of_int in
  let (mj, mi, p) = (s mj, s mi, s p) in
  mj ^ "." ^ mi ^ "." ^ p
