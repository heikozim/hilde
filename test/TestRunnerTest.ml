(*
   Part of the Hilde project, under the Apache License v2.0 with LLVM Exceptions.
   See LICENSE file for details.

   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
*)
(* `hilde test': which functions of a test file are
   tests, and in which form.  Every case of the name rule has a neighbour on
   the other side of it, so that a rule that took every name, or none, would
   fail here; the forms are read from a compiled module, one accepted form of
   each kind and one refused form of each way a form can be wrong. *)
open OUnit2
open Hilde_core.Identifier
open Hilde_core.Error
open Hilde_core.Compiler

let test_names _ =
  List.iter
    (fun (name, want) ->
      assert_equal ~msg:name want (is_test_name (make_ident name)))
    [ ("testLength", true); ("testA", true); ("test2", true);
      ("test", false); ("testing", false); ("tests", false);
      ("test_length", false); ("lengthTest", false); ("Test", false) ]

let body (code: string list): module_source =
  BodyModuleSource { body_filename = "Example.test.hiq"; body_code = String.concat "\n" code }

let tests_of (code: string list): string =
  let source = body code in
  try
    let c = compile_multiple empty_compiler [source] in
    let (_, tests) = test_functions c source in
    String.concat " "
      (List.map
         (fun (n, form) ->
           ident_string n ^ (match form with TestPlain -> ":plain" | TestWithRoot -> ":root"))
         tests)
  with Hilde_error e ->
    let (HildeError { code; _ }) = e in
    code_string code

let test_forms _ =
  assert_equal ~msg:"both forms, in the order of the file, the helper left out"
    "testPlain:plain testRoot:root"
    (tests_of [
         "module body Example.Test is";
         "    function testPlain(): Unit is";
         "        return nil;";
         "    end;";
         "    function helper(): Nat8 is";
         "        return 1;";
         "    end;";
         "    generic [R: Region]";
         "    function testRoot(root: &![RootCapability, R]): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a parameter"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    function testTakesOne(n: Nat8): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a result"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    function testGivesOne(): Nat8 is";
         "        return 1;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"a read reference to the root capability"
    "H2046"
    (tests_of [
         "module body Example.Test is";
         "    generic [R: Region]";
         "    function testReadsRoot(root: &[RootCapability, R]): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ]);
  assert_equal ~msg:"no test at all"
    "H2047"
    (tests_of [
         "module body Example.Test is";
         "    function helper(): Unit is";
         "        return nil;";
         "    end;";
         "end module body.";
         "" ])

let suite =
  "TestRunner" >::: [
      "test names" >:: test_names;
      "test forms" >:: test_forms;
    ]

let _ = run_test_tt_main suite
