(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open OUnit2
open Hilde_core.Cst
open Hilde_core.ParserInterface
open TestUtil

let p = parse_stmt

let peq (s: string) (v: 'a) =
  eq v (p s)

let test_if _ =
  (* Discarding block *)
  let db e = CBlock [CDiscarding e]
  in
  peq "if true then nil; end if;" (CIf (CBoolConstant true, db CNilConstant, CSkip));
  peq "if true then nil; else nil; end if;" (CIf (CBoolConstant true, db CNilConstant, db CNilConstant));
  peq "if true then nil; else if false then nil; end if;" (CIf (CBoolConstant true, db CNilConstant, CIf (CBoolConstant false, db CNilConstant, CSkip)));
  peq "if true then nil; else if false then nil; else nil; end if;" (CIf (CBoolConstant true, db CNilConstant, CIf (CBoolConstant false, db CNilConstant, db CNilConstant)))

let test_return _ =
  peq "return 123;" (CReturn (CIntConstant "123"))


let test_skip _ =
  peq "skip;" CSkip

let suite =
  "Statement parser" >::: [
      "If statement" >:: test_if;
      "Return statement" >:: test_return;
      "Skip statement" >:: test_skip
    ]

let _ = run_test_tt_main suite
