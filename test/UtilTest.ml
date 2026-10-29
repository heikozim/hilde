(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

   Hilde is derived from the Austral project and extends it substantially.
   Modified by Heiko Zimmermann, 2026.
*)
open OUnit2
open Hilde_core.Util
open TestUtil

let test_run_command _ =
  let (CommandOutput { command; code; stdout; stderr }) = run_command [|"echo"; "derp"|] in
  eq "'echo' 'derp'" command;
  eq 0 code;
  eq "derp" stdout;
  eq "" stderr

(* The compiler runs `cc` with paths its caller controls, so an argument a
   shell would split or act on has to arrive whole. The input carries the
   case on purpose: a semicolon and a space. Against the previous version,
   which passed a string to a shell, stdout would read "a b" and the file
   below would exist. *)
let test_run_command_passes_arguments_whole _ =
  let marker = "hilde-shell-marker.txt" in
  if Sys.file_exists marker then Sys.remove marker;
  let (CommandOutput { code; stdout; _ }) = run_command [|"echo"; "a b; touch " ^ marker|] in
  eq 0 code;
  eq ("a b; touch " ^ marker) stdout;
  assert_bool "a shell ran: the marker file was created" (not (Sys.file_exists marker))

let test_search_replace _ =
  let out = search_replace {
                text = "The quick brown fox.";
                search = "quick";
                replacement = "slow"
              }
  in
  assert_equal out "The slow brown fox."

let test_map_with_context _ =
  let lst = ["a"; "b"; "c"; "d"]
  and ctx = 0
  and f ((c, a): (int * string)): (int * string) =
    (c + 1, String.uppercase_ascii a)
  in
  let (ctx', results) = map_with_context f ctx lst in
  assert_equal ctx' 4;
  assert_equal results ["A"; "B"; "C"; "D"]

let suite =
  "Utilities" >::: [
      "run_command" >:: test_run_command;
      "run_command passes arguments whole" >:: test_run_command_passes_arguments_whole;
      "search_replace" >:: test_search_replace;
      "map_with_context" >:: test_map_with_context
    ]

let _ = run_test_tt_main suite
