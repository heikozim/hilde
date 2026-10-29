(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Span

let eq = assert_equal
let i = make_ident

let span l c l' c' =
  Span {
      filename = "";
      startp = Position {
                   line = l;
                   column = c;
                 };
      endp = Position {
                 line = l';
                 column = c';
               };
  }

let simplespan s =
  span 1 0 1 (String.length s)
