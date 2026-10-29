(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* The HTML error report is written after the error has been printed, and
   its line cutting must not raise on a span that does not fit the line:
   that turned a parse error into a crash of the compiler. *)
open OUnit2
open Hilde_core.Span
open Hilde_core.HtmlError

let eq = assert_equal ~printer:(fun s -> s)

let span l c l' c' =
  Some (Span {
      filename = "";
      startp = Position { line = l; column = c };
      endp = Position { line = l'; column = c' };
  })

let mark before inside after =
  before ^ "<span class='error-hl'>" ^ inside ^ "<span>" ^ after

let test_inside _ =
  eq (mark "let " "t" " := ;") (line_err "let t := ;" 3 (span 3 4 3 5))

let test_other_line _ =
  eq "let t := ;" (line_err "let t := ;" 2 (span 3 4 3 5))

let test_start_beyond_the_line _ =
  eq (mark "second line" "" "") (line_err "second line" 4 (span 4 24 4 25))

let test_end_beyond_the_line _ =
  eq (mark "sec" "ond line" "") (line_err "second line" 4 (span 4 3 4 40))

let test_negative_column _ =
  eq (mark "" "se" "cond line") (line_err "second line" 4 (span 4 (-1) 4 2))

let test_end_before_start _ =
  eq (mark "second" "" " line") (line_err "second line" 4 (span 4 6 4 2))

let suite =
  "HTML error report" >::: [
      "a span inside the line" >:: test_inside;
      "a span on another line" >:: test_other_line;
      "a start beyond the line" >:: test_start_beyond_the_line;
      "an end beyond the line" >:: test_end_beyond_the_line;
      "a negative column" >:: test_negative_column;
      "an end before the start" >:: test_end_before_start
    ]

let _ = run_test_tt_main suite
