(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* hilde modules and the name an unknown module was meant to be. *)
open OUnit2
open Hilde_core

let known = ["Standard.String"; "Standard.Buffer"; "Standard.StringBuilder"; "Hilde.Pervasive"]

let test_closest _ =
  assert_equal ~msg:"one letter left out" (Some "Standard.String") (Suggest.closest "Standard.Strng" known);
  assert_equal ~msg:"two letters swapped" (Some "Standard.Buffer") (Suggest.closest "Standard.Bufefr" known);
  assert_equal ~msg:"nothing near" None (Suggest.closest "Library" known);
  assert_equal ~msg:"the name itself is no suggestion" None (Suggest.closest "Standard.String" known);
  assert_equal ~msg:"a tie names nothing" None (Suggest.closest "ab" ["ac"; "ad"]);
  assert_equal ~msg:"distance" 3 (Suggest.distance "kitten" "sitting")

let write (dir: string) (name: string) (text: string): unit =
  Out_channel.with_open_bin (Filename.concat dir name) (fun oc -> output_string oc text)

let test_list ctxt =
  let dir = bracket_tmpdir ctxt in
  write dir "Alpha.hih" "module Alpha is\n    function one(): Int32;\n    type Opaque: Free;\nend module.\n";
  write dir "Alpha.hiq" "module body Alpha is\n    record Opaque: Free is\n        x: Int32;\n    end;\n    function one(): Int32 is\n        return 1;\n    end;\n    function hidden(): Int32 is\n        return 2;\n    end;\nend module body.\n";
  write dir "Beta.hiq" "module body Beta is\n    constant two: Int32 := 2;\nend module body.\n";
  write dir "Beta.test.hiq" "module body Beta.Test is\nend module body.\n";
  let listed = TestRunner.list_modules [dir] in
  assert_equal ~msg:"two modules, the test file left out" ["Alpha"; "Beta"]
    (List.map (fun (m: TestRunner.module_listing) -> m.listed_name) listed);
  match listed with
  | [alpha; beta] ->
     assert_equal ~msg:"the interface's exports, not the body's" [("function", "one"); ("type", "Opaque")] alpha.listed_exports;
     assert_bool "an interface path" (alpha.listed_interface <> None);
     assert_equal ~msg:"a body alone exports what it defines" [("constant", "two")] beta.listed_exports;
     assert_equal ~msg:"no interface" None beta.listed_interface
  | _ -> assert_failure "not two modules"

let suite =
  "Modules" >::: [
      "closest" >:: test_closest;
      "list" >:: test_list;
    ]

let _ = run_test_tt_main suite
